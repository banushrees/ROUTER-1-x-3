# 2. Project Objectives

The main objectives of this project are:

- Design a packet-based 1×3 router using Verilog RTL.
- Route packets from one input port to one of three output ports.
- Store packets in destination-specific FIFOs.
- Implement packet parity checking for error detection.
- Handle FIFO full/empty conditions.
- Implement timeout-based FIFO soft reset.
- Verify the RTL using a Verilog testbench.
- Perform linting and structural checks.
- Synthesize the RTL and analyze area, timing, clock, and power reports.

---

# 3. Top-Level Architecture

The Router 1×3 consists of the following major blocks:

                         ┌──────────────────┐
                         │   Router Top     │
                         │   router_top     │
                         └────────┬─────────┘
                                  │
              ┌───────────────────┼───────────────────┐
              │                   │                   │
              ▼                   ▼                   ▼
       ┌─────────────┐     ┌─────────────┐     ┌─────────────┐
       │     FSM     │     │  Register   │     │Synchronizer │
       │ router_fsm  │     │ router_reg  │     │ router_sync │
       └─────────────┘     └─────────────┘     └──────┬──────┘
                                                      │
                         ┌────────────────────────────┼───────────────┐
                         │                            │               │
                         ▼                            ▼               ▼
                    ┌─────────┐                  ┌─────────┐     ┌─────────┐
                    │  FIFO0  │                  │  FIFO1  │     │  FIFO2  │
                    └─────────┘                  └─────────┘     └─────────┘
                         │                            │               │
                         ▼                            ▼               ▼
                    data_out_0                   data_out_1      data_out_2

The top-level design contains three FIFOs, a Synchronizer, a Register block, and a Finite State Machine. The Maven specification identifies these as the six sub-blocks of the router: three FIFOs plus Synchronizer, Register, and FSM.

# 4. Router Interface
Signal	Direction	Description
clock	Input	Active-high clocking event
resetn	Input	Active-low synchronous reset
pkt_valid	Input	Indicates arrival of a new packet
data_in[7:0]	Input	8-bit packet input data
read_enb_0	Input	Enables reading from output FIFO 0
read_enb_1	Input	Enables reading from output FIFO 1
read_enb_2	Input	Enables reading from output FIFO 2
data_out_0[7:0]	Output	Data sent to destination network 1
data_out_1[7:0]	Output	Data sent to destination network 2
data_out_2[7:0]	Output	Data sent to destination network 3
vld_out_0	Output	Indicates valid data at output 0
vld_out_1	Output	Indicates valid data at output 1
vld_out_2	Output	Indicates valid data at output 2
busy	Output	Indicates that the router cannot accept a new byte
error	Output	Indicates packet parity mismatch

The interface behavior follows the supplied Router 1×3 specification. fileciteturn47file0L3-L3

## 5. Packet Format

Each router packet consists of three sections:

┌──────────────┬──────────────────────┬──────────────┐
│    Header    │       Payload        │    Parity    │
└──────────────┴──────────────────────┴──────────────┘
     8 bits          1–63 bytes           8 bits
Header

The header contains:

Destination Address (DA): 2 bits
Payload Length: 6 bits

The destination address determines which output FIFO receives the packet.

DA = 2'b00 → FIFO0
DA = 2'b01 → FIFO1
DA = 2'b10 → FIFO2
DA = 2'b11 → Invalid address

The payload length can range from 1 byte to 63 bytes.

Payload

The payload contains the actual packet data and is transferred byte by byte.

Parity

The parity byte is used to detect corruption. The router calculates internal parity across the header and payload and compares it against the received packet parity.

A mismatch causes the error output to be asserted.

The packet structure, destination-address field, payload-length field, and parity mechanism are defined in the supplied specification. 

## 6. Input Protocol

The input packet transfer follows this sequence:

Header
  ↓
Payload Byte 1
  ↓
Payload Byte 2
  ↓
...
  ↓
Last Payload Byte
  ↓
Parity Byte
Packet reception
pkt_valid is asserted when the header byte is presented on data_in.
The header contains the destination address.
Each payload byte is presented on successive clock cycles.
After the final payload byte, pkt_valid is deasserted.
The parity byte is then presented.
The router checks the received parity against the internally calculated parity.

The specification also states that the testbench should hold the last driven value whenever busy is asserted because incoming bytes are dropped while the router is busy. 

## 7. Output Protocol

Each output channel contains a dedicated FIFO.

                 ┌──────────┐
data_out_0 ◄─────│  FIFO0   │
                 └──────────┘

                 ┌──────────┐
data_out_1 ◄─────│  FIFO1   │
                 └──────────┘

                 ┌──────────┐
data_out_2 ◄─────│  FIFO2   │
                 └──────────┘

For each output:

vld_out_x = 1
      ↓
Receiver detects valid data
      ↓
Receiver asserts read_enb_x
      ↓
