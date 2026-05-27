import json
import os

# Professional BOM for Infinity-Cache Proxy (V1.0 FPGA Prototype)
# Based on PRD Section 5.1

bom_data = {
    "Project": "Infinity-Cache Proxy",
    "Version": "1.0-PROTO",
    "Base_Board": [
        {"Item": "Lattice ECP5-25F FPGA", "MPN": "LFE5U-25F-6BG256C", "Qty": 1, "Est_Unit_Price_INR": 1100, "Category": "IC-Bridge"},
        {"Item": "High-Temp Tantalum Polymer", "MPN": "T540 Polymer 330uF 4V (x10 Array)", "Qty": 2, "Est_Unit_Price_INR": 450, "Category": "Power-Vault"},
        {"Item": "TI PMIC / Load Switch", "MPN": "TPS22929", "Qty": 1, "Est_Unit_Price_INR": 250, "Category": "Power-Management"},
        {"Item": "Mezzanine Socket (Base)", "MPN": "Hirose DF40C-80DS-0.4V", "Qty": 1, "Est_Unit_Price_INR": 150, "Category": "Connector"},
        {"Item": "PCB (6-Layer ENIG)", "MPN": "Custom M.2 2280", "Qty": 1, "Est_Unit_Price_INR": 2000, "Category": "Fabrication"},
    ],
    "Cartridge": [
        {"Item": "8GB LPDDR5 DRAM", "MPN": "MT53E2G32D4DE-046", "Qty": 1, "Est_Unit_Price_INR": 950, "Category": "Memory-Cache"},
        {"Item": "Raw SLC NAND (Emergency Log)", "MPN": "MT29F32G08CBACA", "Qty": 1, "Est_Unit_Price_INR": 250, "Category": "Memory-Emergency"},
        {"Item": "512GB UFS 4.0 (x2 Array)", "MPN": "KLUEG8UHGC-B0E1", "Qty": 1, "Est_Unit_Price_INR": 2800, "Category": "Memory-Vault"},
        {"Item": "Mezzanine Header (Plug)", "MPN": "Hirose DF40C-80DP-0.4V", "Qty": 1, "Est_Unit_Price_INR": 120, "Category": "Connector"},
    ],
    "Development_Tools": [
        {"Item": "Lattice Diamond Programmer", "MPN": "HW-USBN-2B", "Qty": 1, "Est_Unit_Price_INR": 8500, "Category": "Tools"},
        {"Item": "Digital Oscilloscope (Entry)", "MPN": "Rigol DS1054Z", "Qty": 1, "Est_Unit_Price_INR": 35000, "Category": "Tools"},
    ]
}

def generate_report():
    print("-" * 50)
    print("INVESTOR-READY BILL OF MATERIALS (BOM)")
    print("-" * 50)
    total_cost = 0
    
    for section, items in bom_data.items():
        if isinstance(items, list):
            print(f"\n[ {section.replace('_', ' ')} ]")
            for i in items:
                cost = i['Qty'] * i['Est_Unit_Price_INR']
                total_cost += cost
                print(f" - {i['Item']:<25} | Qty: {i['Qty']} | Est: INR {cost}")
    
    print("\n" + "=" * 50)
    print(f"TOTAL ESTIMATED PROTOTYPE CAPITAL: ₹{total_cost}")
    print("=" * 50)
    print("\nNOTE: Prices are estimates based on 2026 electronics spot markets.")

if __name__ == "__main__":
    generate_report()
" * 50)
    print("\nNOTE: Prices are estimates based on 2026 electronics spot markets.")

if __name__ == "__main__":
    generate_report()
