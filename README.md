# Code Converter (Binary ⇄ Gray, BCD, Excess-3)

This project implements a **Verilog HDL based code converter** using a **datapath and control path architecture**.  
It supports conversions between **Binary, Gray, BCD, and Excess-3** codes in both directions.

---

## Features
- Binary → Gray  
- Gray → Binary  
- Binary → BCD (Binary Coded Decimal)  
- BCD → Binary  
- BCD → Excess-3  
- Excess-3 → BCD  
- FSM-based control unit with `start`, `busy`, `done` handshaking  

---

## Project Structure
- **Datapath Modules**
  - `binary_to_gray.v`
  - `gray_to_binary.v`
  - `binary_to_bcd.v`
  - `bcd_to_binary.v`
  - `bcd_to_excess3.v`
  - `excess3_to_bcd.v`
- **Control Path**
  - `control_unit.v` – FSM for operation sequencing
- **Integration**
  - `code_converter_top.v` – Top module
- **Verification**
  - `tb_code_converter.v` – Testbench with example cases

---

## Simulation
1. Compile all modules in **ModelSim, Vivado, or EDA Playground**.  
2. Run `tb_code_converter.v`.  
3. Example output:

