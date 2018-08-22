
.segment "STARTUP"
.segment "INIT"
.segment "ONCE"

	; This program now can handle single digit
	; basic math operations.

	; TODO: multi-digit input, multi-byte operations.

	; TODO: Needs a routine that can handle outputing
	;	any string that is passed to it.
	;	This will require a strlen routine.

	; TODO:	Read assembler documentation about finding
	;	the address of certain labels so that they
	;	can be accessed via. any required
	;	addressing modes. 

	; GPL 3.0
	; Copyright (c) 2018 ElliePenguins

.segment "CODE"

	; BASIC routines.
	GETIN = $ffe4
	PUTCHAR = $ffd2
	STOP = $ffe1

	; VARiables.
	input = $033c 
	input2 = $033d

	; Answer to be returned to user
	; will be stored in these bytes.
	value = $0340
	value2 = $0341
	value3 = $0342
	value4 = $0343

	selection = $0350

	; Used for math and multibyte operations. 
	
	; The number of shifts, not the number of rotates.
	numberOfShifts = $0355
	multiplicationAddRequired = $0356
	divisionSubtractRequred = $0357

		; Note: The above could exist in one addr.

	; Parameters

	par1 = $0345
	par2 = $0346
	par3 = $0347

	stringAddress = $0348	

	; Control	
	startStop = $033e
	opFail = $0458


main:
	lda #0
	ldx #0
	ldy #0

	jsr init 

	@mainLoop:

	jsr clear
	jsr menu	
	jsr wait
	jsr clear

	; build this into a load function subroutine.
	lda selection

	cmp #$33
	beq @add
	cmp #$32
	beq @multi
	cmp #$34
	beq @sub
	cmp #$31
	beq @div

	@add:
	bne @fwdjmp 		; Check stop key.
	jsr addNumbers 
	jsr displayCalculated 
	jsr waitKey		; This could be placed inside displayCalc:
	jmp @fwdjmp		; Required to bypass other options.

	@sub:
	bne @fwdjmp		; Check Stop Key.
	jsr subtractNumbers

	ldx opFail		; make determine weather to print.
	cpx #$1
	beq @wrongInput		; TODO: need more elegent solution.
	jsr displayCalculated
	jsr waitKey
	jmp @fwdjmp

	@multi:
	bne @fwdjmp		; Check stop key. 
	jsr multiplyNumbers
	jsr displayCalculated
	jsr waitKey		; This could be placed inside displayCalc:
	jmp @fwdjmp

	; TODO: Check the user input numbers, set opFail if required.
	@div:
	bne @fwdjmp		; Check start/stop
	jsr divideNumbers
	ldx opFail
	cpx #$1	
	beq @wrongInput
	jsr displayCalculated
	jsr waitKey
	jmp @fwdjmp
	
	@wrongInput:
	ldx #$0

	jsr newline
	@loop:
	lda wrong,x
	jsr PUTCHAR	
	inx
	cmp #$00 
	bne @loop
	jsr waitKey
	jmp @fwdjmp
	
	jsr waitKey
	ldx #$0
	stx opFail

	@fwdjmp:

	; This allows any function to jsr stopCheck and it will exit.
	jsr stopCheck
	lda startStop
	cmp #$1			; TODO: Define constants. 
	beq @end

	jmp @mainLoop

	@end:
	rts	; Return to Basic"

init:
	lda #$0
	sta input
	sta opFail	; init

	; Change the background color black.
	sta $d020
	sta $d021

	lda #$93	; Clear Screen.
	jsr PUTCHAR

	lda #$0

	rts

newline:
	php
	lda #$0d
	jsr PUTCHAR 
	plp
	rts

clear:
	php
	pha
	lda #$93
	jsr PUTCHAR
	pla
	plp
	rts

wait:
	php
	pha
	ldx #$0
	ldy #$0
	
	@loop:
	inx
	cpx #$FF
	bne @loop
	iny
	cpy #$FF
	bne @loop

	pla
	plp
	rts
	
