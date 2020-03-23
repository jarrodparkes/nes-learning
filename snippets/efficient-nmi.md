# Efficient NMI

The NMI signal is arguably one of the most important parts of NES development. Efficient use of this signal ensures your game "runs in real-time" at a smooth 60 frames per second. Anything less will feel clunky and slow — not a good gaming experience.

## NMI and VBLANK

Once you've finished initializing the NES, you will most likely enable the NMI signal. The NMI signal fires each time the PPU has finished drawing a full screen of graphics (a frame). As soon as the NMI fires, the PPU enters an idle state giving you the opportunity to make safe graphical changes before the PPU becomes active again and starts drawing another frame. The period of time in which the PPU is idle directly correlates to VBLANK: the amount of time is takes for a raster display to move its laser from the lower right-hand corner of the screen (after rendering a frame) to the upper left-hand corner of the screen (to start a new frame).

On a NTSC NES, VBLANK is 20 scanlines or 2273 cycles. If you take into account the overhead required to switch in-and-out of your NMI subroutine, then the usable VBLANK time period is more like 2250 cycles.

## When Real-Time Matters

The 2250 usable VBLANK cycles are absolutely precious. If any graphical updates in your NMI subroutine are made beyond those 2250 cycles, then you open yourself up to a myriad of visual glitches, slowdowns, and insanely-hard-to-debug problems. But, despite this reality, not all graphical updates are beholden to this strict cycle restriction. The cycle restriction should only apply to real-time graphical updates or "update drawing" — the kind of drawing you do mid-gameplay.

When a game is not in the middle of the action, like when a new level is being loaded, real-time updates are no longer as important. It is expected and even preferable for some visual updates to take multiple frames to complete. These kinds of visual updates can be classified as "bulk drawing".

## Update Drawing

## Bulk Drawing

[TODO]: [Continue paraphrasing this...](https://wiki.nesdev.com/w/index.php/The_frame_and_NMIs)
