# Snake Game on ICEUP5K (VHDL)

## Description
This project implements the classic **Snake** arcade game using **VHDL** on the **ICEUP5K (iCE40 UltraPlus)** FPGA. The game is implemented entirely in hardware without a processor. VGA output is used for display, and push buttons or GPIO inputs are used to control the snake’s movement.

The design uses synchronous logic with a system clock and a divided game tick to control snake movement independently from VGA refresh timing.

---

## Features
* Fully hardware-based implementation in VHDL
* VGA video output (e.g., 640×480 @ 60 Hz)
* Grid-based snake movement
* Clock-divider-based game timing
* Snake growth and food consumption
* Wall and self-collision detection
* Game-over and reset functionality

---

## Tools Used
* ICEUP5K FPGA development board
* **Lattice Radiant**
* VGA monitor
* Windows 10 / 11

---

## Authors
* **Wilson Wu**
* Lawrence Qiu
* Devon Kumar
* William Cordray

---

## License
This project is licensed under the **MIT License**.
