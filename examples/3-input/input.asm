;------------------------------------------------------------------------------------------\
; [NES HEADER DIRECTIVES]
  .inesprg 1  ; using 1x 16KB PRG bank
  .ineschr 1  ; using 1x 8KB CHR bank
  .inesmap 0  ; mapper 0 = NROM, is NROM-128 b/c using 1x 16Kib PRG bank
  .inesmir 1  ; background mirroring
;------------------------------------------------------------------------------------------/

;------------------------------------------------------------------------------------------\
; [SEMANTICS]
; Numbers prefixed with # should be interpreted as values (ex: #$40).
; Numbers not prefixed with # should be interpreted as address (ex: $0005).
; Numbers beginning with % are binary.
; Numbers beginning with $ are hexadecimal.
;------------------------------------------------------------------------------------------/

;------------------------------------------------------------------------------------------\
; [SYSTEM VARIABLES]
PPU_CTRL      EQU $2000
PPU_MASK      EQU $2001
PPU_STATUS    EQU $2002
PPU_OAM_ADDR  EQU $2003
PPU_OAM_DATA  EQU $2004
PPU_SCROLL    EQU $2005
PPU_ADDR      EQU $2006
PPU_DATA      EQU $2007
PPU_OAM_DMA   EQU $4014
PPU_FRAMECNT  EQU $4017
DMC_FREQ      EQU $4010
CTRL_PORT1    EQU $4016
ZERO_PG_TMP   EQU $00F0
;------------------------------------------------------------------------------------------/

;------------------------------------------------------------------------------------------\
; [MAIN]
  .bank 0
  .org $C000          ; start location of bank 0 ($C000 in CPU memory space)
Reset:
  SEI                 ; disable all CPU IRQs
  CLD                 ; disable decimal mode
  LDX #$40            ; X = %01000000
  STX PPU_FRAMECNT    ; disable APU frame IRQ

ResetStack:
  LDX #$FF
  TXS

ResetMore:
  INX                 ; X = %00000000
  STX PPU_CTRL        ; disable NMI/VBLANK
  STX PPU_MASK        ; disable rendering
  STX DMC_FREQ        ; disable DMC IRQs

WaitVBlank1:          ; wait for VBLANK, to make sure PPU is ready
  BIT PPU_STATUS
  BPL WaitVBlank1

ClrMem:
  LDA #$00            ; A = %00000000
  STA $0000, X        ; zero out value at this address
  STA $0100, X        ; zero out value at this address
  STA $0300, X        ; zero out value at this address
  STA $0400, X        ; zero out value at this address
  STA $0500, X        ; zero out value at this address
  STA $0600, X        ; zero out value at this address
  STA $0700, X        ; zero out value at this address
  LDA #$FE
  STA $0200, X        ; move sprite off screen
  INX
  BNE ClrMem          ; keep looping until X = %00000000

WaitVBlank2:          ; wait for VBLANK, PPU is ready after this
  BIT PPU_STATUS
  BPL WaitVBlank2

PrepPaletteLoad:
  LDA PPU_STATUS      ; tell PPU to expect the high byte next
  LDA #$3F
  STA PPU_ADDR        ; write the high byte of $3F00 address
  LDA #$00
  STA PPU_ADDR        ; write the low byte of $3F00 address
  LDX #$00            ; now PPU_DATA is ready to accept data

LoadPalette:
  LDA Palette, X      ; load palette byte
  STA PPU_DATA        ; write to PPU
  INX                 ; set index to next byte
  CPX #$20            ; check if X == $20 (32)
  BNE LoadPalette     ; keep looping until all 32 bytes are copied
  LDX #$00

LoadSprites:
  LDA Sprites, X      ; load sprite byte
  STA $0200, X        ; write sprite btye
  INX                 ; set index to next byte
  CPX #$30            ; check if X == $30 (48)
  BNE LoadSprites     ; keep looping until all 48 bytes are copied

PrepTileLoad:         ; update PPU_ADDR to load tiles and attrs
  LDA PPU_STATUS      ; tell PPU to expect the high byte next
  LDA #$20
  STA PPU_ADDR        ; write the high byte of $2000 address
  LDA #$00
  STA PPU_ADDR        ; write the low byte of $2000 address
  LDX #$00            ; now PPU_DATA is ready to accept data

LoadTiles:            ; loop and load all tile bytes, followed by attr bytes
  LDX #LOW(Tiles)
  LDY #HIGH(Tiles)
  STX <ZERO_PG_TMP    ; write the low byte of tiles address to ZERO_PG_TMP
  STY <ZERO_PG_TMP+1  ; write the high byte of tiles address to ZERO_PG_TMP+1
  LDX #4              ; X = 4 (outer loop)
  LDY #0              ; Y = 0 (inner loop)
.1
  LDA [ZERO_PG_TMP],Y ; load byte from address $[HIGH+LOW]
  STA PPU_DATA        ; write to PPU
  INY
  BNE .1              ; keep looping until 256 bytes are copied
  INC <ZERO_PG_TMP+1  ; outer loop finished
  DEX
  BNE .1              ; keep looping until all 1024 (256*4) bytes are copied

