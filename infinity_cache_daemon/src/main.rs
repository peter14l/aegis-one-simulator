use notify::{Watcher, RecursiveMode, Config, EventKind};
use std::path::PathBuf;
use std::time::Duration;
use std::sync::Arc;
use std::sync::atomic::{AtomicBool, AtomicU64, Ordering};
use interprocess::local_socket::tokio::LocalSocketStream;
use futures_util::io::{AsyncBufReadExt, AsyncWriteExt, BufReader};
use futures_util::{StreamExt, SinkExt};
use tokio::sync::Mutex;
use serde::{Serialize, Deserialize};
use tokio_tungstenite::tungstenite::protocol::Message;

const IPC_SOCKET: &str = if cfg!(windows) { r"\\.\pipe\infinity_cache.sock" } else { "infinity_cache.sock" };
const WS_PORT: &str = "127.0.0.1:3030";

#[derive(Serialize, Deserialize, Debug, Clone)]
pub enum Command {
    WriteLba(u32),
    WriteLbaBatch { start: u32, count: u32 },
    GetTelemetry,
    SetHmbCapacity(u64),
    SuddenPowerLoss,
    ToggleHostPlp,
}

#[derive(Serialize, Deserialize, Debug, Clone)]
pub struct Telemetry {
    pub total_ios: u64,
    pub hmb_active_pages: u64,
    pub hmb_max_pages: u64,
    pub hmb_pressure_percentage: f64,
    pub ufs_wear_percentage: f64,
    pub chip_wear_array: Vec<f64>,
    pub status: String,
    pub version: String,
    pub temperature: f64,
    pub performance_multiplier: f64,
    pub pseudo_slc_active: bool,
    pub lost_dirty_pages_count: u64,
    pub host_plp_enabled: bool,
}

