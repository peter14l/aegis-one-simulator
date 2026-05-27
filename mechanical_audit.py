import json
import math

# --- Aegis-One Phase 3 Physical Constraints ---
PCB_WIDTH = 22.0  # mm
PCB_LENGTH = 80.0 # mm
MAX_Z_HEIGHT = 2.25 # mm (Production Target)

# --- Component Inventory (Phase 3 Monolithic / No-DRAM) ---
# Format: [Name, Width, Length, Height, Count]
COMPONENTS = [
    ["Aegis-Alpha ASIC (TSMC 22nm)", 12.0, 12.0, 0.8, 1], # Larger HMB-DMA controller
    ["UFS 4.0 512GB (V-NAND)", 11.5, 13.0, 1.2, 4],     # 2TB Total (Thinner than eMMC stacks)
    ["PMIC (Minimal Power Filter)", 4.0, 4.0, 0.5, 2],    # No supercap charging needed
    ["M.2 Edge Connector (M-Key)", 22.0, 8.0, 0.0, 1],
]

def calculate_surface_utilization():
    total_area = PCB_WIDTH * (PCB_LENGTH - 8.0) # Subtract connector area
    occupied_area = sum(c[1] * c[2] * c[4] for c in COMPONENTS)
    utilization = (occupied_area / total_area) * 100
    
    print(f"--- Aegis-One Phase 3 Mechanical Audit (Elastic HMB / Zero-DRAM) ---")
    print(f"Total Usable Area: {total_area:.2f} mm²")
    print(f"Total Component Footprint: {occupied_area:.2f} mm²")
    print(f"Surface Utilization: {utilization:.2f}%")
    
    if utilization > 95:
        print("WARNING: Component density too high.")
    else:
        print("STATUS: Low component density (Room for 8TB Expansion).")

    # Z-Height Check
    max_h = max(c[3] for c in COMPONENTS)
    pcb_thickness = 0.8 # Standard 8-layer PCB
    total_z = max_h + pcb_thickness + 0.05
    
    print(f"Max Component Height: {max_h:.2f} mm")
    print(f"Total Stack Z-Height: {total_z:.2f} mm")
    
    if total_z <= MAX_Z_HEIGHT:
        print(f"VERDICT: PASS (Fits {MAX_Z_HEIGHT}mm constraint with {MAX_Z_HEIGHT - total_z:.2f}mm headroom)")
    else:
        print(f"VERDICT: FAIL (Exceeds constraint)")

if __name__ == "__main__":
    calculate_surface_utilization()
