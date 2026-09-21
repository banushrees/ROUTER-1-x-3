# ROUTER-1-X-3
## 1. Project Overview
<img width="1536" height="1024" alt="ChatGPT Image Sep 21, 2026, 11_02_24 PM" src="https://github.com/user-attachments/assets/507176ad-a167-432d-88ca-f9647555ee0d" />

The Alarm Clock is a digital clock design that maintains the current time, allows the user to enter a new time or alarm time using a 4-bit keypad input, displays the selected time in LCD-compatible format, and generates an alarm output when the current time matches the programmed alarm time.

The Maven specification defines the top-level Alarm Clock around six major functional blocks:

1. Time Generator
2. Key Register
3. Alarm Register
4. Counter
5. Alarm Controller
6. Display Driver

The specification identifies these as sequential logic blocks except for the display driver, which is combinational logic. fileciteturn46file0L1-L3

---

## 2. Top-Level I/O

The specified top-level interface contains:

| Signal | Description |
|---|---|
| `clk` | 256 Hz clock |
| `reset` | Asynchronous active-high reset |
| `key[3:0]` | 4-bit keypad input |
| `alarm_button` | Active-high control for setting alarm time |
| `time_button` | Active-high control for setting current time |
| `fast_watch` | Enables faster clock behavior for simulation |
| `sound_alarm` | Active-high alarm output |
| `display_ms_hr[7:0]` | Most-significant hour LCD output |
| `display_ls_hr[7:0]` | Least-significant hour LCD output |
| `display_ms_min[7:0]` | Most-significant minute LCD output |
| `display_ls_min[7:0]` | Least-significant minute LCD output |

The Maven specification describes `clk` as a 256 Hz clock, `reset` as asynchronous active-high, `key` as a four-bit input, and `sound_alarm` as an active-high output. It also defines `fast_watch` as a mode that makes the clock run faster for simulation. fileciteturn46file0L1-L1

---

## 3. Top-Level Architecture

The Alarm Clock is organized around the following functional blocks:

text
                         ┌─────────────────────┐
                         │    Time Generator   │
                         └──────────┬──────────┘
                                    │
                           one_second / one_minute
                                    │
                                    ▼
┌──────────────┐          ┌─────────────────────┐
│  Key Register│◄─────────│   Alarm Controller │
└──────┬───────┘          └──────┬──────┬───────┘
       │                         │      │
       │                         │      ├── show_a
       │                         │      ├── show_new_time
       │                         │      ├── load_new_a
       │                         │      └── load_new_c
       │                         │
       ▼                         ▼
┌──────────────┐          ┌─────────────────────┐
│Alarm Register│          │       Counter       │
└──────┬───────┘          └──────────┬──────────┘
       │                              │
       └──────────────┬───────────────┘
                      │
                      ▼
              ┌─────────────────┐
              │  Display Driver │
              └────────┬────────┘
                       │
              ┌────────┴────────┐
              ▼                 ▼
       LCD display outputs   sound_alarm

The Maven top-level specification requires all lower-level modules to be instantiated according to the architecture, followed by testbench verification and RTL synthesis. fileciteturn46file0L18-L18

## 4. Functional Blocks
### 4.1 Time Generator

The Time Generator is a sequential block that generates the one_second and one_minute pulses used by the Counter.

For a 256 Hz clock:

1 second = 256 clock cycles

1 minute = 256 × 60
         = 15360 clock cycles

The specified behavior includes:

one_second becomes active for one clock period after 256 cycles.
one_minute becomes active for one clock period after 15360 cycles.
When fast_watch = 1, one_minute follows one_second for faster simulation.
reset_count = 1 resets the generated outputs.
reset = 1 resets the outputs.

These behaviors are defined in the Maven project specification. fileciteturn46file0L9-L10

## 4.2 Counter

The Counter maintains the current hour and minute digits.

Its specified behavior is:

reset = 1
→ all outputs reset to ZERO

load_new_c = 1 and reset = 0
→ load new current-time values

load_new_c = 0 and one_minute = 0
→ retain previous values

load_new_c = 0 and one_minute = 1
→ increment according to the clock-counting algorithm

The counting sequence follows the standard 24-hour BCD-style transitions specified by Maven. fileciteturn46file0L11-L12

Counting Algorithm
LS_MIN = 9
→ LS_MIN = 0
  MS_MIN = MS_MIN + 1