spacer: 

	php

	ldx #0			

	@loop:
	jsr newline
	inx
	cpx #$10	; Define a constant for this. 
	bne @loop
			
	plp	 
	rts

stopCheck:

	php

	lda #$0		; not Pressed.

	jsr STOP
	bne @end	; Jmp forward.
	
	lda #$1		; Pressed.	

	@end:
	sta startStop
	plp
	rts

prompt:

	php
	ldx #$0

	@loop:
	lda msg,x
	jsr PUTCHAR 
	inx
	cpx #$10		; Note TODO: strlen
	bne @loop

	plp
	rts

; TODO create a string out Routine, load the address of str and print.
banner:
	php
	ldx #$0

	@loop:
	lda Banner,x
	jsr PUTCHAR 
	inx
	cpx #26		; Note TODO: strlen
	bne @loop

	jsr newline

	plp
	rts

menu:
	php		; Save multiple states on the stack.
	pha	

	jsr banner
	jsr operations
	jsr getNumber

	; Transfer the number into label selection.
	jsr convertNumber	; Selection needs to be a digit.
	lda input
	sta selection

	jsr convertNumber	; Convert the number for display.
	jsr displayNumber
	jsr newline
	; Transfer input to selection.
	lda input
	sta selection 

	jsr newline 

	pla		; Restore
	plp

	rts		; Return

	; This routine only displays the names of the possible operations.
	; Attempting to define the strings locally.
operations:

	php

	; Here is the table that will decide which character to
	; load into the regester to be printed, it is indexed by
	; the X regisiter.
	; The x register isent actually counted. All it does is index
	; the entry of the string to the character that is supposed to
	; actually be loaded.
	; NOTE!!! this requires that A is actively checked for NULL.

	ldy #$0		; Which string to actually print.
	ldx #$0		; Character in string via. offset.
	lda #$0

	; this uses a bit of processing power but saves zeroPage.

	@localLoop:
	cpy #$0
	beq @loadDiv
	cpy #$1
	beq @loadMulti 
	cpy #$2
	beq @loadAdd
	cpy #$3
	beq @loadSub
	cpy #4
	beq @selection

	@print:
	inx		; Next Character.
	cmp #$00
	bne @fwdjmp
	ldx #$0
	iny		; Print Next String
	cpy #$5		; Exit if Y hits its limit.
	beq @exit

	@fwdjmp:
	jsr PUTCHAR
	jmp @localLoop

	@loadDiv:
	lda div,x	
	jmp @print

	@loadMulti:
	lda multi,x
	jmp @print	

	@loadAdd:
	lda add,x
	jmp @print	
	
	@loadSub:
	lda sub,x
	jmp @print

	@selection:
	lda select,x
	jmp @print

	@exit:

	plp
	rts
	
getNumber:
	php 			; save state.

	@loop:

	jsr stopCheck
	lda startStop
	cmp #$1			; TODO: Define constants. 
	beq @end

	jsr GETIN		; Use BASIC to get value.
	cmp #$30		; ASCII 0
	bcc @loop		; Less
	cmp #$3A		; ASCII 9
	bcs @loop		; Greater

	sta input	 	; store correct input
	

	@end:
	plp			; Restore
	rts			; Return.

; Does not save state!
getNumberUnprotected:
	
	@loop:
	jsr GETIN		; Use BASIC to get value.

	cmp #$30		; ASCII 0
	bcc @loop		; Less
	cmp #$3A		; ASCII 9
	bcs @loop		; Greater

	rts

getNumbers:
	php
	pha

	jsr prompt
	jsr getNumber
	lda input
	jsr PUTCHAR
	jsr convertNumber	; to digit
	lda input
	sta input2

	jsr newline
	jsr prompt
	jsr getNumber
	lda input
	jsr PUTCHAR
	jsr convertNumber	; to digit

	pla
	plp

	rts

