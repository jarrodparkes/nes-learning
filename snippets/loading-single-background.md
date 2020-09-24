# Loading a Single Background

## Un-Optimized Loading

- The fastest that you can copy a byte from one location to another is 8 cycles (LDA + STA).
- A full background is 1024 bytes, meaning you'd need at least 8192 cycles to copy an entire background. And, that does not consider the overhead of loops or the NMI handler.
- VBlank only lasts ~2273 cycles. So, best case scenario, you need 4 frames (screen refreshes) to load a full background. 