Data is read through data_out_x

Each FIFO is specified as 16 locations × 9 bits. The extra bit is used to identify the header byte internally. fileciteturn47file0L9-L13

The receiver must assert the corresponding read_enb_x within 30 clock cycles after vld_out_x is asserted; otherwise a timeout occurs and the FIFO is reset through its soft-reset mechanism. 

## 8. RTL Sub-Blocks
8.1 Router FIFO — router_fifo.v

Three FIFO instances are used:

FIFO0
FIFO1
FIFO2

Each FIFO:

Has a width of 9 bits.
Has a depth of 16 locations.
Uses the system clock.
Uses an active-low synchronous reset.
Supports simultaneous read and write operations.
Prevents write operation when full.
Prevents read operation when empty.
Uses an additional bit to identify the header byte.
Supports internal soft_reset during timeout conditions.

The specification states that the 9th bit is set for the header byte and cleared for the remaining packet bytes. fileciteturn47file0L12-L13

## 8.2 Router Synchronizer — router_sync.v

The Synchronizer provides communication between the router FSM and the three FIFO blocks.

Its main responsibilities include:

Selecting the destination FIFO.
Generating fifo_full.
Generating vld_out_0, vld_out_1, and vld_out_2.
Generating the FIFO write-enable signals.
Generating FIFO soft-reset signals during timeout conditions.

FIFO selection is based on the destination address:

data_in = 2'b00 → fifo_full = full_0
data_in = 2'b01 → fifo_full = full_1
data_in = 2'b10 → fifo_full = full_2
otherwise        → fifo_full = 0

The valid-output signals are generated from FIFO empty status:

vld_out_0 = ~empty_0
vld_out_1 = ~empty_1
vld_out_2 = ~empty_2

The soft-reset logic is activated when a destination receiver does not assert its corresponding read_enb_x within the specified timeout period. 

9. Router Controller / FSM — router_fsm.v

The FSM is the main controller of the router. It generates the control signals required to receive, store, and process a packet.

FSM States
DECODE_ADDRESS
       │
       ▼
LOAD_FIRST_DATA
       │
       ▼
LOAD_DATA
     /     \
fifo_full  pkt_valid=0
   ↓          ↓
FIFO_FULL   LOAD_PARITY
   │           │
   ↓           ▼
LOAD_AFTER_FULL
       │
       ▼
CHECK_PARITY_ERROR
       │
       ▼
DECODE_ADDRESS

Additional state:

WAIT_TILL_EMPTY
State Functions

DECODE_ADDRESS

Initial/reset state.
Detects the incoming packet.
Detects and latches the header byte.

LOAD_FIRST_DATA

Loads the first packet byte into the selected FIFO.
Asserts busy so the already-latched header is not overwritten.
Transitions unconditionally to LOAD_DATA.

LOAD_DATA

Loads payload bytes into the selected FIFO.
Deasserts busy during normal payload reception.
Asserts write_enb_reg.
Moves to LOAD_PARITY when pkt_valid goes low.
Moves to FIFO_FULL_STATE when the selected FIFO becomes full.

LOAD_PARITY

Captures the final parity byte.
Asserts busy.
Writes the parity byte into the FIFO.
Moves to CHECK_PARITY_ERROR.

FIFO_FULL_STATE

Asserts busy.
Deasserts write_enb_reg.
Indicates that the selected FIFO is full.

LOAD_AFTER_FULL

Handles data after a FIFO-full condition.
Uses laf_state.
Returns toward packet completion based on parity_done and low_pkt_valid.

WAIT_TILL_EMPTY

Holds the router busy while waiting for the required FIFO condition.

CHECK_PARITY_ERROR

Generates rst_int_reg.
Completes the parity-check sequence.
Returns toward DECODE_ADDRESS or FIFO_FULL_STATE depending on FIFO status.

These state functions and transitions are based on the supplied router FSM specification. 

## 10. Router Register — router_reg.v

The Register block stores and processes packet information.

It contains internal registers for:

Header byte
FIFO/full-state related information
Internal parity
Packet parity

Important control signals include:

parity_done
low_pkt_valid
err
dout
Parity Calculation

Internal parity is calculated using bitwise XOR:

internal_parity
    = previous_parity ^ header_byte

internal_parity
    = previous_parity ^ payload_byte_1

internal_parity
    = previous_parity ^ payload_byte_2

...

The received packet parity is compared with the internally calculated parity. If the values do not match, err is asserted.

The Register block behavior and parity-generation process follow the supplied specification. 

## 11. Top-Level RTL — router_top.v

The top-level module integrates:

router_fsm
router_reg
router_sync
router_fifo × 3

The top-level module connects the control, packet data, FIFO status, output data, and reset signals between these blocks.

