# Gravity

[TODO]: Clean up the notes below...

New learnings, things to understand better
- Representing a negative number in 8bits
- Representing a position as 16-bits… the first byte for the pixel position, and the second byte for the sub pixel (which may just be for calc/rounding purposes, but not for drawing)
- Doing 16bit math on an 8bit machine

============================================

TODO

- When A is tapped and the character is standing on something, then set the characters Y velocity to some positive value
- Every frame
    - Add a constant downward acceleration value to the velocity (gravity)
    - Then, add the velocity to the current Y position
    - ^^^ This will cause the jump to have a peak and then a descent

============================================

Pseudocode 1

    lda _JumpFlag
    bne ObjectJumpCont
    sta _YPlayerSubPixel
    inc _jumpFlag
    lda #28
    sta _YPlayerSubPixelConst
    lda #4
    sta _YPlayerVelocity
ObjectJumpCont:
   lda _YPlayerSubPixel
   sec
   sbc _YPlayerSubPixelConst
   sta  _YPlayerSubPixel
   lda _YPlayerVelocity
   sbc #0
   sta _YPlayerVelocity
   lda _YPlayer
   sec
   sbc _YPlayerVelocity
   sta _YPlayer
   rts

============================================

Pseudocode 2

void update_player()
{
	if (on_ground)
	{
		if (button_a) velocity_y = -500; // apply sudden upward velocity for jump
		if (dpad_left) velocity_x -= 5; // accelerate left
		if (dpad_right) velocity_x += 5; // accelerate right
	}

	position_x += velocity_x;
	resolve_horizontal_collision();

	position_y += velocity_y;
	resolve_vertical_collision();

	velocity_y += 10; // apply gravity
}

void main_loop()
{
	setup_level();
	draw_frame();
	rendering_on();

	while (!quit)
	{
		poll_gamepad();
		update_player();
		update_enemies();
		draw_frame();
		wait_vblank();
	}
}

============================================

Pseudocode 3

;Note I picked all these constants arbitrarily, I wouldn't know without running the code what the jump would look like. I would then tweak these values til I get the arc that I want.

ACCELERATION = 100
START_JUMP = -50  ;on ca65 you would need to use feature .force_range for it to be happy with negative values used as bytes

;zp variables
y_coordinate: .res 3
y_velocity: .res 2
sign_extend_byte: .res 1


;when you detect A button and the character is standing on something

    lda #<START_JUMP
    sta y_velocity
    lda #>START_JUMP
    sta y_velocity+1


....


;on each frame. You would always do this--jumping just sets y velocity to an initial value, landing on a tile (not included in example) would set y velocity to 0. Ejection would keep it at 0 if you're standing on a tile.

    ;Add 16 bit y velocity to 24 bit y coordinate with sign extension. 16 bit world coordinates, 8 bit sub pixel precision
    lda #0
    sta sign_extend_byte
    lda y_coordinate+3
    bpl :+
    lda #$ff
    sta sign_extend_byte
:
    clc
    lda y_coordinate
    adc y_velocity
    sta y_coordinate
    lda y_coordinate+1
    adc y_velocity+1
    sta y_coordinate+1
    lda y_coordinate+2
    adc sign_extend_byte
    sta y_coordinate+2

    ;Now add acceleration to y velocity
    clc
    lda y_velocity
    adc #<ACCELERATION
    sta y_velocity
    lda y_velocity+1
    adc #>ACCELERATION
    sta y_velocity+1
