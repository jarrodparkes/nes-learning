# Lecture

NES development is vastly different than writing modern software. There is no operating system, software development kit (SDK), integrated development environment (IDE), etc. Instead, you have to do everything by hand.

## Memory-Mapped Input/Output (I/O)

[TBD]

## The NES Memory Map

[TBD]

## "The Game Loop"

NES games fall into a category of software which have an input or "game" loop where they regularly check for user input. For NES games, the typical code path involves the following steps:

1. check/handle user input
2. run game logic
3. prepare/update graphics for screen
4. repeat

## Basic NES Game Structure

header
{
	- include header information
	- define constants
	- reserve RAM locations for variables
}

start_up
{
	RESET
		- turn off all interrupt signals, etc.
		- turn off rendering
		- initialize stack

	CLEAR_MEM
		- ensure all hardware has booted
		- clear RAM/VRAM any RAM
		- initialize any sub-systems
		- initialize any game variables
}

game_loop
{
	MAIN
		- handle input
		- run game logic
		- update sound
		- prepare video/graphics data
		- wait until video/graphics should be updated (has frame counter updated?)
		- update video/graphics
		- goto MAIN
}

interrupts (platform specific)
{
	NMI (NES)
		- increment frame counter
}

footer
{
	- include graphics ROM
	- include any additional ROM
}