MS_MIN = 5 AND LS_MIN = 9
→ MS_MIN = 0
  LS_MIN = 0
  LS_HR = LS_HR + 1

LS_HR = 9 AND MS_MIN = 5 AND LS_MIN = 9
→ MS_MIN = 0
  LS_MIN = 0
  LS_HR = 0
  MS_HR = MS_HR + 1

MS_HR = 2 AND LS_HR = 3 AND MS_MIN = 5 AND LS_MIN = 9
→ all time digits = 0
## 4.3 Key Register

The Key Register is a sequential block that stores keypad values and shifts previously entered digits.

The key is loaded into key_buffer_ls_min on the positive clock edge when shift is asserted. Existing values are shifted through the other digit registers.

key
 ↓
key_buffer_ls_min
 ↓
key_buffer_ms_min
 ↓
key_buffer_ls_hr
 ↓
key_buffer_ms_hr

The specified key-entry behavior supports entering the four time digits from right to left. fileciteturn46file0L13-L14

## 4.4 Alarm Register

The Alarm Register is a sequential block that stores the programmed alarm time.

Specified behavior:

reset = 1
→ all outputs become ZERO

load_new_a = 1 and reset = 0
→ outputs load the new alarm-time inputs

load_new_a = 0 and reset = 0
→ outputs retain their previous values

This block stores the four BCD alarm-time digits. fileciteturn46file0L8-L8

## 4.5 Alarm Controller

The Alarm Controller generates control signals for the Key Register, Counter, Display Driver, and Time Generator.

The specified control outputs include:

reset_count
load_new_c
show_new_time
show_a
load_new_a
shift

The controller handles:

Key entry
Setting the current time
Setting the alarm time
Displaying the alarm time
Timing out incomplete key entry
Returning the display to the current time

The Maven specification states that digits 0–9 are valid time-entry keys and 10 represents No Key. A maximum of 10 seconds is allowed for each key entry. fileciteturn46file0L15-L16

Controller FSM

The specified controller states are:

SHOW_TIME
    │
    ├── key != 10 ──► KEY_ENTRY
    │
    └── alarm_button ──► SHOW_ALARM

KEY_ENTRY
    │
    ├── key == 10 ──► KEY_WAITED
    ├── key != 10 ──► KEY_ENTRY
    ├── alarm_button ──► SET_ALARM_TIME
    └── time_button ──► SET_CURRENT_TIME

KEY_WAITED
    │
    ├── time_out == 0 ──► SHOW_TIME
    └── key == 10 / timeout behavior

SET_ALARM_TIME ──► SHOW_TIME

SET_CURRENT_TIME ──► SHOW_TIME

SHOW_ALARM
    │
    └── !alarm_button ──► SHOW_TIME

The state names and transition conditions follow the supplied Maven controller-FSM specification. fileciteturn46file0L17-L17

## 4.6 LCD Display Driver

The Display Driver is the combinational logic portion of the design.

It selects which four-bit BCD time value should be displayed based on:

show_a
show_new_time

Specified selection:

show_a = 1 AND show_new_time = 0
→ display alarm time

show_a = 0 AND show_new_time = 0
→ display current time

show_a = 0 AND show_new_time = 1
→ display newly entered key time

The input time values use 4-bit BCD values. fileciteturn46file0L4-L5

BCD-to-LCD Mapping
BCD	LCD value
0000	8'h30
0001	8'h31
0010	8'h32
0011	8'h33
0100	8'h34
0101	8'h35
0110	8'h36
0111	8'h37
1000	8'h38
1001	8'h39

The mapping is specified by the supplied Maven material. fileciteturn46file0L5-L5

## 4.7 LCD Display Unit

The LCD Display Unit combines the four time digits:

MS_HR : LS_HR : MS_MIN : LS_MIN

and produces the four 8-bit LCD-compatible display outputs.

The Maven specification identifies this as the display unit responsible for displaying the four hour/minute digits in LCD format. fileciteturn46file0L6-L7

## 5. Verification Architecture

The project was verified using a SystemVerilog/UVM-based verification environment.

The repository is organized into:

alarm_clock_env/
alarm_clock_test/
alarm_clock_ip_agent/
alarm_clock_display_agent/
alarm_clock_assertions/
rtl/
sim/

The verification environment includes:

Transaction-based stimulus
UVM agents
Drivers
Monitors
Scoreboard/reference checking
UVM tests
SystemVerilog Assertions
Functional coverage
Coverage reporting
## 6. SystemVerilog Assertions

