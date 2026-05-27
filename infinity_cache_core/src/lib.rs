#![no_std]

#[cfg(feature = "std")]
extern crate std;

#[cfg(feature = "std")]
use std::collections::{HashMap, HashSet, VecDeque};
#[cfg(feature = "std")]
use std::sync::{Arc, Mutex as SyncMutex};

#[cfg(not(feature = "std"))]
use spin::Mutex as SyncMutex;

use core::sync::atomic::{AtomicU64, AtomicBool, Ordering};
use serde::{Serialize, Deserialize};
use heapless::{Vec as FixedVec, String as FixedString};

#[cfg(not(feature = "std"))]
#[panic_handler]
fn panic(_info: &core::panic::PanicInfo) -> ! {
    loop {}
}

// --- Aegis-One Phase 3 Architecture Constants ---
const NUM_UFS_CHANNELS: usize = 4;
const UFS_MAX_WEAR_CYCLES: u64 = 5_000_000; // Increased for high-endurance UFS 4.0
const LBA_BLOCK_SIZE: u32 = 4096;
const INITIAL_HMB_PAGES: u64 = 4096;         // 16GB default HMB in simulation blocks
const PSEUDO_SLC_THRESHOLD: f64 = 0.85;      // Trigger Pseudo-SLC fallback at 85% HMB pressure

#[derive(Serialize, Deserialize, Debug, Clone)]
pub struct Telemetry {
    pub total_ios: u64,
    pub hmb_active_pages: u64,
    pub hmb_max_pages: u64,
    pub hmb_pressure_percentage: f64,
    pub ufs_wear_percentage: f64,
    pub chip_wear_array: FixedVec<f64, 4>,
    pub status: FixedString<32>,
    pub version: FixedString<32>,
    pub temperature: f64,
    pub performance_multiplier: f64,
    pub pseudo_slc_active: bool,
    pub lost_dirty_pages_count: u64,
    pub host_plp_enabled: bool,
}

#[derive(Serialize, Deserialize, Debug, Clone)]
pub enum Command {
    WriteLba(u32),
    WriteLbaBatch { start: u32, count: u32 },
    GetTelemetry,
    SetHmbCapacity(u64), // Dynamically resize HMB
    SuddenPowerLoss,     // Simulate sudden power loss
    ToggleHostPlp,       // Toggle host power loss protection
}

pub struct UfsChannel {
    pub id: usize,
    pub wear_cycles: u64,
}

impl UfsChannel {
    pub fn new(id: usize) -> Self {
        Self { id, wear_cycles: 0 }
    }

    pub fn write(&mut self) {
        if self.wear_cycles < UFS_MAX_WEAR_CYCLES {
            self.wear_cycles += 1;
        }
    }

    pub fn get_wear_fraction(&self) -> f64 {
        (self.wear_cycles as f64 / UFS_MAX_WEAR_CYCLES as f64).min(1.0)
    }
}

/// Aegis-One Phase 3 Elastic HMB Storage Engine
pub struct AegisEngine {
    #[cfg(feature = "std")]
    hmb_cache: SyncMutex<HashMap<u32, std::vec::Vec<u8>>>,
    #[cfg(not(feature = "std"))]
    hmb_cache: SyncMutex<heapless::LinearMap<u32, [u8; 64], 8192>>,
    
    #[cfg(feature = "std")]
    hmb_fifo: SyncMutex<VecDeque<u32>>,
    #[cfg(not(feature = "std"))]
    hmb_fifo: SyncMutex<FixedVec<u32, 8192>>,

    #[cfg(feature = "std")]
    ufs_array: std::vec::Vec<Arc<SyncMutex<UfsChannel>>>,
    #[cfg(not(feature = "std"))]
    ufs_array: [SyncMutex<UfsChannel>; 4],