waitKey:

	php
	pha

	lda #$0

	@loop:
	jsr GETIN
	cmp #$0
	beq @loop	; Branch until changed.

	pla
	plp

	rts

convertNumber:
	php

	; XOR by 0x30, changes from ascii
	; to the value and back saving
	; in labeled address input.
	
	lda input
	eor #$30	
	sta input

	plp
	rts

displayNumber:
	php
	
	lda input
	jsr PUTCHAR  
	
	plp	; restore
	rts	; Return

displayCalculated:

	php

	ldx #$0

	jsr newline

	@loop:
	lda answer,x
	jsr PUTCHAR 
	inx
	cpx #$9			; TODO: fix with strlen.
	bne @loop
	
	lda value
	jsr PUTCHAR
	
	
	plp
	rts
	
;	-	-	-	-	-	-	;
; 	|	DATA MANIUPULATION ROUTINES.	|	;
;	-	-	-	-	-	-	;

addNumbers:

	; As this function is written it relies hevily on
	; the input label address, it has to store the
	; values there for the converNumber to convert
	; for manipulation and display.
	; TODO: fix this to work more in immediate mode.

	php
	
	; prompt the user for input and get the first number.
	
	jsr prompt
	jsr getNumber
	jsr PUTCHAR
	jsr newline
	

	; prompt the user for input and get the first number.
	jsr convertNumber
	lda input
	sta input2

	jsr prompt
	jsr getNumber
	jsr PUTCHAR
	jsr newline

	; The actual calculation.
	
	jsr convertNumber
	
	lda input2
	clc
	adc input
	sta input 

	jsr convertNumber
	lda input
	sta value		; TODO: multibyte.

	plp
	rts

subtractNumbers:

	php
	pha

	jsr getNumbers

	; Check the second digit is smaller
	; then first, unsigned only.
	lda input2
	cmp input
	bcc @wrongInput	

	; Actual subtraction takes place here.

	lda input2
	
	sec		; set Carry flag.
	sbc input	; subtract	
	sta input

	; TODO: change address convertNumber works on.
	jsr convertNumber	; To ascii
	lda input
	sta value
	jmp @end
	
	lda #$0

	@wrongInput:
	ldx #$1 
	stx opFail
	ldx #$0
	
	@end:

	pla
	plp

	rts

divideNumbers:

	php
	pha

	; TODO: Set up some kind of remainder display.

	; Here is that block of 
	; GETIN again, please turn it
	; into its own subroutine. 

	jsr getNumbers

	; Check if digits are in right order.
	lda input2
	cmp input
	bcc @inputFail	
	beq @divBySelf		; divide by itself.

	lda input
	cmp #$1
	beq @divByOne
	
	jsr dividePreSet

	ldy numberOfShifts
	lda input2		; Again, op on input2
	@loop:
	
	lsr		; TODO: Multibyte ror
	dey

	cpy #$0
	bne @loop
	
	ldx divisionSubtractRequred
	cpx #$0
	beq @end	; not req, jump past.	
	
	; Division by an odd digit.
	sec
	sbc #$1

	; Convert number for display and put
	; answer in correct address for display routine.
	@end:
	sta input
	jsr convertNumber
	lda input
	sta value	
	jmp @fwdjmp1
	
	@inputFail:
	ldx #$1
	stx opFail	; input issues.	
	ldx #$0
	
	@divByOne:
	lda input2
	sta input
	jsr convertNumber
	lda input
	sta value
	jmp @fwdjmp1

	@divBySelf:
	lda #1
	sta input
	jsr convertNumber
	lda input
	sta value

	@fwdjmp1:
	
	pla
	plp

	rts