#[tokio::main]
async fn main() -> std::io::Result<()> {
    let scratch_path = std::path::Path::new("scratch_disk");
    if !scratch_path.exists() {
        let _ = std::fs::create_dir_all(scratch_path);
    }

    let stress_test_active = Arc::new(AtomicBool::new(false));
    let thermal_stress_active = Arc::new(AtomicBool::new(false));
    let demo_writes_remaining = Arc::new(AtomicU64::new(0));

    println!("[DAEMON] Connecting to Aegis-One Phase 3 Core...");
    let core_stream = loop {
        match LocalSocketStream::connect(IPC_SOCKET).await {
            Ok(s) => break s,
            Err(_) => {
                tokio::time::sleep(Duration::from_secs(1)).await;
            }
        }
    };

    let (reader, mut writer) = core_stream.into_split();
    
    // Core Writer Task
    let (core_tx, mut core_rx) = tokio::sync::mpsc::unbounded_channel::<String>();
    tokio::spawn(async move {
        while let Some(payload) = core_rx.recv().await {
            let _ = writer.write_all(payload.as_bytes()).await;
            while let Ok(more) = core_rx.try_recv() {
                let _ = writer.write_all(more.as_bytes()).await;
            }
            let _ = writer.flush().await;
        }
    });

    let mut core_reader_lines = BufReader::new(reader).lines();
    let clients: Arc<Mutex<Vec<tokio::sync::mpsc::UnboundedSender<String>>>> = Arc::new(Mutex::new(Vec::new()));
    
    // Stress Test Task
    let stress_active_clone = stress_test_active.clone();
    let writer_stress = core_tx.clone();
    tokio::spawn(async move {
        let mut lba: u32 = 0x50000000;
        loop {
            if stress_active_clone.load(Ordering::SeqCst) {
                let cmd = Command::WriteLbaBatch { start: lba, count: 2000 };
                let mut payload = serde_json::to_string(&cmd).unwrap();
                payload.push('\n');
                let _ = writer_stress.send(payload);
                lba = lba.wrapping_add(2000);
            }
            tokio::time::sleep(Duration::from_millis(100)).await;
        }
    });

    // Thermal Stress Task
    let thermal_active_clone = thermal_stress_active.clone();
    let writer_thermal = core_tx.clone();
    tokio::spawn(async move {
        let mut lba: u32 = 0x70000000;
        loop {
            if thermal_active_clone.load(Ordering::SeqCst) {
                let cmd = Command::WriteLbaBatch { start: lba, count: 5000 };
                let mut payload = serde_json::to_string(&cmd).unwrap();
                payload.push('\n');
                let _ = writer_thermal.send(payload);
                lba = lba.wrapping_add(5000);
            }
            tokio::time::sleep(Duration::from_millis(50)).await;
        }
    });

    // 1M Write Absorption Demo Task
    let demo_remaining_clone = demo_writes_remaining.clone();
    let writer_demo = core_tx.clone();
    tokio::spawn(async move {
        loop {
            let remaining = demo_remaining_clone.load(Ordering::SeqCst);
            if remaining > 0 {
                let batch = remaining.min(8000) as u32;
                let lba = (1_000_000u32).wrapping_sub(remaining as u32);
                let cmd = Command::WriteLbaBatch { start: lba % 4096, count: batch };
                let mut payload = serde_json::to_string(&cmd).unwrap();
                payload.push('\n');
                let _ = writer_demo.send(payload);
                demo_remaining_clone.fetch_sub(batch as u64, Ordering::SeqCst);
            }
            tokio::time::sleep(Duration::from_millis(50)).await;
        }
    });

    // WebSocket Listener
    let clients_inner = clients.clone();
    let writer_ws = core_tx.clone();
    let stress_inner = stress_test_active.clone();
    let thermal_inner = thermal_stress_active.clone();
    let demo_inner = demo_writes_remaining.clone();
    let listener = tokio::net::TcpListener::bind(WS_PORT).await.expect("Bind Fail");
    println!("[DAEMON] WebSocket Server listening at ws://{}", WS_PORT);

    tokio::spawn(async move {
        while let Ok((stream, _)) = listener.accept().await {
            let ws_stream = match tokio_tungstenite::accept_async(stream).await {
                Ok(ws) => ws,
                Err(e) => {
                    println!("[DAEMON] WebSocket handshake failed: {}", e);
                    continue;
                }
            };
            let (mut ws_sender, mut ws_receiver) = ws_stream.split();
            let (tx_client, mut rx_client) = tokio::sync::mpsc::unbounded_channel::<String>();
            
            let clients_list = clients_inner.clone();
            {
                let mut c = clients_list.lock().await;
                c.push(tx_client);
            }

            let writer_cmd = writer_ws.clone();
            let stress_cmd = stress_inner.clone();
            let thermal_cmd = thermal_inner.clone();
            let demo_cmd = demo_inner.clone();

            tokio::spawn(async move {
                while let Some(msg) = rx_client.recv().await {
                    if ws_sender.send(Message::Text(msg)).await.is_err() { break; }
                }
            });

            tokio::spawn(async move {
                while let Some(Ok(Message::Text(text))) = ws_receiver.next().await {
                    println!("[DAEMON] WS Command received: {}", text);
                    match text.as_str() {
                        "START_STRESS_TEST" => stress_cmd.store(true, Ordering::SeqCst),
                        "STOP_STRESS_TEST" => stress_cmd.store(false, Ordering::SeqCst),
                        "START_THERMAL_STRESS" => thermal_cmd.store(true, Ordering::SeqCst),
                        "STOP_THERMAL_STRESS" => thermal_cmd.store(false, Ordering::SeqCst),
                        "START_1M_DEMO" => demo_cmd.store(1_000_000, Ordering::SeqCst),
                        "SIMULATE_HMB_PRESSURE" => {
                            // Shrink HMB to simulate OS memory pressure
                            let mut p = serde_json::to_string(&Command::SetHmbCapacity(512)).unwrap();
                            p.push('\n'); let _ = writer_cmd.send(p);
                        },
                        "RESET_HMB" => {
                            let mut p = serde_json::to_string(&Command::SetHmbCapacity(4096)).unwrap();
                            p.push('\n'); let _ = writer_cmd.send(p);
                        },
                        "TRIGGER_SUDDEN_POWER_LOSS" => {
                            let mut p = serde_json::to_string(&Command::SuddenPowerLoss).unwrap();
                            p.push('\n'); let _ = writer_cmd.send(p);
                        },
                        "TOGGLE_HOST_PLP" => {
                            let mut p = serde_json::to_string(&Command::ToggleHostPlp).unwrap();
                            p.push('\n'); let _ = writer_cmd.send(p);
                        },
                        _ => println!("[DAEMON] Unknown command: {}", text)
                    }
                }
            });
        }
    });

    // Telemetry Loop
    let writer_tel = core_tx.clone();
    tokio::spawn(async move {
        loop {
            let mut p = serde_json::to_string(&Command::GetTelemetry).unwrap();
            p.push('\n'); let _ = writer_tel.send(p);
            tokio::time::sleep(Duration::from_millis(300)).await;
        }
    });

    // Broadcaster
    while let Some(line_res) = core_reader_lines.next().await {
        match line_res {
            Ok(line) => {
                let line = line.trim();
                if line.is_empty() { continue; }
                
                let json_start = line.find('{');
                if let Some(start_idx) = json_start {
                    let potential_json = &line[start_idx..];
                    match serde_json::from_str::<Telemetry>(potential_json) {
                        Ok(tel) => {
                            if let Ok(msg) = serde_json::to_string(&tel) {
                                let mut list = clients.lock().await;
                                list.retain(|c| c.send(msg.clone()).is_ok());
                            }
                        }
                        Err(e) => {
                            eprintln!("[DAEMON] JSON Parse Error: {} in line: {}", e, potential_json);
                        }
                    }
                }
            }
            Err(e) => {
                eprintln!("[DAEMON] Error reading from core IPC: {}", e);
                break;
            }
        }
    }
    println!("[DAEMON] Core reader connection lost, shutting down.");
    Ok(())
}