FinishGraphicInit:
  LDA #%10010000      ; enable NMI/VBLANK, sprites from table 0, tiles from table 1
  STA PPU_CTRL
  LDA #%00011110      ; enable sprites, enable background, no clipping on left side
  STA PPU_MASK

Forever:
  JMP Forever         ; loop forever
;------------------------------------------------------------------------------------------/

;------------------------------------------------------------------------------------------\
; [NMI HANDLER]
VBlankStarted:
DMATransfer:
  LDA #$00
  STA PPU_OAM_ADDR    ; write the low byte of $0200 address
  LDA #$02
  STA PPU_OAM_DMA     ; write the low byte of $0200 address, start DMA transfer

PrepController:
  LDA #$01            ; prep CTRL_PORT1
  STA CTRL_PORT1
  LDA #$00
  STA CTRL_PORT1      ; now we're ready to read from CTRL_PORT1

ReadButtons:          ; read one-at-a-time (A, B, Select, Start, Up, Down, Left, Right)
ReadA:
  LDA CTRL_PORT1      ; player 1
  AND #%00000001      ; check A button
  BEQ ReadADone       ; if A is not pressed, skip to ReadADone
  LDA $0212
  EOR #%00000001
  STA $0212           ; if A is pressed, flip/flop sprite palette 0/1
ReadADone:

ReadB:
  LDA CTRL_PORT1      ; player 1
  AND #%00000001      ; check B button
  BEQ ReadBDone       ; if B is not pressed, skip to ReadBDone
  LDA $0216
  EOR #%00000001
  STA $0216           ; if B is pressed, flip/flop sprite palette 0/1
ReadBDone:

ReadSelect:
  LDA CTRL_PORT1
  AND #%00000001
  BEQ ReadSelectDone
  LDA $021A
  EOR #%00000001
  STA $021A
ReadSelectDone:

ReadStart:
  LDA CTRL_PORT1
  AND #%00000001
  BEQ ReadStartDone
  LDA $021E
  EOR #%00000001
  STA $021E
ReadStartDone:

ReadUp:
  LDA CTRL_PORT1
  AND #%00000001
  BEQ ReadUpDone
  LDA $0222
  EOR #%00000001
  STA $0222
ReadUpDone:

ReadDown:
  LDA CTRL_PORT1
  AND #%00000001
  BEQ ReadDownDone
  LDA $0226
  EOR #%00000001
  STA $0226
ReadDownDone:

ReadLeft:
  LDA CTRL_PORT1
  AND #%00000001
  BEQ ReadLeftDone
  LDA $022A
  EOR #%00000001
  STA $022A
ReadLeftDone:

ReadRight:
  LDA CTRL_PORT1
  AND #%00000001
  BEQ ReadRightDone
  LDA $022E
  EOR #%00000001
  STA $022E
ReadRightDone:

PrepGraphics:
  LDA #%10010000      ; enable NMI/VBLANK, sprites from table 0, tiles from table 1
  STA PPU_CTRL
  LDA #%00011110      ; enable sprites, enable background, no clipping on left side
  STA PPU_MASK
  LDA #$00            ; tell PPU no background scrolling
  STA PPU_SCROLL
  STA PPU_SCROLL

  RTI                 ; return from interrupt
;------------------------------------------------------------------------------------------/

;------------------------------------------------------------------------------------------\
; [8KB PGR-ROM]
  .bank 1
  .org $E000
Palette:
  .db $22,$29,$1A,$0F,$22,$36,$17,$0F,$22,$30,$21,$0F,$22,$27,$17,$0F ; tile palette
  .db $22,$16,$27,$18,$22,$36,$17,$0F,$22,$30,$21,$0F,$22,$27,$17,$0F ; sprite palette

Sprites:
  .db $C0, $32, $00, $40 ; sprite 0 (vertical, tile, settings, horizontal)
  .db $C0, $33, $00, $48 ; sprite 1
  .db $C8, $34, $00, $40 ; sprite 2
  .db $C8, $35, $00, $48 ; sprite 3
  .db $27, $DA, $02, $40 ; A
  .db $27, $DB, $02, $50 ; B
  .db $27, $F8, $02, $60 ; Select
  .db $27, $EC, $02, $70 ; Start
  .db $27, $EE, $02, $80 ; U
  .db $27, $DD, $02, $90 ; D
  .db $27, $E5, $02, $A0 ; L
  .db $27, $EB, $02, $B0 ; R

