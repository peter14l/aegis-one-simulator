use notify::{Watcher, RecursiveMode, Config, EventKind};
use std::path::PathBuf;
use std::time::Duration;
use std::sync::Arc;
use std::sync::atomic::{AtomicBool, Ordering};
use interprocess::local_socket::tokio::LocalSocketStream;
use futures_util::io::{AsyncBufReadExt, AsyncWriteExt, BufReader};
use futures_util::{StreamExt, SinkExt};
use tokio::sync::Mutex;
use serde::{Serialize, Deserialize};
use tokio_tungstenite::tungstenite::protocol::Message;

const IPC_SOCKET: &str = "infinity_cache.sock";
const WS_PORT: &str = "127.0.0.1:3030";

#[derive(Serialize, Deserialize, Debug, Clone)]
pub enum Command {
    WriteLba(u32),
    WriteLbaBatch { start: u32, count: u32 },
    GetTelemetry,
    SetVoltage(f64),
}

#[derive(Serialize, Deserialize, Debug, Clone)]
pub struct Telemetry {
    pub active_pages: usize,
    pub max_pages: usize,
    pub total_ios: u64,
    pub voltage: f64,
    pub emmc_wear_percentage: f64,
    pub supercap_charge: f64,
    pub status: String,
    pub version: String,
}

#[tokio::main]
async fn main() -> std::io::Result<()> {
    let scratch_path = std::path::Path::new("scratch_disk");
    if !scratch_path.exists() {
        let _ = std::fs::create_dir_all(scratch_path);
    }

    let absolute_path = std::fs::canonicalize(scratch_path).unwrap_or_else(|_| PathBuf::from("scratch_disk"));
    let stress_test_active = Arc::new(AtomicBool::new(false));

    println!("[DAEMON] Connecting to Hardware Core...");
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
            print!("[DAEMON->CORE] {}", payload.trim());
            let _ = writer.write_all(payload.as_bytes()).await;
            while let Ok(more) = core_rx.try_recv() {
                print!("[DAEMON->CORE] {}", more.trim());
                let _ = writer.write_all(more.as_bytes()).await;
            }
            let _ = writer.flush().await;
        }
    });

    let mut core_reader_lines = BufReader::new(reader).lines();
    let clients: Arc<Mutex<Vec<tokio::sync::mpsc::UnboundedSender<String>>>> = Arc::new(Mutex::new(Vec::new()));
    
    // 1. File Monitoring Task
    let (tx, mut rx) = tokio::sync::mpsc::unbounded_channel();
    let mut watcher = notify::RecommendedWatcher::new(
        move |res: Result<notify::Event, notify::Error>| {
            if let Ok(event) = res { let _ = tx.send(event); }
        }, 
        Config::default()
    ).unwrap();
    let _ = watcher.watch(&absolute_path, RecursiveMode::Recursive);

    let writer_lba = core_tx.clone();
    tokio::spawn(async move {
        let mut simulated_lba: u32 = 0x10000000;
        while let Some(event) = rx.recv().await {
            if let EventKind::Modify(_) = event.kind {
                simulated_lba = simulated_lba.wrapping_add(1);
                let cmd = Command::WriteLba(simulated_lba);
                let mut payload = serde_json::to_string(&cmd).unwrap();
                payload.push('\n');
                let _ = writer_lba.send(payload);
            }
        }
    });

    // 2. Stress Test Task
    let stress_active_clone = stress_test_active.clone();
    let writer_stress = core_tx.clone();
    tokio::spawn(async move {
        let mut lba: u32 = 0x50000000;
        loop {
            if stress_active_clone.load(Ordering::SeqCst) {
                let cmd = Command::WriteLbaBatch { start: lba, count: 30 };
                let mut payload = serde_json::to_string(&cmd).unwrap();
                payload.push('\n');
                let _ = writer_stress.send(payload);
                lba = lba.wrapping_add(30);
                print!("[STRESS] {}", lba);
            }
            tokio::time::sleep(Duration::from_millis(500)).await;
        }
    });

    // 3. WebSocket Listener
    let clients_inner = clients.clone();
    let writer_ws = core_tx.clone();
    let stress_inner = stress_test_active.clone();
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

            tokio::spawn(async move {
                while let Some(msg) = rx_client.recv().await {
                    println!("[DAEMON->WS] {}", msg);
                    if ws_sender.send(Message::Text(msg)).await.is_err() { break; }
                }
            });

            tokio::spawn(async move {
                while let Some(Ok(Message::Text(text))) = ws_receiver.next().await {
                    println!("[DAEMON] WS Command received: {}", text);
                    match text.as_str() {
                        "START_STRESS_TEST" => {
                            println!("[DAEMON] Starting stress test...");
                            stress_cmd.store(true, Ordering::SeqCst);
                        },
                        "STOP_STRESS_TEST" => {
                            println!("[DAEMON] Stopping stress test...");
                            stress_cmd.store(false, Ordering::SeqCst);
                        },
                        "SIMULATE_POWER_LOSS" => {
                            println!("[DAEMON] Simulating power loss...");
                            let mut p = serde_json::to_string(&Command::SetVoltage(2.5)).unwrap();
                            p.push('\n'); let _ = writer_cmd.send(p);
                        },
                        "RESET_POWER" => {
                            println!("[DAEMON] Resetting power...");
                            let mut p = serde_json::to_string(&Command::SetVoltage(3.3)).unwrap();
                            p.push('\n'); let _ = writer_cmd.send(p);
                        },
                        _ => println!("[DAEMON] Unknown command: {}", text)
                    }
                }
            });
        }
    });

    // 4. Telemetry Loop
    let writer_tel = core_tx.clone();
    tokio::spawn(async move {
        loop {
            let mut p = serde_json::to_string(&Command::GetTelemetry).unwrap();
            p.push('\n'); let _ = writer_tel.send(p);
            tokio::time::sleep(Duration::from_millis(100)).await;
        }
    });

// 5. Broadcaster
    loop {
        if let Some(Ok(line)) = core_reader_lines.next().await {
            let line = line.trim();
            println!("[DAEMON READ] '{}'", line);
            if line.is_empty() { continue; }
            
            // Handle potentially interleaved or malformed lines
            let json_start = line.find('{');
            if let Some(start_idx) = json_start {
                let potential_json = &line[start_idx..];
                match serde_json::from_str::<Telemetry>(potential_json) {
                    Ok(tel) => {
                        println!("[DAEMON] Broadcasting: total_ios={}", tel.total_ios);
                        if let Ok(msg) = serde_json::to_string(&tel) {
                            let mut list = clients.lock().await;
                            list.retain(|c| c.send(msg.clone()).is_ok());
                        }
                    }
                    Err(e) => {
                        eprintln!("[DAEMON] Error parsing potential JSON: '{}' - Error: {}", potential_json, e);
                    }
                }
            } else {
                eprintln!("[DAEMON] Received non-JSON line from core: '{}'", line);
            }
        }
    }
}
