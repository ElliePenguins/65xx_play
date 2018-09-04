
.segment "STARTUP"
.segment "INIT"
.segment "ONCE"

	; Date:	September 3 2018

	; This simple program creates a border around the 
	; screen and then creates a simple "ball" that
	; bounces from side to side. It is not interactive
	; for the moment, but this can be added eventually.

	; Note that this program writes to the screen by
	; putting the values in screen memory instead of
	; jsr to a basic putchar type subroutine. 
	; This makes it able to move quite fast.

	; TODO: move the animate routine to work inside
	;	of main so that other options can be
	;	multiplexed with the animation to allow
	;	this program to become interactive.

	;	Next:	Create function that checks
	;		to see if start/stop is being
	;		pressed, allowing the program
	;		to return to BASIC upon request.

	; GPL 3.0
	; Copyright (c) 2018 ElliePenguins


	topLeft = $0400
	topRight = $0427
	bottomLeft = $07c0 
	bottomRight = $07e7

	upperMiddleLeft = $04c8
	middleLeft = $0590
	lowerMiddleLeft = $0658
	
	saveStateX = $033c
	saveStateY = $033c

	character = $0350
	characterClear = $0351

	; Position is an offset used for printing the ball.

	position = $0355	

	; Note: Lower position is an added 0x28 to
	;	the value and add one for next.


main:
	lda #0
	ldx #0
	ldy #0

	pha

	lda #$93		; PETSCII newline 
	jsr $ffd2

	; TODO: Debug why certain ascii chars throw off animation.

	lda #$51		; PETSCII "circles"
	sta character
	jsr printBorder 
	
	jsr animate
	
	pla

	lda #$0
	jsr waitKey

	rts			; Return to Basic"

animate:

	php
	pha

	; Set position, call printBall, eraseBall and repeat.	

	lda #$0
	ldx #$0
	ldy #$0

	; All animation is done here. although might be
	; a better idea to use main for now, to make
	; multiplexing with the movement easier. 


	@loop:

	inx
	stx position	

	jsr printBall

	iny

	lda character
	ldx #$20		; space to overwrite.
	stx character

	jsr wait
	
	jsr printBall
	sta character		; Put original back

	cpy #$25		; full, then go back.
	bne @loop

	; same Thing as above, but decrease X instead.
	; This makes the "ball" go backwards.

	@loopRev:

	dex	
	stx position	

	jsr printBall

	dey

	lda character
	ldx #$20		; space to overwrite.
	stx character

	jsr wait
	
	jsr printBall
	sta character		; Put original back

	cpy #1			; full, then go back.
	bne @loopRev

	jmp @loop		; infinite Loop.
				; TODO: add check for Stop/Start

	pla
	plp

	rts

printBall:

	php
	pha

	stx saveStateX
	sty saveStateY

	lda character
	ldx position

	; TODO: use y for like, verticle-ness.	
	
	sta middleLeft,x
	inx
	sta middleLeft,x	; One character next to it.
	
	txa
	clc
	adc #$27		; Next line.
	tax

	lda character

	sta middleLeft,x
	inx
	sta middleLeft,x
				; Should produce a 4
				; charactered square.
	txa
	sec
	sbc #$27
	tax
	
	ldx saveStateX
	ldy saveStateY

	pla
	plp
	
	rts

printBorder:

	php
	pha

	jsr borderTop
	jsr borderSides 

	plp
	pla

	rts

borderTop:

	php
	pha

	; Print top / Bottom.

	lda character

	@loop:
	
	sta topLeft,x	
	sta bottomLeft,x
	inx
	
	cpx #$28	; One Past.
	bne @loop
	pla
	plp

	rts

borderSides:

	php
	pha

	ldx #$0
	ldy #$0
	lda #$0

	lda character
	inx

	sta character
	txa
	adc #$27
	tax

	lda character
	sta topLeft,x 

	@loop2:

	sta topLeft,x
	sta upperMiddleLeft,x
	sta middleLeft,x
	sta lowerMiddleLeft,x
	sta $06d0,x			; Note this puts 5 chars, however
					; it also overwrites 2, showing 3
					; This is from an error that when
					; corrected should make this uneeded.
	
	txa
	adc #$27 
	tax

	lda character
	sta topLeft,x
	sta upperMiddleLeft,x
	sta middleLeft,x
	sta lowerMiddleLeft,x
	sta $0720,x			; Same Story, the previous 3 are
					; off by 1. fix this.

	inx
	iny

	cpy #$5
	bne @loop2

	pla
	plp

	rts


borderSide2:

	php
	pha

	ldx #$0
	ldy #$0
	lda #$0

	lda #$30

	sta character
	txa
	adc #$27
	tax

	lda character
	sta topLeft,x 

	@loop2:

	sta topLeft,x
	
	txa
	adc #$27 
	tax

	lda character
	sta topLeft,x

	inx
	iny

	cpy #$5
	bne @loop2

	pla
	plp

	rts

waitKey:

	php
	pha

	lda #$0
	@loop:
	
	jsr $ffe4
	
	cmp #$0
	beq @loop

	pla
	plp
	
	rts

wait:

	php
	pha

	stx saveStateX
	sty saveStateY
	ldx #$0
	ldy #$0

	@loop:
	inx
	cpx #$ff
	bne @loop
	ldx #$0
	iny
	cpy #$22
	bne @loop
	
	ldx saveStateX
	ldy saveStateY

	pla
	plp

	rts

printCorners:

	php
	pha
	
	lda #$41

	sta topLeft
	sta topRight
	sta bottomLeft
	sta bottomRight

	pla
	plp

	rts
