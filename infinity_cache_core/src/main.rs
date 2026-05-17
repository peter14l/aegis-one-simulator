#![cfg_attr(not(feature = "std"), no_std)]
#![cfg_attr(not(feature = "std"), no_main)]

#[cfg(feature = "std")]
use std::collections::HashMap;
#[cfg(feature = "std")]
use std::sync::atomic::{AtomicU64, AtomicUsize, Ordering};
#[cfg(feature = "std")]
use std::sync::Arc;
#[cfg(feature = "std")]
use std::time::Duration;
#[cfg(feature = "std")]
use tokio::sync::Mutex;
use serde::{Serialize, Deserialize};

// Constants
const CACHE_PAGES: usize = 4096; 
const CRITICAL_VOLTAGE: f64 = 2.9;

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

// --- Embedded Panic Handler ---
#[cfg(all(not(feature = "std"), not(test), target_os = "none"))]
#[panic_handler]
fn panic(_info: &core::panic::PanicInfo) -> ! {
    loop {
        core::hint::spin_loop();
    }
}

#[cfg(feature = "std")]
mod std_impl {
    use super::*;
    use futures::io::{AsyncBufReadExt, AsyncWriteExt, BufReader};
    use futures::StreamExt;
    use interprocess::local_socket::tokio::LocalSocketListener;

    pub const IPC_SOCKET: &str = "infinity_cache.sock";

    pub struct CacheManager {
        pub storage: HashMap<u32, ()>,
        pub total_ios: u64,
        pub emmc_wear: f64,
    }

    impl CacheManager {
        pub fn new() -> Self {
            Self {
                storage: HashMap::with_capacity(CACHE_PAGES),
                total_ios: 0,
                emmc_wear: 0.001,
            }
        }

        pub fn access(&mut self, lba: u32) {
            self.total_ios += 1;
            if self.storage.len() >= CACHE_PAGES && !self.storage.contains_key(&lba) {
                if let Some(&key) = self.storage.keys().next() {
                    self.storage.remove(&key);
                    self.emmc_wear += 0.00000001; 
                }
            }
            self.storage.insert(lba, ());
        }
    }

    pub struct CoreEngine {
        pub cache: Arc<Mutex<CacheManager>>,
        pub voltage: Arc<AtomicU64>,
        pub pending_writes: Arc<AtomicUsize>,  // Track in-progress batch writes
    }

    impl CoreEngine {
        pub fn new() -> Self {
            Self {
                cache: Arc::new(Mutex::new(CacheManager::new())),
                voltage: Arc::new(AtomicU64::new(3.3f64.to_bits())),
                pending_writes: Arc::new(AtomicUsize::new(0)),
            }
        }
    }

    pub async fn start_ipc_server(engine: Arc<CoreEngine>) -> std::io::Result<()> {
        if cfg!(unix) {
            let _ = std::fs::remove_file(IPC_SOCKET);
        }
        let listener = LocalSocketListener::bind(IPC_SOCKET)?;
        println!("[CORE] V2.3-ULTRA Server Listening...");

        loop {
            match listener.accept().await {
                Ok(stream) => {
                    println!("[CORE] Accepted Connection.");
                    let engine = engine.clone();
                    tokio::spawn(async move {
                        let (reader, mut writer) = stream.into_split();
                        let mut lines = BufReader::new(reader).lines();
                        
                        // Use a channel for thread-safe writing to the socket
                        let (tx, mut rx) = tokio::sync::mpsc::unbounded_channel::<String>();
                        
                        tokio::spawn(async move {
                            while let Some(msg) = rx.recv().await {
                                if writer.write_all(msg.as_bytes()).await.is_err() { break; }
                                if writer.flush().await.is_err() { break; }
                            }
                        });

                        while let Some(Ok(line)) = lines.next().await {
                            if let Ok(cmd) = serde_json::from_str::<Command>(&line) {
                                match cmd {
                                    Command::WriteLba(lba) => {
                                        let mut cache = engine.cache.lock().await;
                                        cache.access(lba);
                                    }
                                    Command::WriteLbaBatch { start, count } => {
                                        engine.pending_writes.fetch_add(count as usize, Ordering::SeqCst);
                                        let engine_clone = engine.clone();
                                        tokio::spawn(async move {
                                            let mut i = 0;
                                            while i < count {
                                                let chunk_size = std::cmp::min(250, count - i);
                                                {
                                                    let mut cache = engine_clone.cache.lock().await;
                                                    for _ in 0..chunk_size {
                                                        cache.access(start.wrapping_add(i));
                                                        i += 1;
                                                    }
                                                }
                                                tokio::task::yield_now().await;
                                            }
                                            engine_clone.pending_writes.fetch_sub(count as usize, Ordering::SeqCst);
                                        });
                                    }
                                    Command::GetTelemetry => {
                                        let v = f64::from_bits(engine.voltage.load(Ordering::SeqCst));
                                        let (active, total, wear) = {
                                            let cache = engine.cache.lock().await;
                                            (cache.storage.len(), cache.total_ios, cache.emmc_wear)
                                        };

                                        let tel = Telemetry {
                                            active_pages: active,
                                            max_pages: CACHE_PAGES,
                                            total_ios: total,
                                            voltage: v,
                                            emmc_wear_percentage: wear,
                                            supercap_charge: if v > 3.0 { 100.0 } else { (v / 3.3) * 100.0 },
                                            status: if v < CRITICAL_VOLTAGE { "PANIC_FLUSH".to_string() } else { "NORMAL_OPERATION".to_string() },
                                            version: "V2.3-ULTRA".to_string(),
                                        };

                                        if let Ok(mut resp) = serde_json::to_string(&tel) {
                                            resp.push('\n');
                                            let _ = tx.send(resp);
                                        }
                                    }
                                    Command::SetVoltage(v) => {
                                        engine.voltage.store(v.to_bits(), Ordering::SeqCst);
                                    }
                                }
                            }
                        }
                    });
                }
                Err(e) => eprintln!("IPC Accept error: {}", e),
            }
        }
    }
}

#[cfg(feature = "std")]
#[tokio::main]
async fn main() -> std::io::Result<()> {
    use std_impl::*;

    let engine = Arc::new(CoreEngine::new());
    
    let v_jitter = engine.voltage.clone();
    tokio::spawn(async move {
        loop {
            tokio::time::sleep(Duration::from_millis(500)).await;
            let current_v = f64::from_bits(v_jitter.load(Ordering::SeqCst));
            if current_v > 3.0 {
                let jitter = (rand::random::<f64>() - 0.5) * 0.04;
                v_jitter.store((3.3 + jitter).to_bits(), Ordering::SeqCst);
            }
        }
    });

    start_ipc_server(engine).await
}

#[cfg(not(feature = "std"))]
#[no_mangle]
pub extern "C" fn main() -> ! {
    loop {
        core::hint::spin_loop();
    }
}
