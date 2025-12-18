# Snake Game on ICEUP5K (VHDL)

## Description
This project implements the classic Snake arcade game using VHDL on the ICEUP5K (iCE40 UltraPlus) FPGA. The game is implemented entirely in hardware without a processor. VGA output is used for display, and push buttons or GPIO inputs are used to control the snake’s movement.

---

## Features
* Fully hardware-based Snake game implemented entirely in VHDL
* VGA video output at 640×480 pixels, 60 Hz refresh rate, with HSYNC and VSYNC timing
* Grid-based snake movement with 16×16 pixel cells
* Game tick derived from 12 MHz system clock divided down to ~5 Hz for consistent snake speed
* Snake growth: body stored in register array
* Food spawning at random grid locations
* Collision detection with walls and self
* Push-button or GPIO input for four directions
* Game-over and reset logic fully implemented in FSM


---

## Tools Used
* ICEUP5K FPGA development board
* **Lattice Radiant**
* VGA monitor

---

## Authors
* Wilson Wu
* Lawrence Qiu
* Devon Kumar
* William Cordray

---

## License
This project is licensed under the MIT License.