Top-Level Hierarchy
router_top
│
├── FSM
│   └── router_fsm
│
├── REG
│   └── router_reg
│
├── SYNC
│   └── router_sync
│
├── FIFO0
│   └── router_fifo
│
├── FIFO1
│   └── router_fifo
│
└── FIFO2
    └── router_fifo

The supplied RTL design procedure specifies router_top.v as the top-level module, with router_top_tb.v as the testbench, followed by lower-level module instantiation, functional verification, and synthesis.

## 12. Verification

The project includes a Verilog testbench:

tb/router_top_tb.v

The RTL simulation environment was compiled and simulated using Questa Sim.

The recorded simulation completed with:

6 compiles
0 compilation failures

The simulation reached $finish at approximately 780 ns.

## 13. Lint Analysis

Structural lint/check analysis was performed using Synopsys Design Compiler X-2025.06.

The fresh check_design report identified the following categories:

LINT-28 : 12 unconnected ports
LINT-31 :  2 shorted outputs
LINT-52 :  2 constant outputs
LINT-32 :  5 connections to power/ground

The project therefore should not be described as lint-clean.

The complete lint output is available in:

reports/lint_report.txt
## 14. Synthesis

The RTL was synthesized using:

Synopsys Design Compiler X-2025.06
Target Library: lsi_10k.db
Operating Condition: nom_pvt

RTL source files:

router_fifo.v
router_fsm.v
router_sync.v
router_reg.v
router_top.v

Top-level design:

router_top
## 15. Clock Analysis

The synthesized design uses:

Clock name : clk
Clock source: clock
Period     : 10 ns
Waveform   : {0 5}
Frequency  : 100 MHz

The clock report is available at:

reports/clock_report.txt
## 16. Area Analysis

Fresh Design Compiler results:

Parameter	Result
Ports	172
Nets	2,486
Cells	1,875
Combinational cells	1,388
Sequential cells	477
Buffer/Inverter cells	277
Macro/Black Box cells	0
Combinational area	3018
Buffer/Inverter area	395
Non-combinational area	3362
Total cell area	6380

The report states that total area is undefined because no wire-load model was specified for net interconnect area.

The complete report is available at:

reports/area_report.txt
## 17. Static Timing Analysis

The reported maximum-delay path is:

Startpoint:
FIFO0/rd_ptr_reg[3]

        ↓
FIFO0
        ↓
SYNC
        ↓
FSM

Endpoint:
FSM/state_reg[1]

For the analyzed path:

Data arrival time  = 9.77 ns
Data required time = 9.20 ns
Slack              = -0.57 ns

Result:

Timing slack = -0.57 ns
Status       = VIOLATED

This means the analyzed path does not meet the specified 10 ns clock requirement under the reported synthesis conditions.

The complete timing report is available at:

reports/timing_report.txt
## 18. Power Analysis

Fresh Design Compiler power analysis reported:

Net switching power = 30.1477 µW
Total dynamic power = 30.1477 µW

The selected lsi_10k library does not contain characterized internal cell power. The report also indicates that the complete power-group summary cannot be displayed because of unit limitations in the library.

Therefore, the reported value should be treated as a library-dependent switching/dynamic-power estimate, rather than a complete ASIC power characterization.

Complete report:

reports/power_report.txt
19. Analysis Summary
Analysis	Result
RTL modules	5
Output FIFOs	3
FIFO size	16 × 9
Clock period	10 ns
Clock frequency	100 MHz
Ports	172
Nets	2,486
Cells	1,875
Sequential cells	477
Combinational cells	1,388
Total cell area	6380
Critical-path arrival time	9.77 ns
Required time	9.20 ns
Timing slack	-0.57 ns — VIOLATED
Net switching power	30.1477 µW
Reported dynamic power	30.1477 µW
Lint findings	LINT-28 / LINT-31 / LINT-32 / LINT-52
20. Repository Structure
ROUTER-1X3-VERILOG/
│
├── rtl/
│   ├── router_fifo.v
│   ├── router_fsm.v
│   ├── router_reg.v
│   ├── router_sync.v
│   └── router_top.v
│
├── tb/
│   └── router_top_tb.v
│
├── reports/
│   ├── lint_report.txt
│   ├── area_report.txt
│   ├── timing_report.txt
│   ├── power_report.txt
│   └── clock_report.txt
│
├── README.md
└── .gitignore
21. Tools Used
Verilog HDL — RTL design
Questa Sim — RTL simulation
Synopsys Design Compiler X-2025.06 — synthesis, lint/check, area, timing, clock, and power analysis
lsi_10k.db — target standard-cell library
22. Learning Outcomes

This project provided practical exposure to:

Packet-based RTL design
Verilog module hierarchy
FSM-based control logic
FIFO design and integration
Packet routing
Header and payload handling
Parity generation and error detection
FIFO full/empty management
Timeout and soft-reset handling
RTL simulation
Structural linting
Logic synthesis
Static timing analysis
Clock analysis
Area analysis
Power estimation
Interpretation of synthesis reports
