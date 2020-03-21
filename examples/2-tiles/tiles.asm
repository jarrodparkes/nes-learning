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
  STA $0000, x        ; zero out value at this address
  STA $0100, x        ; zero out value at this address
  STA $0300, x        ; zero out value at this address
  STA $0400, x        ; zero out value at this address
  STA $0500, x        ; zero out value at this address
  STA $0600, x        ; zero out value at this address
  STA $0700, x        ; zero out value at this address
  LDA #$FE
  STA $0200, x        ; move sprite off screen
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
  LDA Palette, x      ; load palette byte
  STA PPU_DATA        ; write to PPU
  INX                 ; set index to next byte
  CPX #$20            ; check if X == $20 (32)
  BNE LoadPalette     ; keep looping until all 32 bytes are copied

LoadMarioStanding:    ; draw mario standing L-to-R, T-to-B
  LDA #$40            ; sprite 1
  STA $0200           ; set vertical position
  LDA #$60
  STA $0203           ; set horizontal position
  LDA #$00
  STA $0201           ; set tile
  STA $0202           ; set color w/ no flipping

  LDA #$40            ; sprite 2
  STA $0204
  LDA #$68
  STA $0207
  LDA #$01
  STA $0205
  LDA #$00
  STA $0206

  LDA #$48            ; sprite 3
  STA $0208
  LDA #$60
  STA $020B
  LDA #$02
  STA $0209
  LDA #$00
  STA $020A

  LDA #$48            ; sprite 4
  STA $020C
  LDA #$68
  STA $020F
  LDA #$03
  STA $020D
  LDA #$00
  STA $020E

  LDA #$50            ; sprite 5
  STA $0210
  LDA #$60
  STA $0213
  LDA #$04
  STA $0211
  LDA #$00
  STA $0212

  LDA #$50            ; sprite 6
  STA $0214
  LDA #$68
  STA $0217
  LDA #$05
  STA $0215
  LDA #$00
  STA $0216

  LDA #$58            ; sprite 7
  STA $0218
  LDA #$60
  STA $021B
  LDA #$06
  STA $0219
  LDA #$00
  STA $021A

  LDA #$58            ; sprite 8
  STA $021C
  LDA #$68
  STA $021F
  LDA #$07
  STA $021D
  LDA #$00
  STA $021E

LoadMarioRunning:     ; draw mario running L-to-R, T-to-B
  LDA #$40            ; sprite 9
  STA $0220
  LDA #$80
  STA $0223
  LDA #$08
  STA $0221
  LDA #$00
  STA $0222

  LDA #$40            ; sprite 10
  STA $0224
  LDA #$88
  STA $0227
  LDA #$09
  STA $0225
  LDA #$00
  STA $0226

  LDA #$48            ; sprite 11
  STA $0228
  LDA #$80
  STA $022B
  LDA #$0A
  STA $0229
  LDA #$00
  STA $022A

  LDA #$48            ; sprite 12
  STA $022C
  LDA #$88
  STA $022F
  LDA #$0B
  STA $022D
  LDA #$00
  STA $022E

  LDA #$50            ; sprite 13
  STA $0230
  LDA #$80
  STA $0233
  LDA #$0C
  STA $0231
  LDA #$00
  STA $0232

  LDA #$50            ; sprite 14
  STA $0234
  LDA #$88
  STA $0237
  LDA #$0D
  STA $0235
  LDA #$00
  STA $0236

  LDA #$58            ; sprite 15
  STA $0238
  LDA #$80
  STA $023B
  LDA #$0E
  STA $0239
  LDA #$00
  STA $023A

  LDA #$58            ; sprite 16
  STA $023C
  LDA #$88
  STA $023F
  LDA #$0F
  STA $023D
  LDA #$00
  STA $023E

FinishSprites:
  LDA #%10000000      ; enable NMI/VBLANK
  STA PPU_CTRL

  LDA #%00010000      ; enable sprites
  STA PPU_MASK

Forever:
  JMP Forever         ; loop forever
;------------------------------------------------------------------------------------------/

;------------------------------------------------------------------------------------------\
; [HELPERS]
VBlankDetected:
  LDA #$00
  STA PPU_OAM_ADDR    ; write the low byte of $0200 address
  LDA #$02
  STA PPU_OAM_DMA     ; write the low byte of $0200 address, this starts DMA transfer
  RTI                 ; return from interrupt
;------------------------------------------------------------------------------------------/

;------------------------------------------------------------------------------------------\
; [8KB PGR-ROM]
  .bank 1
  .org $E000
Palette:
  .db $22,$16,$38,$18,$22,$16,$38,$18,$22,$16,$38,$18,$22,$16,$38,$18 ; tile palette
  .db $22,$16,$38,$18,$22,$16,$38,$18,$22,$16,$38,$18,$22,$16,$38,$18 ; sprite palette
;------------------------------------------------------------------------------------------/

;------------------------------------------------------------------------------------------\
; [SYSTEM INTERRUPTS]
  .org $FFFA
  .dw VBlankDetected  ; if NMI occurs (once per frame if enabled), goto VBlankDetected
  .dw Reset           ; if system is reset, goto Reset
  .dw 0               ; external interrupt IRQ is not used in this tutorial
;------------------------------------------------------------------------------------------/

;------------------------------------------------------------------------------------------\
; [CHR-ROM]
  .bank 2
  .org $0000
  .incbin "mario.chr" ; include 8KB graphics file from SMB1
;------------------------------------------------------------------------------------------/
