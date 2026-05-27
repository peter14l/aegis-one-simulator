use infinity_cache_core::{AegisEngine, Command};
use std::sync::Arc;
use core::sync::atomic;

#[tokio::main]
async fn main() -> Result<(), std::boxed::Box<dyn std::error::Error>> {
    use interprocess::local_socket::tokio::LocalSocketListener;
    use futures::{AsyncWriteExt, StreamExt};
    use futures::io::{AsyncBufReadExt, BufReader};
    use std::time::Duration;

    let engine = Arc::new(AegisEngine::new());
    let name = if cfg!(windows) { r"\\.\pipe\infinity_cache.sock" } else { "/tmp/infinity_cache.sock" };
    
    let _ = std::fs::remove_file(name);
    let listener = LocalSocketListener::bind(name)?;
    
    std::println!("--- Aegis-One Silicon Simulation Server Started ---");
    std::println!("Listening on: {}", name);

    // Background write loop disabled for cleaner demo startup
    /*
    let engine_clone = engine.clone();
    tokio::spawn(async move {
        let mut lba = 0;
        loop {
            engine_clone.handle_write(lba).await;
            lba = (lba + 1) % 10000;
            tokio::time::sleep(Duration::from_millis(10)).await;
        }
    });
    */

    let writeback_engine = engine.clone();
    tokio::spawn(async move {
        loop {
            tokio::time::sleep(Duration::from_millis(500)).await;
            writeback_engine.flush_dirty_pages_batch(200).await;
        }
    });

    loop {
        let stream = listener.accept().await?;
        let (reader, mut writer) = stream.into_split();
        let engine_conn = engine.clone();

        // Response Channel to prevent backpressure blocking the command loop
        let (tx_resp, mut rx_resp) = tokio::sync::mpsc::channel::<String>(100);

        // Socket Writer Task
        tokio::spawn(async move {
            while let Some(msg) = rx_resp.recv().await {
                if writer.write_all(msg.as_bytes()).await.is_err() { break; }
                let _ = writer.flush().await;
            }
        });

        tokio::spawn(async move {
            let mut reader_lines = BufReader::new(reader).lines();
            while let Some(line_res) = reader_lines.next().await {
                match line_res {
                    Ok(line) => {
                        let line = line.trim();
                        if line.is_empty() { continue; }

                        if let Ok(cmd) = serde_json::from_str::<Command>(line) {
                            match cmd {
                                Command::WriteLba(lba) => {
                                    engine_conn.handle_write(lba).await;
                                }
                                Command::WriteLbaBatch { start, count } => {
                                    let engine_clone = engine_conn.clone();
                                    tokio::spawn(async move {
                                        let mut i = 0;
                                        while i < count {
                                            let chunk_size = std::cmp::min(1000, count - i);
                                            let mut batch = std::vec::Vec::with_capacity(chunk_size as usize);
                                            for _ in 0..chunk_size {
                                                batch.push(start.wrapping_add(i));
                                                i += 1;
                                            }
                                            engine_clone.handle_write_batch(&batch).await;
                                            tokio::task::yield_now().await;
                                        }
                                    });
                                }
                                Command::SetHmbCapacity(pages) => {
                                    engine_conn.set_hmb_capacity(pages);
                                }
                                Command::SuddenPowerLoss => {
                                    engine_conn.trigger_sudden_power_loss().await;
                                }
                                Command::ToggleHostPlp => {
                                    engine_conn.toggle_host_plp();
                                }
                                Command::GetTelemetry => {
                                    let tel = engine_conn.get_telemetry().await;
                                    if let Ok(mut json) = serde_json::to_string(&tel) {
                                        json.push('\n');
                                        let _ = tx_resp.send(json).await;
                                    }
                                }
                            }
                        }
                    }
                    Err(_) => break,
                }
            }
        });
    }
    }