    total_ios: AtomicU64,
    hmb_max_pages: AtomicU64,
    active_pages: AtomicU64,
    pub is_panic: AtomicBool,
    pub pseudo_slc_active: AtomicBool,
    pub lost_dirty_pages_count: AtomicU64,
    pub host_plp_enabled: AtomicBool,

    #[cfg(feature = "std")]
    ftl_map: SyncMutex<HashMap<u32, u32>>,
    #[cfg(feature = "std")]
    dirty_pages: SyncMutex<HashSet<u32>>,
    #[cfg(feature = "std")]
    next_pba: AtomicU64,
    #[cfg(feature = "std")]
    temperature_c: AtomicU64,

    #[cfg(not(feature = "std"))]
    ftl_map: SyncMutex<heapless::LinearMap<u32, u32, 1024>>,
    #[cfg(not(feature = "std"))]
    dirty_pages: SyncMutex<heapless::LinearMap<u32, bool, 1024>>,
    #[cfg(not(feature = "std"))]
    next_pba: AtomicU64,
    #[cfg(not(feature = "std"))]
    temperature_c: AtomicU64,
}

impl AegisEngine {
    #[cfg(feature = "std")]
    pub fn new() -> Self {
        let mut ufs_array = std::vec::Vec::new();
        for i in 0..NUM_UFS_CHANNELS {
            ufs_array.push(Arc::new(SyncMutex::new(UfsChannel::new(i))));
        }

        Self {
            hmb_cache: SyncMutex::new(HashMap::new()),
            hmb_fifo: SyncMutex::new(VecDeque::new()),
            ufs_array,
            total_ios: AtomicU64::new(0),
            hmb_max_pages: AtomicU64::new(INITIAL_HMB_PAGES),
            active_pages: AtomicU64::new(0),
            is_panic: AtomicBool::new(false),
            pseudo_slc_active: AtomicBool::new(false),
            lost_dirty_pages_count: AtomicU64::new(0),
            host_plp_enabled: AtomicBool::new(true), // Default to enabled for safety
            ftl_map: SyncMutex::new(HashMap::new()),
            dirty_pages: SyncMutex::new(HashSet::new()),
            next_pba: AtomicU64::new(0),
            temperature_c: AtomicU64::new(2500),
        }
    }

    #[cfg(not(feature = "std"))]
    pub fn new() -> Self {
        const CHANNEL: SyncMutex<UfsChannel> = SyncMutex::new(UfsChannel { id: 0, wear_cycles: 0 });
        let mut ufs_array = [CHANNEL; 4];
        for i in 0..4 {
            ufs_array[i] = SyncMutex::new(UfsChannel::new(i));
        }

        Self {
            hmb_cache: SyncMutex::new(heapless::LinearMap::new()),
            hmb_fifo: SyncMutex::new(FixedVec::new()),
            ufs_array,
            total_ios: AtomicU64::new(0),
            hmb_max_pages: AtomicU64::new(INITIAL_HMB_PAGES),
            active_pages: AtomicU64::new(0),
            is_panic: AtomicBool::new(false),
            pseudo_slc_active: AtomicBool::new(false),
            lost_dirty_pages_count: AtomicU64::new(0),
            host_plp_enabled: AtomicBool::new(true),
            ftl_map: SyncMutex::new(heapless::LinearMap::new()),
            dirty_pages: SyncMutex::new(heapless::LinearMap::new()),
            next_pba: AtomicU64::new(0),
            temperature_c: AtomicU64::new(2500),
        }
    }

    #[cfg(feature = "std")]
    pub async fn handle_write(&self, lba: u32) {
        self.handle_write_batch(&[lba]).await;
    }

