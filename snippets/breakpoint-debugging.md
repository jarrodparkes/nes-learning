# Breakpoint Debugging

You may be familiar with breakpoints in modern IDE's, but how can you use breakpoints to assist with NES development? The easiest way is to start with the right emulator.

## FCEUXD SP


## Example

[TODO: cleanup]

Try opening up some of your favorite games in FCEUXD SP and set a breakpoint on writes to $4015.  Take a look at what values are getting written there.  If you don't know how to do this, follow these steps:

1. Open FCEUXD SP
2. Load a ROM
3. Open up the Debugger by pressing F1 or going to Tools->Debugger
4. In the top right corner of the debugger, under "BreakPoints", click the "Add..." button
5. Type "4015" in the first box after "Address:"
6. Check the checkbox next to "Write"
7. Set "Memory" to "CPU Mem"
8. Leave "Condition" and "Name" blank and click "OK"

Now FCEUX will pause emulation and snap the debugger anytime your game makes a write (usually via STA) to $4015.  The debugger will tell you the contents of the registers at that moment, so you can check what value will be written to $4015.  Some games will write to $4015 every frame, and some only do so once at startup.  Try resetting the game if your debugger isn't snapping.
