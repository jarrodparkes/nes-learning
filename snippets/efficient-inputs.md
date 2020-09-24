# Efficient Inputs

[TODO]: [Continue paraphrasing this...](https://forums.nesdev.com/viewtopic.php?f=10&t=16276)

## Hold Inputs

## Press Inputs

## Example: Reading Button States into a Single Byte

```
ReadControllers:
  lda #$01
  sta $4016
  lda #$00
  sta $4016  ; read from controller 1, but not controller 2

  ldx #$08
  lda $4016
  lsr
  rol buttons
  dex
  bne
  rts
```

This snippet reads the first controller's button state into "buttons" such that bit 7 would be A, bit 6 would be B, bit 5 Select, bit 4 Start, and then the d-pad buttons.