    #[cfg(feature = "std")]
    pub async fn handle_write_batch(&self, lbas: &[u32]) {
        if self.is_panic.load(Ordering::SeqCst) { return; }

        let hmb_limit = self.hmb_max_pages.load(Ordering::SeqCst);
        let mut direct_writes = std::vec::Vec::new();

        {
            let mut cache = self.hmb_cache.lock().unwrap();
            let mut fifo = self.hmb_fifo.lock().unwrap();
            let mut dirty = self.dirty_pages.lock().unwrap();

            for &lba in lbas {
                // Metadata Safe Path: Bypass volatile HMB for critical blocks (LBA < 100)
                if lba < 100 {
                    direct_writes.push(lba);
                    continue;
                }

                let current_pressure = cache.len() as f64 / hmb_limit as f64;
                
                if current_pressure > PSEUDO_SLC_THRESHOLD {
                    direct_writes.push(lba);
                    continue;
                }
                
                if !cache.contains_key(&lba) {
                    if (cache.len() as u64) >= hmb_limit {
                        if let Some(old_lba) = fifo.pop_front() {
                            cache.remove(&old_lba);
                        }
                    }
                    fifo.push_back(lba);
                }
                cache.insert(lba, std::vec![0; LBA_BLOCK_SIZE as usize]);
                dirty.insert(lba);
            }
            self.active_pages.store(cache.len() as u64, Ordering::SeqCst);
        }

        // Handle Pseudo-SLC direct writes after dropping HMB locks
        if !direct_writes.is_empty() {
            self.pseudo_slc_active.store(true, Ordering::SeqCst);
            for lba in direct_writes {
                self.write_to_ufs_direct(lba).await;
            }
        } else {
            self.pseudo_slc_active.store(false, Ordering::SeqCst);
        }

        self.total_ios.fetch_add(lbas.len() as u64, Ordering::SeqCst);

        // Heat rise per write batch
        let current_temp = self.temperature_c.load(Ordering::Relaxed);
        if current_temp < 5500 {
            let heat_inc = (lbas.len() as u64 * 2).min(100);
            let _ = self.temperature_c.fetch_max(core::cmp::min(5500, current_temp + heat_inc), Ordering::SeqCst);
        }
    }

    #[cfg(feature = "std")]
    async fn write_to_ufs_direct(&self, lba: u32) {
        let mut ftl = self.ftl_map.lock().unwrap();
        let pba = *ftl.entry(lba).or_insert_with(|| {
            self.next_pba.fetch_add(1, Ordering::SeqCst) as u32
        });
        let chip_idx = (pba % NUM_UFS_CHANNELS as u32) as usize;
        let mut chip = self.ufs_array[chip_idx].lock().unwrap();
        chip.write();
    }

    #[cfg(feature = "std")]
    pub async fn get_telemetry(&self) -> Telemetry {
        let mut chip_wears = FixedVec::new();
        let mut total_wear = 0.0;
        
        for chip_arc in &self.ufs_array {
            let wear = chip_arc.lock().unwrap().get_wear_fraction();
            let _ = chip_wears.push(wear);
            total_wear += wear;
        }

        let cache_len = self.active_pages.load(Ordering::SeqCst);
        let hmb_max = self.hmb_max_pages.load(Ordering::SeqCst);
        let pressure = cache_len as f64 / hmb_max as f64;

        let status_str = if self.is_panic.load(Ordering::SeqCst) { "HOST_FLUSH_ACTIVE" } else { "NORMAL_OPERATION" };
        let status = FixedString::<32>::try_from(status_str).unwrap();
        let version = FixedString::<32>::try_from("AEGIS-3.0-ELASTIC").unwrap();

        // Graphene cooling towards ambient (25C)
        let current_temp_c = self.temperature_c.load(Ordering::Relaxed);
        let mut temp_val = current_temp_c as f64 / 100.0;
        if current_temp_c > 2500 {
            let diff = current_temp_c - 2500;
            let cool_rate = (diff / 25).max(1);
            let next_temp = current_temp_c.saturating_sub(cool_rate);
            self.temperature_c.store(next_temp, Ordering::SeqCst);
            temp_val = next_temp as f64 / 100.0;
        }

        let performance_multiplier = if temp_val > 85.0 { 0.5 } else { 1.0 };

        Telemetry {
            total_ios: self.total_ios.load(Ordering::SeqCst),
            hmb_active_pages: cache_len,
            hmb_max_pages: hmb_max,
            hmb_pressure_percentage: pressure * 100.0,
            ufs_wear_percentage: (total_wear / NUM_UFS_CHANNELS as f64) * 100.0,
            chip_wear_array: chip_wears,
            status,
            version,
            temperature: temp_val,
            performance_multiplier,
            pseudo_slc_active: self.pseudo_slc_active.load(Ordering::SeqCst),
            lost_dirty_pages_count: self.lost_dirty_pages_count.load(Ordering::SeqCst),
            host_plp_enabled: self.host_plp_enabled.load(Ordering::SeqCst),
        }
    }