dividePreSet:

	php
	pha

	; This routine is similar to mulitplyPreSet
	; in that it is used to determine the number
	; of shifts, rotates and adds/subtracts that
	; are required to accomplish the task in
	; the divideNumbers subRoutine. ( reversed )  

	; Unlike multiplicationPreSet, this will use A 


	lda input
	cmp #$1 	; divide by 1, dont subtract.
	beq @fwdjmp
	lsr 
	bcc @fwdjmp
	pha
	lda #$1
	sta divisionSubtractRequred 	
	pla
	@fwdjmp:

	;--------;
	;  INIT	 ;
	;--------;
	lda input
	ldy #$0

	cmp #$2
	bcc @end 
	iny 

	cmp #$4
	bcc @end 
	iny

	cmp #$6
	bcc @end 
	iny	
	
	cmp #$8
	bcc @end 
	iny

	@end:

	sty numberOfShifts

	pla
	plp

	rts

multiplyNumbers:

	php
	pha

	jsr getNumbers

	; TODO: The above code to get numbers from the user
	;	is replicated many times and is complex
	;	consider building it into its own subroutine.

	ldx input2
	
	; check the last bit for parity to determine
	; if the number is even or odd.

	jsr multiplicationPreSet

	ldx numberOfShifts

	lda input2		; NOTE: operates on input2
	jsr PUTCHAR
	
	@loop:
	asl			; TODO: setup multibyte rotate.
	dex			
	cpx #$0			
	bne @loop		; Once complete,
				; TODO: make convertNumber work
				; 	on a different address.

	ldx multiplicationAddRequired 
	cpx #$1
	bne @fwdJmp		; Is not an odd number.

	clc
	adc input2
	
	@fwdJmp:
	
	sta input		; Put it in input for
	jsr convertNumber	; convert number to use.
	lda input
	sta value		; transfer to value for display	
	
	pla
	plp

	rts

multiplicationPreSet:

	php
	pha

	; This routine determines the number of shifts and
	; rotates that are required for the multiplication
	; of the two input values.

	; Get the input values from label: input and input2
		
	; Start with an lsr and check for an overflow.	

	ldx #$0		; Will be used to init addRequired
			; which can be overwritten if req.

	stx multiplicationAddRequired 

	lda input
	lsr			; Note this messes up A
	bcc @noAddRequired	; jmp over setting the value.

	ldx #$1			; if not jmpd then addr set 0x1
	stx multiplicationAddRequired 

	@noAddRequired:		; Essentially just a fwd-jmp.
		
	ldx input
	ldy #$0

	cpx #$2		; Less then 2, no shifts
	bcc @end
	iny		; +1 number of shifts
	cpx #$4		
	bcc @end
	iny		; +1
	cpx #$6
	bcc @end
	iny		; +1
	cpx #$8
	bcc @end
	iny		; +1

	; Y now contains the required number of shifts,
	; store it in the labeled address and allow the
	; multiplication rountine pair it with addRequired.

	@end:
	sty numberOfShifts	

	pla
	plp

	rts

;	-	-	-	-	-	-	;
;		Commented out, Temp unused Code. 	;
;	-	-	-	-	-	-	;

;displayString:
	; load the address of the string in a before calling.
	; 16 bit address is not able to be passed this way, try again.

	; After Some searching I was able to find indirect indexed
	; addressing that requires the use of zeroPage. do this later.

	;php

	;@loop:
	;jsr PUTCHAR
	; INCrease memory address.
	;cmp #$00
	;bne @loop	
	
	;plp
	;rts

.segment "DATA" 

	msg: .byte "enter a number: ", $0d, $00
	Banner: .byte "commodore 64 calculator:", $0d, $00
	answer: .byte "answer: ", $00
	wrong: .byte "wrong input, try again.",$0d, $00

	div:	.byte "1 - division", $0d, $00
	multi: .byte "2 - multiplication", $0d, $00
	add:	.byte "3 - addition", $0d, $00
	sub:	.byte "4 - subtraction", $0d, $00
	select:	.byte $0d,"enter selection: ", $00
