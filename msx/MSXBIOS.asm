; ------------------------------------------------------------------------------
; BBX80 MSX HOST v1.0
; Copyright (C) 2024 H.J. Berends
;
; ver2.0 for MSX2 mcheine
; Copyright (C) 2027 MZ80K-USER-OLD
;
; You can freely use, distribute or modify this program.
; It is provided freely and "as it is" in the hope that it will be useful, 
; but without any warranty of any kind, either expressed or implied.
; ------------------------------------------------------------------------------

		SECTION MSXHOST

		PUBLIC	msxBIOS
		PUBLIC	msxKey
		PUBLIC	msxSetCliksw
		PUBLIC	msxInitText
		PUBLIC	msxBeep
		PUBLIC	msxINITXT40
		PUBLIC	msxINITXT80
		PUBLIC	msxCHGWIDTH
		PUBLIC	msxCHGMOD
		PUBLIC	msxCLS
		PUBLIC	msxCLRSPR
		PUBLIC	msxCALATR
		PUBLIC	msxCALPAT
		PUBLIC	msxGSPSIZ
		PUBLIC	msxLDIRVM
		PUBLIC	msxWRTVDP
		PUBLIC	msxWRTVRM
		PUBLIC	OSWRTVRM
		PUBLIC	msxSTRPUT
		PUBLIC  msxCHPUT
		PUBLIC	msxPINLINE
		PUBLIC  msxPOSIT
		PUBLIC	msxGETPOS
		PUBLIC	msxCheckMSX2
		PUBLIC	msxGETTICK


INCLUDE "MSXBIOS.def"

; ------------------------------------------------------------------------------
; Use MSX BIOS keyboard input which is faster than via CP/M dosKey routine.
; ------------------------------------------------------------------------------
msxKey:		PUSH	IX
		LD	IX,CHSNS	; Test the status of the keyboard buffer
		CALL	msxBIOS
		JR	Z,_endKey	; Z = no key is pressed
		LD	IX,CHGET	; 
		CALL	msxBIOS
_endKey:	POP	IX
		RET

; ------------------------------------------------------------------------------
; Set keyboard click switch
; ------------------------------------------------------------------------------
msxSetCliksw:	AND	$01		; 0=Off 1=On
		LD	(CLIKSW),A
		RET

; ------------------------------------------------------------------------------
; Initialize text mode (screen 0), uses current screen width setting (LINL40)
; ------------------------------------------------------------------------------
msxInitText:
		PUSH	IX
		LD	IX,INITXT
		CALL	msxBIOS
		POP	IX
		RET
; ------------------------------------------------------------------------------
; CURSOR POSITION
; L  = Y
; H  = X 
; ------------------------------------------------------------------------------		
msxPOSIT:
		PUSH IX
		LD IX,POSIT       ; HLレジスタの値を画面に反映
		CALL msxBIOS
		POP IX
		RET

; ------------------------------------------------------------------------------
; GET CURSOR POSITION
; L  = Y
; H  = X 
; ------------------------------------------------------------------------------		
msxGETPOS:
   	 ; 現在のシステム変数からカーソル位置を取得
    	LD  A,(CSRX)
    	LD  H,A
    	LD  A,(CSRY)
    	LD  L,A
		RET

; ------------------------------------------------------------------------------
; Output Bell / MSX Beep
; CHPUT BELL only works when the VDP is in text mode, use BIOS call instead
; ------------------------------------------------------------------------------
msxBeep:
		PUSH	IX
		LD	IX,BEEP
		CALL	msxBIOS
		POP	IX
		RET
;
; Output String terminated 0
; HL
;
msxSTRPUT:
		LD  A,(HL)
		OR  A
		RET Z
		INC HL
		PUSH HL
		LD	IX,CHPUT      
		CALL msxBIOS	
		POP HL
		JR msxSTRPUT
;
; Output Character
; A=Character
;
msxCHPUT:
		PUSH IX
		LD	IX,CHPUT      
		CALL msxBIOS
		POP IX	
		RET

; ------------------------------------------------------------------------------
; Input line
;  INPUT:Nothing
;  OUTPUT: HL=Address of input buffer
;  CY:CTRL-STOP
; ------------------------------------------------------------------------------
msxPINLINE:
		PUSH IX
		LD IX,KILBUF
		CALL msxBIOS
		XOR	A
		LD	(BUF),A		; clear stale text so PINLINE doesn't re-edit it
		LD	IX,PINLINE   ; 一行入力
		CALL msxBIOS
		INC HL
		POP IX	
		RET            ; CTRL-STOPが押されたらCY=1	
;----------------------------------------------------------------------
; Init Screen   
;  Screen 0, width 40
;
msxINITXT40:
		LD A,40				; set 40 column width
		JR msxCHGWIDTH