SVA was used to verify important temporal/protocol behaviors of the Alarm Clock RTL.

Assertions are bound into the DUT hierarchy through the testbench.

The project includes:

alarm_clock_assertions/

and the simulation flow enables assertion checking and assertion coverage.

## 7. Verification Tests

The simulation flow contains multiple tests, including:

alarm_clock_test
alarm_clock_rand_test
alarm_clock_current_time_test
alarm_clock_child_test

The regression flow executes the relevant test cases and merges their coverage databases.

## 8. Functional Coverage

Coverage is collected using Synopsys VCS coverage options and merged using URG.

The project generates an HTML coverage report under:

urgReport/dashboard.html

The final fresh coverage dashboard obtained from the project showed:

Coverage Metric	Result
Overall URG score	84.38%
Assertion coverage	80.00%
Group coverage	88.75%
top.DUV score	85.71%
top.DUV assertion coverage	85.71%
alarm_clock_pkg	100%
Module definition coverage	80%

These values represent the coverage report generated from the project regression.

## 9. Simulation Result

The simulation completed with:

UVM_INFO     : 100
UVM_WARNING  : 0
UVM_ERROR    : 1
UVM_FATAL    : 0

The simulation finished at approximately:

9123517578125

The single UVM error was reported by the scoreboard as:

SOUND ALARM IS NOT WORKING PROPERLY

Therefore, the project is not described as completely error-free. The scoreboard finding is retained as part of the verification evidence and can be investigated further.

## 10. Coverage Reporting Flow

The VCS coverage flow used:

VCS
 ↓
Simulation tests
 ↓
Coverage databases
 ↓
URG merge
 ↓
HTML coverage report
 ↓
urgReport/dashboard.html

The report can be opened locally with:

firefox "$(pwd)/urgReport/dashboard.html" &
## 11. Repository Structure
ALARM-CLOCK-SVA/
│
├── rtl/
│
├── alarm_clock_env/
│
├── alarm_clock_test/
│
├── alarm_clock_ip_agent/
│
├── alarm_clock_display_agent/
│
├── alarm_clock_assertions/
│
├── sim/
│   └── Makefile
│
├── result
├── topology result
├── README.md
└── .gitignore

The result and topology result files are retained as project evidence containing simulation/verification information.

Generated simulator and coverage databases should not be committed to the repository.

## 12. Tools Used
Verilog — RTL design
SystemVerilog — testbench and verification
UVM — constrained/randomized verification environment
SVA — temporal assertion checking
Synopsys VCS X-2025.06 — simulation and coverage
Synopsys URG — coverage report generation
Verdi — waveform/debug support
## 13. Project Workflow
Maven Functional Specification
            ↓
        RTL Design
            ↓
      RTL Simulation
            ↓
       UVM Testbench
            ↓
      Scoreboard Checks
            ↓
        SVA Checking
            ↓
    Functional Coverage
            ↓
      VCS Coverage DB
            ↓
        URG Merge
            ↓
      HTML Coverage Report
## 14. Key Learning Outcomes

This project demonstrates practical experience with:

RTL design and module integration
Sequential and combinational logic
FSM-based control design
BCD time representation
Clock-divider/time-generation logic
FIFO-style verification concepts
SystemVerilog class-based verification
UVM testbench architecture
Constrained-random testing
Scoreboard-based checking
SystemVerilog Assertions
Functional coverage
Coverage database merging
VCS/URG simulation and reporting
Debugging simulation failures
## 15. Known Results & Areas for Improvement

The current project provides measurable verification evidence, but it also exposes areas for further improvement:

Investigate the single scoreboard error related to sound_alarm.
Increase assertion coverage from the current reported level.
Increase functional/group coverage.
Add additional corner-case alarm-time and current-time scenarios.
Improve coverage closure for unhit bins.
Add more targeted assertions for controller state transitions.
Investigate the exact synchronization/timing relationship behind the sound_alarm scoreboard mismatch.

These improvements would make the verification environment more comprehensive and improve coverage closure.

## 16. Reference

The functional architecture, I/O definition, module descriptions, timing behavior, controller states, counting algorithm, and RTL design procedure documented in this README are based on the supplied Maven Silicon Alarm Clock training material. The project-specific implementation, verification results, coverage values, and simulation results are documented separately based on the repository's actual execution.
