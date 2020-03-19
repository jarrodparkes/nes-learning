  .inesprg 1   ; 1x 16KB PRG code
  .ineschr 1   ; 1x  8KB CHR data
  .inesmap 0   ; mapper 0 = NROM, no bank swapping
  .inesmir 1   ; background mirroring

;;;;;;;;;;;;;;;

  .bank 0
  .org $C000
RESET:
  SEI          ; disable IRQs
  CLD          ; disable decimal mode
  LDX #$40
  STX $4017    ; disable APU frame IRQ
  LDX #$FF
  TXS          ; Set up stack
  INX          ; now X = 0
  STX $2000    ; disable NMI
  STX $2001    ; disable rendering
  STX $4010    ; disable DMC IRQs

vblankwait1:       ; First wait for vblank to make sure PPU is ready
  BIT $2002
  BPL vblankwait1

clrmem:
  LDA #$00
  STA $0000, x
  STA $0100, x
  STA $0300, x
  STA $0400, x
  STA $0500, x
  STA $0600, x
  STA $0700, x
  LDA #$FE
  STA $0200, x    ;move all sprites off screen
  INX
  BNE clrmem

vblankwait2:      ; Second wait for vblank, PPU is ready after this
  BIT $2002
  BPL vblankwait2

LoadPalettes:
  LDA $2002    ; read PPU status to reset the high/low latch
  LDA #$3F
  STA $2006    ; write the high byte of $3F00 address
  LDA #$00
  STA $2006    ; write the low byte of $3F00 address
  LDX #$00
LoadPalettesLoop:
  LDA palette, x        ;load palette byte
  STA $2007             ;write to PPU
  INX                   ;set index to next byte
  CPX #$20
  BNE LoadPalettesLoop  ;if x = $20, 32 bytes copied, all done

LoadMario:
  ; row-1-left
  LDA #$80
  STA $0200        ; put sprite 0 in center ($80) of screen vert
  STA $0203        ; put sprite 0 in center ($80) of screen horiz
  LDA #$00
  STA $0201        ; tile number = 0
  STA $0202        ; color = 0, no flipping

  ; row-1-right
  LDA #$80
  STA $0204
  LDA #$88
  STA $0207
  LDA #$01
  STA $0205        ; tile number = 1
  LDA #$00
  STA $0206        ; color = 0, no flipping

  ; row-2-left
  LDA #$88
  STA $0208
  LDA #$80
  STA $020B
  LDA #$02
  STA $0209        ; tile number = 2
  LDA #$00
  STA $020A        ; color = 0, no flipping

  ; row-2-right
  LDA #$88
  STA $020C
  LDA #$88
  STA $020F
  LDA #$03
  STA $020D        ; tile number = 3
  LDA #$00
  STA $020E        ; color = 0, no flipping

  ; row-3-left
  LDA #$90
  STA $0210
  LDA #$80
  STA $0213
  LDA #$04
  STA $0211        ; tile number = 4
  LDA #$00
  STA $0212        ; color = 0, no flipping

  ; row-3-right
  LDA #$90
  STA $0214
  LDA #$88
  STA $0217
  LDA #$05
  STA $0215        ; tile number = 5
  LDA #$00
  STA $0216        ; color = 0, no flipping

  ; row-4-left
  LDA #$98
  STA $0218
  LDA #$80
  STA $021B
  LDA #$06
  STA $0219        ; tile number = 6
  LDA #$00
  STA $021A        ; color = 0, no flipping

  ; row-4-right
  LDA #$98
  STA $021C
  LDA #$88
  STA $021F
  LDA #$07
  STA $021D        ; tile number = 7
  LDA #$00
  STA $021E        ; color = 0, no flipping

  LDA #%10000000   ; enable NMI, sprites from Pattern Table 0
  STA $2000

  LDA #%00010000   ; enable sprites
  STA $2001

Forever:
  JMP Forever     ;jump back to Forever, infinite loop

NMI:
  LDA #$00
  STA $2003  ; set the low byte (00) of the RAM address
  LDA #$02
  STA $4014  ; set the high byte (02) of the RAM address, start the transfer

  RTI        ; return from interrupt

;;;;;;;;;;;;;;

  .bank 1
  .org $E000
palette:
  .db $0F,$31,$32,$33,$0F,$35,$36,$37,$0F,$39,$3A,$3B,$0F,$3D,$3E,$0F
  .db $0F,$17,$30,$0C,$0F,$02,$38,$3C,$0F,$1C,$15,$14,$0F,$02,$38,$3C


  .org $FFFA     ;first of the three vectors starts here
  .dw NMI        ;when an NMI happens (once per frame if enabled) the
                   ;processor will jump to the label NMI:
  .dw RESET      ;when the processor first turns on or is reset, it will jump
                   ;to the label RESET:
  .dw 0          ;external interrupt IRQ is not used in this tutorial

;;;;;;;;;;;;;;

  .bank 2
  .org $0000
  .incbin "mario.chr"   ;includes 8KB graphics file from SMB1