; Init Screen   
;  Screen 0, width 80
;
msxINITXT80:
		LD  A,80			; set 80 column width
msxCHGWIDTH:
		LD	(LINL40),A		
msxINITXT:
		PUSH IX
		LD	IX,INITXT
		CALL msxBIOS
		POP IX
		RET
; ------------------------------------------------------------------------------
;
; ------------------------------------------------------------------------------
msxCHGMOD:
		PUSH IX
		LD	IX,CHGMOD
		CALL msxBIOS
		POP IX
		RET

; Write to VDP Reigster
;	input: B = value
;			C= register number
; ------------------------------------------------------------------------------
msxWRTVDP:
		PUSH IX
		LD	IX,WRTVDP
		CALL msxBIOS
		POP IX
		RET


; ------------------------------------------------------------------------------
; Screen Clear
; ------------------------------------------------------------------------------
msxCLS:
		PUSH IX
		LD	IX,CLS
		CALL msxBIOS
		POP IX
		RET		
; ------------------------------------------------------------------------------
;  CLEAR SPRITES
; ------------------------------------------------------------------------------
msxCLRSPR:	
		PUSH IX
		LD	IX,CLRSPR
		CALL msxBIOS
		POP IX
		RET
; ------------------------------------------------------------------------------
;  CALC　ATTRIBUTE
;	input A:PatterbNo
;	output HL:VDP  Attribute address
; ------------------------------------------------------------------------------
msxCALATR:
		PUSH IX
		LD IX,CALATR
		CALL msxBIOS
		POP IX
		RET
; ------------------------------------------------------------------------------
; LDIRMV - Transfer data from VRAM to RAM
; HL = source VRAM address (all bits valid)
; DE = destination RAM address
; BC = length in bytes
; ------------------------------------------------------------------------------
msxLDIRMV:
		PUSH IX
		LD IX,LDIRMV
		CALL msxBIOS
		POP IX
		RET
; ------------------------------------------------------------------------------
; LDIRVM - Transfer data from RAM to VRAM
; HL = source RAM address
; DE = destination VRAM address (all bits valid)
; BC = length in bytes
; ------------------------------------------------------------------------------	
msxLDIRVM:
		PUSH IX
		LD IX,LDIRVM
		CALL msxBIOS
		POP IX
		RET
; ------------------------------------------------------------------------------
; WRTVRM - Write A to VRAM address HL
; ------------------------------------------------------------------------------
msxWRTVRM:
		PUSH IX
		LD IX,WRTVRM
		CALL msxBIOS
		POP IX
		RET

; OSWRTVRM - OS-facing entry point for writing one byte to VRAM.
OSWRTVRM:
		JP msxWRTVRM
; ------------------------------------------------------------------------------
; CALC　Pattern Generator ADDRESS
;	input A:PatterbNo
;	output HL:VDP  Pattern Generator address
; ------------------------------------------------------------------------------
msxCALPAT:
		PUSH IX
		LD IX,CALPAT
		CALL msxBIOS
		POP IX
		RET

; ------------------------------------------------------------------------------
; Get Sprite Pattern Table Size
; output A: size(bytes)
; ------------------------------------------------------------------------------
msxGSPSIZ:
		PUSH IX
		LD IX,GSPSIZ
		CALL msxBIOS
		POP IX
		RET
; ------------------------------------------------------------------------------
;  vsyncカウンタ
; ------------------------------------------------------------------------------
msxGETTICK:	
		LD HL,(JIFFY)
		LD DE,0
		RET
; ------------------------------------------------------------------------------

; Check MSX Version (MSX2 or over)
; On MSX1, print message and exit to OS
; ------------------------------------------------------------------------------
msxCheckMSX2:
		LD	A,(EXBRSA)	; MSX2 Version
		OR	A			; MSX1 ?
		JP	Z,ERRMSX1	; yep, invalid parameter
		RET				; CY=0
; ------------------------------------------------------------------------------
ERRMSX1:	
		LD	DE, msg
		LD	C, $09
		CALL BDOS		; OS SYSTEM CALL
		LD C,$00
		CALL BDOS		; EXIT TO OS

msg:	db	"You need MSX2 or over",0DH,0AH,"$"

; ------------------------------------------------------------------------------
; MSX BIOS routines, interslot call wrapper
; Parameters: 
;   IX = BIOS routine
; ------------------------------------------------------------------------------
msxBIOS:
		PUSH 	IY
		LD	IY,(EXPTBL-1)	; BIOS slot in IYH

		; Save shadow registers
		EXX			
		PUSH	BC
		PUSH	DE
		PUSH	HL
		EXX

		CALL	CALSLT		; interslot call
		
		; Restore shadow registers
		EXX
		POP	HL
		POP	DE
		POP	BC
		EXX
		
		POP	IY
		RET