    #[cfg(feature = "std")]
    pub async fn flush_dirty_pages_batch(&self, limit: usize) {
        if self.is_panic.load(Ordering::SeqCst) { return; }
        
        let to_flush: std::vec::Vec<u32>;
        {
            let dirty = self.dirty_pages.lock().unwrap();
            if dirty.is_empty() { return; }
            let to_flush_count = (dirty.len() / 20).max(1).min(limit); 
            to_flush = dirty.iter().take(to_flush_count).cloned().collect();
        }
        
        let mut ftl = self.ftl_map.lock().unwrap();
        let mut dirty = self.dirty_pages.lock().unwrap();
        
        for lba in to_flush {
            let pba = *ftl.entry(lba).or_insert_with(|| {
                self.next_pba.fetch_add(1, Ordering::SeqCst) as u32
            });
            let chip_idx = (pba % NUM_UFS_CHANNELS as u32) as usize;
            let mut chip = self.ufs_array[chip_idx].lock().unwrap();
            chip.write();
            dirty.remove(&lba);
        }
    }

    #[cfg(feature = "std")]
    pub async fn trigger_panic_flush(&self) {
        self.is_panic.store(true, Ordering::SeqCst);
        let mut dirty_lock = self.dirty_pages.lock().unwrap();
        let mut ftl = self.ftl_map.lock().unwrap();
        
        let dirty_list: std::vec::Vec<u32> = dirty_lock.iter().cloned().collect();
        for lba in dirty_list {
            let pba = *ftl.entry(lba).or_insert_with(|| {
                self.next_pba.fetch_add(1, Ordering::SeqCst) as u32
            });
            let chip_idx = (pba % NUM_UFS_CHANNELS as u32) as usize;
            let mut chip = self.ufs_array[chip_idx].lock().unwrap();
            chip.write();
        }
        dirty_lock.clear();
    }

    #[cfg(feature = "std")]
    pub fn set_hmb_capacity(&self, pages: u64) {
        self.hmb_max_pages.store(pages, Ordering::SeqCst);
    }

    #[cfg(feature = "std")]
    pub async fn trigger_sudden_power_loss(&self) {
        // If Host PLP is enabled, simulate power loss recovery by performing a fast panic flush before power goes down completely
        if self.host_plp_enabled.load(Ordering::SeqCst) {
            self.trigger_panic_flush().await;
        } else {
            let mut cache = self.hmb_cache.lock().unwrap();
            let mut fifo = self.hmb_fifo.lock().unwrap();
            let mut dirty = self.dirty_pages.lock().unwrap();

            let lost = dirty.len() as u64;
            self.lost_dirty_pages_count.fetch_add(lost, Ordering::SeqCst);

            cache.clear();
            fifo.clear();
            dirty.clear();
            self.active_pages.store(0, Ordering::SeqCst);
        }
    }

    #[cfg(feature = "std")]
    pub fn toggle_host_plp(&self) {
        let current = self.host_plp_enabled.load(Ordering::SeqCst);
        self.host_plp_enabled.store(!current, Ordering::SeqCst);
    }
}
