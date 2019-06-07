//--------------------------
//**********HEADER**********
//--------------------------


//summary
//A program that allows bicolor frames to be displayed on an 8x8 bicolor led matrix.
//Frames are stored as 8 word (16 byte) segments in the flash memory following the instruction segment.
//The first 16 bytes of the ram contain a frame buffer of which two bytes are written to martix ports.
//A special subroutine is used to read and display sequences of frames from the flash.


//reservations
;RAM 0x0100 - 0x010F:					Frame buffer (Green 0 : Red 0, Green 1 : Red 1... Green 7 : Red 7).
;RAM 0x0110:							Cathode buffer.
;RAM 0x0111:							Display address low.
;RAM 0x0112:							Display address high (Next two bytes to be displayed from the frame buffer).
;r2:									Zero constant.
;r16:									General purpose data register.
;r17:									Auxiliary register.
;r18:									General register c.
;r19:									General register d.
;y pointer:								RAM.
;z pointer:								Flash.
;timer 0:								1 ms display refresh.
;timer 1:								General polling delay.
;port a:								Green anode driver.
;port b:								Sequence control.
;port c:								Red anode driver.
;port d:								Cathode sink (Don't exceed 20 mA).


//include
.nolist
.include "m1284Pdef.inc"
.list
//def
.def zero = r2
.def rdata = r16
.def raux = r17
.def rc = r18
.def rd = r19
//equ
.equ F_CPU			= 1000000	;CPU speed in Hz
.equ RAMSTART		= 0x0100	;start of RAM
.equ DISSTART		= 0x0100	;start of frame buffer
.equ DISEND			= 0x010F	;end of frame buffer
.equ CATBUFFER		= 0x0110	;cathode buffer
.equ DISADDL		= 0x0111	;display address low
.equ DISADDH		= 0x0112	;display address high


//--------------------------------
//**********VECTOR TABLE**********
//--------------------------------


.cseg
.org 0x0000 rjmp reset
.org 0x0020 rjmp displayrefresh ;timer 0 output compare match a


//---------------------------------------
//**********INTERRUPT UTILITIES**********
//---------------------------------------


reset:
//registers
clr zero

//I/O space initialization (stack/timers)
//JTAG
ldi rdata, 0b10000000
out mcucr, rdata
out mcucr, rdata ;disable JTAG interface (it must be set twice within four clock cycles as a safety measure)
//stack
ldi rdata, high(RAMEND)
ldi raux, low(RAMEND)
out sph, rdata
out spl, raux ;initialize stack pointer
//ports
ldi rdata, 0b11111000
out ddrb, rdata ;port b as input
ser rdata
out ddra, rdata ;port a as output
out ddrc, rdata ;port c as output
out ddrd, rdata ;port d as output
ldi rdata, 0b00000111
out portb, rdata ;enable first three internal pull-up resistors
out porta, zero ;clear port a
out portc, zero ;clear port c
out portd, zero ;clear port d
//timer 0
out TCNT0, zero ;clear timer 0
ldi rdata, 0b00000010
ldi yl, low(TIMSK0)
ldi yh, high(TIMSK0)
st y, rdata ;enable timer 0 output compare a interrupt
ldi rdata, 0x7C
out OCR0A, rdata ;set timer 0 compare check a to 1 ms or ((1/(target_freq/(F_CPU/prescaler)))-1)
ldi rdata, 0b00000010
out TCCR0B, rdata ;start timer 0 with prescaler of F_CPU/8 (0b00000010)

//RAM initialization
ldi yl, low(CATBUFFER)
ldi yh, high(CATBUFFER)
ldi rdata, 0b11111110
st y+, rdata ;initialize cathode buffer
ldi rdata, low(DISSTART)
ldi raux, high(DISSTART)
st y+, rdata ;initialize display address low
st y, raux ;initialize display address high

//Main loop branch
sei ;enable global interrupts
rjmp main


//Task:
;Switch which green and red bytes are being sent to the matrix from the frame buffer.
;Update the cathode sink.
//Preconditions:
;None.
//Postconditions:
;If x and x + 1 were the two bytes from the frame buffer written to the output ports,
;then x + 2 and x + 3 will be the new ones.
;The cathode buffer will have been shifted once.
//Memory:
;Global:
;cathode buffer (RAM)
;display address (RAM)
;port a
;port c
;port d
;Local:
;rdata
;raux
;rc
;rd
;y pointer
displayrefresh:
out TCNT0, zero ;reset timer 0
//save states
push rdata
push raux
push rc
push rd
push yl
push yh
in rdata, sreg
push rdata

//start
ldi yh, high(CATBUFFER)
ldi yl, low(CATBUFFER) ;load y pointer with cathode buffer address
ld raux, y+ ;load cathode buffer value
ld rc, y+ ;load display address low
ld rd, y ;load display address high
mov yh, rd
mov yl, rc ;load y pointer with display address value
	;check for address overflow
	ldi rd, high(DISEND + 1)
	ldi rc, low(DISEND + 1) ;load display end address value
	cp rd, yh
	cpc rc, yl ;compare y with rd:rc
	brne displayrefresha ;skip display address value reset if no overflow is present
	ldi yh, high(DISSTART)
	ldi yl, low(DISSTART) ;load y pointer with display start address
	displayrefresha:
ld rc, y+ ;load green byte
ld rd, y+ ;load red byte (note that the y pointer will have the next display address for the next refresh interation)
out porta, zero ;clear port a (green)
out portc, zero ;clear port c (red)
out portd, raux ;update port d with new cathode buffer value
out porta, rc ;update green byte
out portc, rd ;update red byte
sbrs raux, 7
clc
sbrc raux, 7
sec
rol raux ;shift cathode buffer value
mov rc, yl
mov rd, yh ;move y address (new display address value)
ldi yh, high(CATBUFFER)
ldi yl, low(CATBUFFER) ;load y pointer with cathode buffer address
st y+, raux ;store new cathode buffer value
st y+, rc
st y, rd ;store new display address value

//restore states
pop rdata
out sreg, rdata
pop yh
pop yl
pop rd
pop rc
pop raux
pop rdata
reti


//--------------------------------------
//**********IMPORTED LIBRARIES**********
//--------------------------------------


//Blank template.
;.include "Libraries\@.asm"


//--------------------------
//**********MACROS**********
//--------------------------


//Task:
;Extend the newframe subroutine to allow for simpler frame buffer updating.
//Preconditions:
;None.
//Postconditions:
;A flash address pointing to a frame is loaded into the z pointer (ext.), then newframe is called.
//Memory:
;Global:
;z pointer (ext.)
;frame buffer (RAM)
;Local:
;rdata
.macro draw ;@0 = frame address (as a word, not byte)
//save states
push rdata

//start
ldi rdata, byte3(@0 * 2)
out rampz, rdata
ldi zh, byte2(@0 * 2)
ldi zl, byte1(@0 * 2) ;load z with frame address
rcall newframe

//restore states
pop rdata
.endmacro


//Task:
;Extend the delay soubroutine to allow the programmer to delay in miliseconds.
//Preconditions:
;None.
//Postconditions:
;OCR1A is loaded with a cycle count corresponding to the milisecond parameter, then delay is called.
//Memory:
;Global:
;timer 1
;Local:
;rdata
;y pointer
.macro pause ;@0 = pause time in ms
;max pause = 67,108.864 ms
;min pause = unknown
//save states
push rdata
push yl
push yh

//start
ldi rdata, high((@0/1.024)-1)
ldi yh, high(OCR1AH)
ldi yl, low(OCR1AH)
st y, rdata
ldi rdata, low((@0/1.024)-1)
st -y, rdata  ;set compare registers
rcall delay

//restore states
pop yh
pop yl
pop rdata
.endmacro


//Task:
;Extend the sequence subroutine to allow simpler sequence accessing.
//Preconditions:
;None.
//Postconditions:
;A flash address pointing to a sequence is loaded into the z pointer (ext.), then sequence is called.
//Memory:
;Global:
;z pointer (ext.)
;timer 1
;Local:
;rdata
.macro display ;@0 = frame address (as a word, not byte)
//save states
push rdata

//start
ldi rdata, byte3(@0 * 2)
out rampz, rdata
ldi zh, byte2(@0 * 2)
ldi zl, byte1(@0 * 2) ;load z with frame address
rcall sequence

//restore states
pop rdata
.endmacro


//-------------------------------
//**********SUBROUTINES**********
//-------------------------------


//Task:
;Load a new frame into the frame buffer.
//Preconditions:
;z pointer (ext.) must be loaded with the desired frame flash address multiplied by two.
//Postconditions:
;The frame buffer is updated with a new frame from the flash.
//Memory:
;Global:
;frame buffer (RAM)
;Local:
;rdata
;raux
;y pointer
;z pointer (ext.)
newframe:
//save states
push rdata
push raux
push yl
push yh
push zl
push zh
in rdata, rampz
push rdata

//start
ldi yh, high(DISSTART)
ldi yl, low(DISSTART) ;load y pointer with display start address
	ldi raux, 0x10 ;initialize raux as main counter
	newframea:
	elpm rdata, z+ ;read byte to rdata from z as pointer
	st y+, rdata ;store byte from rdata to y address
	dec raux
	brne newframea ;loop through again if not all bytes have been updated

//restore states
pop rdata
out rampz, rdata
pop zh
pop zl
pop yh
pop yl
pop raux
pop rdata
ret


//Task:
;Pause program execution by polling for timer 1 output compare A.
//Preconditions:
;OCR1A must be loaded with desired cycle count.
//Postconditions:
;Program executions is paused for OCR1A's cycle counts.
//Memory:
;Global:
;timer 1
;Local:
;rdata
;y pointer
delay:
//save states
push rdata
push yl
push yh

//start
ldi yh, high(TCNT1H)
ldi yl, low(TCNT1H)
st y, zero
ldi yh, high(TCNT1L)
ldi yl, low(TCNT1L)
st y, zero ;clear timer
ldi rdata, 0b00000101
ldi yh, high(TCCR1B)
ldi yl, low(TCCR1B)
st y, rdata ;set prescaler to F_CPU/1024
	delaya: ;poll for compare flag
	sbis TIFR1, 1
	rjmp delaya
st y, zero  ;stop timer
sbi TIFR1, 1 ;clear compare flag

//restore states
pop yh
pop yl
pop rdata
ret


//Task:
;Display a sequence from the flash memory
//Preconditions:
;The z pointer must be loaded with the start address of a sequence.
//Postconditions:
;A sequence is displayed
//Memory:
;Global:
;timer 1
;frame buffer (RAM)
;Local:
;rdata
;raux
;rc
;rd
;y pointer
;z pointer (ext.)
sequence:
//save states
push rdata
push raux
push rc
push rd
push yl
push yh
push zl
push zh
in rdata, rampz
push rdata

//start
ldi yh, high(OCR1AH)
ldi yl, low(OCR1AH)
elpm rdata, z+
elpm raux, z+ ;load raux:rdata with delay cycle count
st y, raux
st -y, rdata  ;set timer 1 output compare a registers for delay cycle count
	elpm rc, z+
	elpm rd, z+ ;initialize rd:rc as counter
	sequencea:
	elpm rdata, z+
	elpm raux, z+ ;load raux:rdata with frame address wordwise
	push zl
	push zh ;save the address pointing to the next frame address to the stack
	mov zl, rdata
	mov zh, raux ;move raux:rdata (frame address wordwise) to z
	clr rdata
	clc
	rol zl
	rol zh
	rol rdata
	out rampz, rdata ;multiply z by two to achieve bytewise addressing
	rcall newframe ;load next frame into the frame buffer
	rcall delay ;delay based on value entered into OCR1A
	pop zh
	pop zl ;restore current frame address from the stack
	subi rc, 0x01
	sbc rd, zero
	brne sequencea ;reiterate if rd:rc is not zero

//restore states
pop rdata
out rampz, rdata
pop zh
pop zl
pop yh
pop yl
pop rd
pop rc
pop raux
pop rdata
ret


//-------------------------------------
//**********MAIN PROGRAM LOOP**********
//-------------------------------------


main:

//==========Sequence Controller==========

//This reads the value on three external switches to determine which sequence to display.

//External sequence control check.
in rdata, pinb ;get external sequence control state
com rdata ;invert the infromation because the control switches sink current
andi rdata, 0b00000111 ;preserve the lower 3 bits, set upper 5 to 0
cpi rdata, 0x00
breq main0 ;check if sequence control equals 0
cpi rdata, 0x01
breq main1 ;check if sequence control equals 1
cpi rdata, 0x02
breq main2 ;check if sequence control equals 2
cpi rdata, 0x03
breq main3 ;check if sequence control equals 3
cpi rdata, 0x04
breq main4 ;check if sequence control equals 4
cpi rdata, 0x05
breq main5 ;check if sequence control equals 5
cpi rdata, 0x06
breq main6 ;check if sequence control equals 6
rjmp main7 ;if all other conditions failed, then the control must be 7

//Call table.
main0:
display sequence0 ;display sequence 0
rjmp main
main1:
display sequence1 ;display sequence 1
rjmp main
main2:
display sequence2 ;display sequence 2
rjmp main
main3:
display sequence3 ;display sequence 3
rjmp main
main4:
display sequence4 ;display sequence 4
rjmp main
main5:
display sequence5 ;display sequence 5
rjmp main
main6:
display sequence6 ;display sequence 6
rjmp main
main7:
display sequence7 ;display sequence 7
rjmp main


//--------------------------
//**********TABLES**********
//--------------------------


//Load stand-alone frames table.

.include "StandAloneFrames.asm"


//Load sequences table.

.include "Sequences.asm"