Tiles:
  .db $24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24 ; $24 (sky)
  .db $24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24
  .db $24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24
  .db $24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24
  .db $24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24
  .db $24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24
  .db $24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24
  .db $24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24
  .db $24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24
  .db $24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24
  .db $24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24
  .db $24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24
  .db $24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24
  .db $24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24
  .db $24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24
  .db $24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24
  .db $24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24
  .db $24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24
  .db $24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24
  .db $24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24
  .db $24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24
  .db $24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24
  .db $24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24
  .db $24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24
  .db $24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24
  .db $24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24
  .db $24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24
  .db $24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24
  .db $24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24
  .db $24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24
  .db $24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24
  .db $24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24
  .db $24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24
  .db $24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24
  .db $24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24
  .db $24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24
  .db $57,$58,$24,$24,$24,$24,$45,$45,$57,$58,$45,$45,$53,$54,$45,$45 ; $45/$47 (brick)
  .db $24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24
  .db $59,$5A,$24,$24,$24,$24,$47,$47,$59,$5A,$47,$47,$55,$56,$47,$47 ; $53-$56 (question)
  .db $24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24 ; $57-$5A (blank block)
  .db $24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24
  .db $24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24
  .db $24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24
  .db $24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24
  .db $24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24 ; $60-$69 (pipe)
  .db $24,$24,$24,$24,$24,$24,$24,$24,$24,$60,$61,$62,$63,$24,$24,$24 ; $26 (dark grass)
  .db $24,$24,$31,$32,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24,$24 ; $31/$32 (top of hill)
  .db $24,$24,$24,$24,$24,$24,$24,$24,$24,$64,$65,$66,$67,$24,$24,$24 ; $30/$33 (hill slopes)
  .db $24,$30,$26,$34,$33,$24,$24,$24,$24,$24,$24,$24,$24,$24,$36,$37 ; $34 (dots)
  .db $24,$24,$24,$24,$24,$24,$24,$24,$24,$68,$69,$25,$6A,$24,$24,$24
  .db $30,$26,$26,$26,$26,$33,$24,$24,$24,$24,$24,$24,$24,$35,$25,$25 ; $35 (bush start)
  .db $38,$24,$24,$24,$24,$24,$24,$24,$24,$68,$69,$25,$6A,$24,$24,$24 ; $38 (bush end)
  .db $B4,$B5,$B4,$B5,$B4,$B5,$B4,$B5,$B4,$B5,$B4,$B5,$B4,$B5,$B4,$B5 ; $B4/$B5 (block tops)
  .db $B4,$B5,$B4,$B5,$B4,$B5,$B4,$B5,$B4,$B5,$B4,$B5,$B4,$B5,$B4,$B5
  .db $B6,$B7,$B6,$B7,$B6,$B7,$B6,$B7,$B6,$B7,$B6,$B7,$B6,$B7,$B6,$B7 ; $B6/$B7 (block bottoms)
  .db $B6,$B7,$B6,$B7,$B6,$B7,$B6,$B7,$B6,$B7,$B6,$B7,$B6,$B7,$B6,$B7
  .db $B4,$B5,$B4,$B5,$B4,$B5,$B4,$B5,$B4,$B5,$B4,$B5,$B4,$B5,$B4,$B5 ; $B4/$B5 (block tops)
  .db $B4,$B5,$B4,$B5,$B4,$B5,$B4,$B5,$B4,$B5,$B4,$B5,$B4,$B5,$B4,$B5
  .db $B6,$B7,$B6,$B7,$B6,$B7,$B6,$B7,$B6,$B7,$B6,$B7,$B6,$B7,$B6,$B7 ; $B6/$B7 (block bottoms)
  .db $B6,$B7,$B6,$B7,$B6,$B7,$B6,$B7,$B6,$B7,$B6,$B7,$B6,$B7,$B6,$B7
  .db %11111111, %11111111, %11111111, %11111111, %11111111, %11111111, %11111111, %11111111
  .db %10101010, %10101010, %10101010, %10101010, %10101010, %10101010, %10101010, %10101010
  .db %11111111, %11111111, %11111111, %11111111, %11111111, %11111111, %11111111, %11111111
  .db %11111111, %11111111, %11111111, %11111111, %11111111, %11111111, %11111111, %11111111
  .db %11111111, %11111111, %11111111, %11111111, %11111111, %11111111, %11111111, %11111111
  .db %00000000, %00000000, %00000000, %00000000, %00000000, %00000000, %00000000, %00000000
  .db %11110000, %11110000, %11110000, %11110000, %11110000, %11110000, %11110000, %11110000
  .db %11111111, %11111111, %11111111, %11111111, %11111111, %11111111, %11111111, %11111111
;------------------------------------------------------------------------------------------/

;------------------------------------------------------------------------------------------\
; [SYSTEM INTERRUPTS]
  .org $FFFA
  .dw VBlankStarted   ; if NMI occurs (once per frame if enabled), goto VBlankStarted
  .dw Reset           ; if system is reset, goto Reset
  .dw 0               ; external interrupt IRQ is not used in this tutorial
;------------------------------------------------------------------------------------------/

;------------------------------------------------------------------------------------------\
; [CHR-ROM]
  .bank 2
  .org $0000
  .incbin "mario-mod.chr" ; include 8KB graphics file from SMB1 (modified to visual letters as sprites)
;------------------------------------------------------------------------------------------/
