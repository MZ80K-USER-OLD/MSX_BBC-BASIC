;	TITLE	BBC BASIC (C) R.T.RUSSELL 1984-2024
;
;PATCH FOR BBC BASIC TO CP/M 2.2 & 3.0
;*    PLAIN VANILLA CP/M VERSION     *
;(C) COPYRIGHT R.T.RUSSELL, 25-12-1986
;VERSION 5.0, 25-05-2024
;
	SECTION CPMHOST

	GLOBAL	OSINIT
	GLOBAL	OSRDCH
	GLOBAL	OSWRCH
	GLOBAL	OSLINE
	GLOBAL	OSSAVE
	GLOBAL	OSLOAD
	GLOBAL	OSOPEN
	GLOBAL	OSSHUT
	GLOBAL	OSBGET
	GLOBAL	OSBPUT
	GLOBAL	OSSTAT
	GLOBAL	GETEXT
	GLOBAL	GETPTR
	GLOBAL	PUTPTR
	GLOBAL	PROMPT
	GLOBAL	RESET
	GLOBAL	LTRAP
	GLOBAL	OSCLI
	GLOBAL	TRAP
	GLOBAL	OSKEY
	GLOBAL	OSCALL
	GLOBAL  CheckMSXDOS
	GLOBAL  PrintAddress
	GLOBAL  PUTCRLF
	GLOBAL  STRPUT
	GLOBAL  CHGWIDTH
	GLOBAL	OSVERCHK
	GLOBAL	OSCHGMOD
	GLOBAL	OSSETSPRITESIZE
	GLOBAL	OSCLRSPR
	GLOBAL	OSCALATR
	GLOBAL	OSCALPAT
	GLOBAL	OSGSPSIZ
	GLOBAL	OSLDIRVM
	GLOBAL	OSSPRITE
	GLOBAL	OSSPRITEATTR

; Primary OS routines
	GLOBAL	CLS
	GLOBAL  PCSR
	GLOBAL  GCSR
	GLOBAL  PTIME
	GLOBAL  GTIME
	GLOBAL  INKEY
	GLOBAL  INITTXT
	GLOBAL	OSGETTICK
	EXTERN	BYE
	EXTERN	GETKEY
;
	EXTERN	ESCAPE
	EXTERN	EXTERR
	EXTERN	CHECK
	EXTERN	CRLF
;
	EXTERN	ACCS
	EXTERN	FREE
	EXTERN	HIMEM
	EXTERN	CURLIN
	EXTERN	AUTONO
	EXTERN	USER
	EXTERN	VERMSG
	EXTERN  WIDTH
	EXTERN	PATHBUF
	EXTERN	DOS_VER
	EXTERN	DIRFIB
	EXTERN	FILE_HANDLE
	EXTERN	FILE_MAXSIZE
	EXTERN	FILE_BUFADRS
	EXTERN	REQ_BYTES
	EXTERN	DOS2_HANDLES
	EXTERN	DOS2_EOF
	EXTERN	DOS2_IOBUF
	EXTERN	PATHBUF2

;MSXBIOS specific routines
	EXTERN	msxKey
	EXTERN	msxPINLINE 
	EXTERN	msxPOSIT
	EXTERN	msxGETPOS
	EXTERN	msxINITXT80
	EXTERN	msxCheckMSXDOS
	EXTERN	msxCLS
	EXTERN	msxSTRPUT
	EXTERN	msxCHPUT
	EXTERN	msxCheckMSX2
	EXTERN	msxGETTICK
	EXTERN	msxCHGMOD
	EXTERN	msxWRTVDP
	EXTERN	msxCLRSPR
	EXTERN	msxCALATR
	EXTERN	msxCALPAT
	EXTERN	msxGSPSIZ
	EXTERN	msxLDIRVM
	EXTERN	OSWRTVRM
	EXTERN	EXEC_CR_PENDING

IFNDEF BDOS
BDOS		EQU	$0005			; MSX-DOS API CALL
ENDIF

INCLUDE "MSXBIOS.def"
;
;
;OSSAVE - Save an area of memory to a file.
;   Inputs: HL addresses filename (term CR)
;           DE = start address of data to save
;           BC = length of data to save (bytes)
; Destroys: A,B,C,D,E,H,L,F
;
STSAVE:	CALL	SAVLOD		;*SAVE
	JP	C,HUH		;"Bad command"
	PUSH	DE
	OR	A
	SBC	HL,DE		;BC = end address - start address
	LD	B,H
	LD	C,L
	POP	DE
	LD	A,(DOS_VER)
	CP	2
	JP	NC,OSSAVE_DOS2
	JP	DOS2_REQUIRED

#ifdef CPM
	PUSH	HL
	JR	OSS1
;
OSSAVE:	
	PUSH	BC		;SAVE
	CALL	SETUP0
OSS1:	EX	DE,HL
	CALL	CREATE
	JR	NZ,SAVE
DIRFUL:	LD	A,190
	CALL	EXTERR
	DEFM	"Directory full"
	DEFB	0
SAVE:	CALL	WRITE
	ADD	HL,BC
	EX	(SP),HL
	SBC	HL,BC
	EX	(SP),HL
	JR	Z,SAVE1
	JR	NC,SAVE
SAVE1:	POP	BC
CLOSE:	LD	A,16
	CALL	BDOS1
	INC	A
	RET	NZ
	LD	A,200
	CALL	EXTERR
	DEFM	"Close error"
	DEFB	0
#endif
;
; CHDIR - *CHDIR / *CD
; HL = directory pathname terminated by CR
;
CHDIR:
    LD      A,(DOS_VER)
    CP      2
	JP      C,DOS2_REQUIRED

    CALL    SKIPSP

    LD      A,(HL)
    CP      CR
    JP      Z,HUH

    CALL    PATHSAVE
    CALL    PATHNORM

    LD      DE,PATHBUF
    LD      C,5AH            ; MSX-DOS2 _CHDIR
    CALL    BDOS

    OR      A
    RET     Z

    LD      A,255
    CALL    EXTERR
    DEFM    "CHDIR error"
    DEFB    0

DOS2_REQUIRED:
    LD      A,255
    CALL    EXTERR
    DEFM    "MSX-DOS2 required"
    DEFB    0
		
;
;OSSHUT - Close disk file(s).
;   Inputs: E = file channel
;           If E=0 all files are closed (except SPOOL)
; Destroys: A,B,C,D,E,H,L,F
;
#ifdef CPM
OSSHUT:	LD	A,E
	OR	A
	JR	NZ,SHUTIT
SHUT0:	INC	E
	BIT	3,E
	RET	NZ
	PUSH	DE
	CALL	SHUT1
	POP	DE
	JR	SHUT0
;
SHUTIT:	CALL	FIND1
	JR	NZ,SHUT2
	JP	CHANER
;
SESHUT:	LD	HL,FLAGS
	RES	0,(HL)		;STOP EXEC
	RES	1,(HL)		;STOP SPOOL
	LD	E,8		;SPOOL/EXEC CHANNEL
SHUT1:	CALL	FIND1
	RET	Z
SHUT2:	XOR	A
	LD	(HL),A
	DEC	HL
	LD	(HL),A
	LD	HL,37
	ADD	HL,DE
	BIT	7,(HL)
	INC	HL
	CALL	NZ,WRITE
	LD	HL,FCBSIZ
	ADD	HL,DE
	LD	BC,(FREE)
	SBC	HL,BC
	JP	NZ,CLOSE
	LD	(FREE),DE	;RELEASE SPACE
	JP	CLOSE
#endif
;
;TYPE - *TYPE command.
;Types file to console output.
;
TYPE:	SCF			;*TYPE
	CALL	OSOPEN
	OR	A
	JP	Z,NOTFND
	LD	E,A
TYPE1:	LD	A,(FLAGS)	;TEST
	BIT	7,A		;FOR
	JR	NZ,TYPESC	;ESCape
	CALL	OSBGET
	CALL	OSWRCH		;N.B. CALLS "TEST"
	JR	NC,TYPE1
	JP	OSSHUT
;
TYPESC:	CALL	OSSHUT		;CLOSE!
	JP	ABORT
;
;OSLOAD - Load an area of memory from a file.
;   Inputs: HL addresses filename (term CR)
;           DE = address at which to load
;           BC = maximum allowed size (bytes)
;  Outputs: Carry reset indicates no room for file.
; Destroys: A,B,C,D,E,H,L,F
;
STLOAD:	CALL	SAVLOD		;*LOAD
	LD	A,(DOS_VER)
	CP	2
	JP	NC,OSLOAD_DOS2

#ifdef CPM
	PUSH	HL
	JR	OSL1
;
OSLOAD:	
OSLOAD_CPM:	PUSH	BC		;LOAD
	CALL	SETUP0
OSL1:	EX	DE,HL
	CALL	OPEN
	JR	NZ,LOAD0
NOTFND:	LD	A,214
	CALL	EXTERR
	DEFM	"File not found"
	DEFB	0
LOAD:	CALL	READ
	JR	NZ,LOAD1
	CALL	INCSEC
	ADD	HL,BC
LOAD0:	EX	(SP),HL
	SBC	HL,BC
	EX	(SP),HL
	JR	NC,LOAD
LOAD1:	POP	BC
	PUSH	AF
	CALL	CLOSE
	POP	AF
	CCF
OSCALL:	RET
#endif

#ifndef CPM
OSSAVE:
	LD	A,(DOS_VER)
	CP	2
	JP	C,DOS2_REQUIRED
	JP	OSSAVE_DOS2

OSLOAD:
	LD	A,(DOS_VER)
	CP	2
	JP	C,DOS2_REQUIRED
	JP	OSLOAD_DOS2

OSCALL:
	RET
#endif

;OSLOAD_DOS2 - Load through an MSX-DOS2 file handle.
; _READ returns the actual byte count in HL.
; Each read is limited to 512 bytes.
;
OSLOAD_DOS2:
	LD	(FILE_BUFADRS),DE
	LD	(FILE_MAXSIZE),BC
	CALL	SETUP0
	CALL	PATHNORM
	CALL	DOS2_DEFAULT_EXT

	LD	DE,PATHBUF
	LD	A,0			; read-only
	CALL	HOPEN
	OR	A
	JP	NZ,FILE_DOS2_NOTFOUND

LOAD_DOS2_LOOP:
	LD	HL,(FILE_MAXSIZE)
	LD	A,H
	OR	L
	JR	Z,FILE_DOS2_CLOSE_OK

	LD	DE,BLOCKSIZE
	OR	A
	SBC	HL,DE
	JR	NC,LOAD_DOS2_FULL_BLOCK
	ADD	HL,DE
	JR	LOAD_DOS2_HAVE_REQUEST

LOAD_DOS2_FULL_BLOCK:
	LD	HL,BLOCKSIZE
LOAD_DOS2_HAVE_REQUEST:
	LD	(REQ_BYTES),HL

	LD	DE,(FILE_BUFADRS)
	LD	HL,(REQ_BYTES)
	CALL	HREAD
	OR	A
	JR	NZ,FILE_DOS2_ERROR
	LD	A,H
	OR	L
	JR	Z,FILE_DOS2_CLOSE_OK

	LD	(FILE_BUFADRS),DE
	EX	DE,HL
	LD	HL,(FILE_MAXSIZE)
	OR	A
	SBC	HL,DE
	JR	C,FILE_DOS2_ERROR
	LD	(FILE_MAXSIZE),HL

	LD	HL,(REQ_BYTES)
	OR	A
	SBC	HL,DE
	JR	C,FILE_DOS2_ERROR
	JR	Z,LOAD_DOS2_LOOP
FILE_DOS2_CLOSE_OK:
	CALL	HCLOSE
	SCF
	RET

FILE_DOS2_NOTFOUND:
	LD	A,214
	CALL	EXTERR
	DEFM	"File not found"
	DEFB	0

FILE_DOS2_CREATE_ERROR:
	LD	A,255
	CALL	EXTERR
	DEFM	"MSX-DOS2 create error"
	DEFB	0

FILE_DOS2_ERROR:
	PUSH	AF
	CALL	HCLOSE
	POP	AF
	LD	A,255
	CALL	EXTERR
	DEFM	"MSX-DOS2 file error"
	DEFB	0

;
;OSSAVE_DOS2 - Save through an MSX-DOS2 file handle.
; _WRITE returns the actual byte count in HL.
; Each write is limited to 512 bytes.
;  DE=FILE BUFFER
;  BC=FILE SIZE (bytes)
OSSAVE_DOS2:
	LD	(FILE_BUFADRS),DE
	LD	(FILE_MAXSIZE),BC
	CALL	SETUP0
	CALL	PATHNORM
	CALL	DOS2_DEFAULT_EXT

	LD	DE,PATHBUF
	XOR A				;Read/Write mode = 0 (read/write)
	CALL	HCREATE
	OR	A
	JP	NZ,FILE_DOS2_CREATE_ERROR
SAVE_DOS2_LOOP:
	LD	HL,(FILE_MAXSIZE)   ;FILE remaining size
	LD	A,H
	OR	L
	JR	Z,FILE_DOS2_CLOSE_OK

	LD	DE,BLOCKSIZE
	OR	A
	SBC	HL,DE
	JR	NC,SAVE_DOS2_FULL_BLOCK	; BLOCK SIZE WRITE
	ADD	HL,DE
	JR	SAVE_DOS2_SIZE; short block write

SAVE_DOS2_FULL_BLOCK:
	LD	HL,BLOCKSIZE	; full block write

SAVE_DOS2_SIZE:
	LD	(REQ_BYTES),HL
	LD	DE,(FILE_BUFADRS)
	LD	HL,(REQ_BYTES)
	CALL	HWRITE
	OR	A
	JP	NZ,FILE_DOS2_ERROR
	LD	A,H
	OR	L
	JP	Z,FILE_DOS2_ERROR

	LD	(FILE_BUFADRS),DE
	EX	DE,HL
	LD	HL,(FILE_MAXSIZE)
	OR	A
	SBC	HL,DE
	JP	C,FILE_DOS2_ERROR
	LD	(FILE_MAXSIZE),HL

	LD	HL,(REQ_BYTES)
	OR	A
	SBC	HL,DE
	JP	C,FILE_DOS2_ERROR	;
	JR	Z,SAVE_DOS2_LOOP
	JP	FILE_DOS2_ERROR	; short write is an error


; HOPEN - Open an MSX-DOS2 file.
;   Inputs: DE = ASCIIZ filename, A = access mode
;  Outputs: A = error code (0 on success), FILE_HANDLE = file handle
; Destroys: A,C,DE,HL,F
HOPEN:
	LD	B,A			; _OPEN access mode
	LD	C,43H			; _OPEN
	CALL	BDOS
	OR	A
	RET	NZ
	LD	A,B
	LD	(FILE_HANDLE),A
	XOR	A
	RET

; HCREATE - Create/truncate an MSX-DOS2 file.
;   Inputs: DE = ASCIIZ filename
;  Outputs: A = error code (0 on success), FILE_HANDLE = file handle
;  Destroys: A,B,C,DE,HL,F
HCREATE:
	LD	B,0			; normal file attribute
	LD	C,44H			; _CREATE
	CALL	BDOS
	OR	A
	RET	NZ
	LD	A,B
	LD	(FILE_HANDLE),A
	XOR	A
	RET

; HCLOSE - Close an MSX-DOS2 file handle.
;   Inputs: FILE_HANDLE = file handle
;  Outputs: A = error code (0 on success)
; Destroys: A,BC,DE,HL,F
HCLOSE:
	LD	A,(FILE_HANDLE)
	LD	B,A
	LD	C,45H			; _CLOSE
	CALL	BDOS
	RET

; HREAD - Read bytes through an MSX-DOS2 file handle.
;   Inputs: FILE_HANDLE = file handle, DE = destination buffer,
;           HL = requested bytes
;  Outputs: A = error code (0 on success), DE = next buffer address,
;           HL = actual bytes read returned by _READ
; Destroys: A,BC,F
HREAD:
	LD	(FILE_BUFADRS),DE
	LD	(REQ_BYTES),HL
	LD	A,(FILE_HANDLE)
	LD	B,A
	LD	DE,(FILE_BUFADRS)
	LD	HL,(REQ_BYTES)
	LD	C,48H			; _READ
	CALL	BDOS
	OR	A
	RET	NZ
	LD	DE,(FILE_BUFADRS)
	PUSH	HL
	ADD	HL,DE
	EX	DE,HL
	POP	HL
	RET
;
; HWRITE - Write bytes through an MSX-DOS2 file handle.
;   Inputs: FILE_HANDLE = file handle, 
;           DE = source buffer,
;           HL = requested bytes
;  Outputs: A = error code (0 on success), 
;           DE = next buffer address,
;           HL = actual bytes written returned by _WRITE	
; Destroys: A,BC,F
HWRITE:
	LD	A,(FILE_HANDLE)
	LD	B,A
	LD	C,49H			; _WRITE
	PUSH DE
	CALL	BDOS
	POP DE
	OR	A
	RET	NZ
	PUSH	HL
	ADD	HL,DE
	EX	DE,HL
	POP	HL
	RET

#ifndef CPM
;
; MSX-DOS2 channel implementation.  BASIC channels 1-7 are available to
; OPENIN/OPENOUT/OPENUP; channel 8 is reserved for SPOOL and EXEC.
;
DOS2_FIND:
	LD	A,E
	OR	A
	JP	Z,DOS2_CHANER
	CP	9
	JP	NC,DOS2_CHANER
	LD	D,0
	LD	HL,DOS2_HANDLES
	ADD	HL,DE
	LD	A,(HL)
	OR	A
	JP	Z,DOS2_CHANER
	LD	(FILE_HANDLE),A
	RET

DOS2_CHANER:
	LD	A,222
	CALL	EXTERR
	DEFM	"Invalid channel"
	DEFB	0

; OSOPEN - open a DOS2 file and return a BASIC file channel.
OSOPEN:
	PUSH	AF
	CALL	PATHSAVE
	CALL	PATHNORM
	CALL	DOS2_DEFAULT_EXT
	LD	E,1
DOS2_OPEN_SLOT:
	LD	D,0
	LD	HL,DOS2_HANDLES
	ADD	HL,DE
	LD	A,(HL)
	OR	A
	JR	Z,DOS2_OPEN_FILE
	INC	E
	LD	A,E
	CP	8
	JR	C,DOS2_OPEN_SLOT
	POP	AF
	LD	A,192
	CALL	EXTERR
	DEFM	"Too many open files"
	DEFB	0
DOS2_OPEN_FILE:
	POP	AF
	PUSH	DE
	LD	DE,PATHBUF
	JR	C,DOS2_OPEN_READ
	XOR A	
	CALL	HCREATE
	JR	DOS2_OPEN_RESULT
DOS2_OPEN_READ:
	LD	A,0
	CALL	HOPEN
DOS2_OPEN_RESULT:
	POP	DE
	OR	A
	JR	Z,DOS2_OPEN_OK
	XOR	A
	RET
DOS2_OPEN_OK:
	LD	HL,DOS2_HANDLES
	LD	D,0
	ADD	HL,DE
	LD	A,(FILE_HANDLE)
	LD	(HL),A
	LD	HL,DOS2_EOF
	ADD	HL,DE
	LD	(HL),0
	LD	A,E
	JP	CHECK

; OSSHUT - close one channel, or all normal channels when E=0.
OSSHUT:
	LD	A,E
	OR	A
	JR	NZ,DOS2_CLOSE_ONE
	LD	E,1
DOS2_CLOSE_ALL:
	PUSH	DE
	CALL	DOS2_CLOSE_IF_OPEN
	POP	DE
	INC	E
	LD	A,E
	CP	8
	JR	C,DOS2_CLOSE_ALL
	RET
DOS2_CLOSE_ONE:
	CALL	DOS2_FIND
	JR	DOS2_CLOSE_HANDLE
DOS2_CLOSE_IF_OPEN:
	LD	D,0
	LD	HL,DOS2_HANDLES
	ADD	HL,DE
	LD	A,(HL)
	OR	A
	RET	Z
	LD	(FILE_HANDLE),A
DOS2_CLOSE_HANDLE:
	PUSH	DE
	CALL	HCLOSE
	POP	DE
	OR	A
	RET	NZ
	LD	D,0
	LD	HL,DOS2_HANDLES
	ADD	HL,DE
	LD	(HL),0
	LD	HL,DOS2_EOF
	ADD	HL,DE
	LD	(HL),0
	RET

OSBGET:
	PUSH	DE
	CALL	DOS2_FIND
	LD	DE,DOS2_IOBUF
	LD	HL,1
	CALL	HREAD
	POP	DE
	OR	A
	JR	Z,DOS2_BGET_CHECK
	CP	0C7H		; MSX-DOS2 EOF
	JP	NZ,FILE_DOS2_ERROR
	XOR	A
DOS2_BGET_CHECK:
	LD	A,H
	OR	L
	JR	NZ,DOS2_BGET_BYTE
	LD	D,0
	LD	HL,DOS2_EOF
	ADD	HL,DE
	LD	(HL),1
	SCF
	RET
DOS2_BGET_BYTE:
	LD	A,(DOS2_IOBUF)
	OR	A
	RET

OSBPUT:
	PUSH	AF
	PUSH	DE
	CALL	DOS2_FIND
	POP	DE
	POP	AF
	LD	(DOS2_IOBUF),A
	LD	DE,DOS2_IOBUF
	LD	HL,1
	CALL	HWRITE
	OR	A
	JP	NZ,FILE_DOS2_ERROR
	LD	A,H
	OR	L
	JP	Z,FILE_DOS2_ERROR
	LD	D,0
	LD	HL,DOS2_EOF
	ADD	HL,DE
	LD	(HL),0
	RET

OSSTAT:
	CALL	DOS2_FIND
	LD	D,0
	LD	HL,DOS2_EOF
	ADD	HL,DE
	LD	A,(HL)
	DEC	A
	RET

; HSEEK - seek FILE_HANDLE. A=origin, DE=low offset, HL=high offset.
HSEEK:
	PUSH	AF
	LD	A,(FILE_HANDLE)
	LD	B,A
	POP	AF
	LD	C,4AH
	CALL	BDOS
	RET

GETPTR:
	CALL	DOS2_FIND
	XOR	A
	LD	DE,0
	LD	HL,0
	JP	HSEEK

PUTPTR:
	EXX
	LD	E,A
	CALL	DOS2_FIND
	EXX
	XOR	A
	JP	HSEEK

GETEXT:
	CALL	DOS2_FIND
	XOR	A
	LD	DE,0
	LD	HL,0
	CALL	HSEEK
	EXX
	LD	A,2
	LD	DE,0
	LD	HL,0
	CALL	HSEEK
	EXX
	XOR	A
	CALL	HSEEK
	EXX
	RET

SESHUT:
	LD	HL,FLAGS
	RES	0,(HL)
	RES	1,(HL)
	LD	E,8
	JP	DOS2_CLOSE_IF_OPEN
;
;
; Open the reserved SPOOL/EXEC channel (channel 8).
;
OPENIT:
	PUSH	AF
	CALL	PATHSAVE
	CALL	PATHNORM
	CALL	DOS2_DEFAULT_EXT
	POP	AF
	LD	DE,PATHBUF
	JR	C,OPENIT_READ
	XOR	A
	CALL	HCREATE
	JR	OPENIT_RESULT
OPENIT_READ:
	LD	A,0
	CALL	HOPEN
OPENIT_RESULT:
	OR	A
	JR	Z,OPENIT_OK
	LD	A,214
	CALL	EXTERR
	DEFM	"File not found"
	DEFB	0
	XOR	A
	RET
OPENIT_OK:
	LD	A,(FILE_HANDLE)
	LD	(DOS2_HANDLES+8),A
	XOR	A
	LD	(DOS2_EOF+8),A
	LD	A,8
	JP	CHECK

NOTFND:
	LD	A,214
	CALL	EXTERR
	DEFM	"File not found"
	DEFB	0
#endif

; Preserve interpreter registers around non-file BDOS calls.
BDOS0:
	PUSH	BC
	PUSH	DE
	PUSH	HL
	PUSH	IX
	PUSH	IY
	LD	C,A
	CALL	BDOS
	INC	H
	DEC	H
	POP	IY
	POP	IX
	POP	HL
	POP	DE
	POP	BC
	RET

;OSOPEN - Open a file for reading or writing.
;   Inputs: HL addresses filename (term CR)
;           Carry set for OPENIN, cleared for OPENOUT.
;   Outputs: A = file channel (=0 if cannot open)
;            DE = file FCB
;   Destroys: A,B,C,D,E,H,L,F
;
#ifdef CPM
OPENIT:	PUSH	AF		;SAVE CARRY
	CALL	SETUP0
	POP	AF
	CALL	NC,CREATE
	CALL	C,OPEN
	RET
;
OSOPEN:	CALL	OPENIT
	RET	Z		;ERROR
	LD	B,7		;MAX. NUMBER OF FILES
	LD	HL,TABLE+15
OPEN1:	LD	A,(HL)
	DEC	HL
	OR	(HL)
	JR	Z,OPEN2		;FREE CHANNEL
	DEC	HL
	DJNZ	OPEN1
	LD	A,192
	CALL	EXTERR
	DEFM	"Too many open files"
	DEFB	0

OPEN2:	LD	DE,(FREE)	;FREE SPACE POINTER
	LD	(HL),E
	INC	HL
	LD	(HL),D
	LD	A,B		;CHANNEL (1-7)
	LD	HL,FCBSIZ
	ADD	HL,DE		;RESERVE SPACE
	LD	(FREE),HL
OPEN3:	LD	HL,FCB		;ENTRY FROM SPOOL/EXEC
	PUSH	DE
	LD	BC,36
	LDIR			;COPY FCB
	EX	DE,HL
	INC	HL
	LD	(HL),C		;CLEAR PTR
	INC	HL
	POP	DE
	LD	B,A
	CALL	RDF		;READ OR FILL
	LD	A,B
	JP	CHECK
;
;OSBPUT - Write a byte to a random disk file.
;   Inputs: E = file channel
;           A = byte to write
; Destroys: A,B,C,F
;
OSBPUT:	PUSH	DE
	PUSH	HL
	LD	B,A
	CALL	FIND
	LD	A,B
	LD	B,0
	DEC	HL
	LD	(HL),B		;CLEAR EOF
	INC	HL
	LD	C,(HL)
	RES	7,C
	SET	7,(HL)
	INC	(HL)
	INC	HL
	PUSH	HL
	ADD	HL,BC
	LD	(HL),A
	POP	HL
	CALL	Z,WRRDF		;WRITE THEN READ/FILL
	POP	HL
	POP	DE
	RET
;
;OSBGET - Read a byte from a random disk file.
;   Inputs: E = file channel
;  Outputs: A = byte read
;           Carry set if LAST BYTE of file
; Destroys: A,B,C,F
;
OSBGET:	PUSH	DE
	PUSH	HL
	CALL	FIND
	LD	C,(HL)
	RES	7,C
	INC	(HL)
	INC	HL
	PUSH	HL
	LD	B,0
	ADD	HL,BC
	LD	B,(HL)
	POP	HL
	CALL	PE,INCRDF	;INC SECTOR THEN READ
	CALL	Z,WRRDF		;WRITE THEN READ/FILL
	LD	A,B
	POP	HL
	POP	DE
	RET
;
;OSSTAT - Read file status.
;   Inputs: E = file channel
;  Outputs: Z flag set - EOF
;           (If Z then A=0)
;           DE = address of file block.
; Destroys: A,D,E,H,L,F
;
OSSTAT:	CALL	FIND
	DEC	HL
	LD	A,(HL)
	INC	A
	RET
;
;GETEXT - Find file size.
;   Inputs: E = file channel
;  Outputs: DEHL = file size (0-&800000)
; Destroys: A,B,C,D,E,H,L,F
;
GETEXT:	CALL	FIND
	EX	DE,HL
	LD	DE,FCB
	LD	BC,36
	PUSH	DE
	LDIR			;COPY FCB
	EX	DE,HL
	EX	(SP),HL
	EX	DE,HL
	LD	A,35
	CALL	BDOS1		;COMPUTE SIZE
	POP	HL
	XOR	A
	JR	GETPT1
;
;GETPTR - Return file pointer.
;   Inputs: E = file channel
;  Outputs: DEHL = pointer (0-&7FFFFF)
; Destroys: A,B,C,D,E,H,L,F
;
GETPTR:	CALL	FIND
	LD	A,(HL)
	ADD	A,A
	DEC	HL
GETPT1:	DEC	HL
	LD	D,(HL)
	DEC	HL
	LD	E,(HL)
	DEC	HL
	LD	H,(HL)
	LD	L,A
	SRL	D
	RR	E
	RR	H
	RR	L
	RET
;
;PUTPTR - Update file pointer.
;   Inputs: A = file channel
;           DEHL = new pointer (0-&7FFFFF)
; Destroys: A,B,C,D,E,H,L,F
;
PUTPTR:	LD	D,L
	ADD	HL,HL
	RL	E
	LD	B,E
	LD	C,H
	LD	E,A		;CHANNEL
	PUSH	DE
	CALL	FIND
	POP	AF
	AND	7FH
	BIT	7,(HL)		;PENDING WRITE?
	JR	Z,PUTPT1
	OR	80H
PUTPT1:	LD	(HL),A
	PUSH	DE
	PUSH	HL
	DEC	HL
	DEC	HL
	DEC	HL
	LD	D,(HL)
	DEC	HL
	LD	E,(HL)
	EX	DE,HL
	OR	A
	SBC	HL,BC
	POP	HL
	POP	DE
	RET	Z
	INC	HL
	OR	A
	CALL	M,WRITE
	PUSH	HL
	DEC	HL
	DEC	HL
	DEC	HL
	LD	(HL),0
	DEC	HL
	LD	(HL),B
	DEC	HL
	LD	(HL),C		;NEW RECORD NO.
	POP	HL
	JR	RDF
;
;WRRDF - Write, read; if EOF fill with zeroes.
;RDF - Read; if EOF fill with zeroes.
;   Inputs: DE address FCB.
;           HL addresses data buffer.
;  Outputs: A=0, Z-flag set.
;           Carry set if fill done (EOF)
; Destroys: A,H,L,F
;
WRRDF:	CALL	WRITE
RDF:	CALL	READ
	DEC	HL
	RES	7,(HL)
	DEC	HL
	LD	(HL),A		;CLEAR EOF FLAG
	RET	Z
	LD	(HL),-1		;SET EOF FLAG
	INC	HL
	INC	HL
	PUSH	BC
	XOR	A
	LD	B,128
FILL:	LD	(HL),A
	INC	HL
	DJNZ	FILL
	POP	BC
	SCF
	RET
;
;INCRDF - Increment record, read; if EOF fill.
;   Inputs: DE addresses FCB.
;           HL addresses data buffer.
;  Outputs: A=1, Z-flag reset.
;           Carry set if fill done (EOF)
; Destroys: A,H,L,F
;
INCRDF:	CALL	INCSEC
	CALL	RDF
	INC	A
	RET
;
;READ - Read a record from a disk file.
;   Inputs: DE addresses FCB.
;           HL = address to store data.
;  Outputs: A<>0 & Z-flag reset indicates EOF.
;           Carry = 0
; Destroys: A,F
;
;BDOS1 - CP/M BDOS call.
;   Inputs: A = function number
;          DE = parameter
;  Outputs: AF = result (carry=0)
; Destroys: A,F
;
READ:	CALL	SETDMA
	LD	A,33
BDOS1:	CALL	BDOS0
	JR	NZ,CPMERR
	OR	A
	RET
CPMERR:	LD	A,255
	CALL	EXTERR
	DEFM	"CP/M Error"
	DEFB	0
;
BDOS0:	PUSH	BC
	PUSH	DE
	PUSH	HL
	PUSH	IX
	PUSH	IY
	LD	C,A
	CALL	BDOS
	INC	H
	DEC	H
	POP	IY
	POP	IX
	POP	HL
	POP	DE
	POP	BC
	RET
;
;WRITE - Write a record to a disk file.
;   Inputs: DE addresses FCB.
;           HL = address to get data.
; Destroys: A,F
;
WRITE:	CALL	SETDMA
	LD	A,40
	CALL	BDOS1
	JR	Z,INCSEC
	LD	A,198
	CALL	EXTERR
	DEFM	"Disk full"
	DEFB	0
;
;INCSEC - Increment random record number.
;   Inputs: DE addresses FCB.

INCSEC:	PUSH	HL
	LD	HL,33
	ADD	HL,DE
INCS1:	INC	(HL)
	INC	HL
	JR	Z,INCS1
	POP	HL
	RET

;OPEN - Open a file for access.
;   Inputs: FCB set up.
;   Outputs: DE = FCB
;            A=0 & Z-flag set indicates Not Found.
;            Carry = 0
;   Destroys: A,D,E,F
;
OPEN:	LD	DE,FCB
	LD	A,15
	CALL	BDOS1
	INC	A
	RET

;CREATE - Create a disk file for writing.
;   Inputs: FCB set up.
;   Outputs: DE = FCB
;            A=0 & Z-flag set indicates directory full.
;            Carry = 0
;   Destroys: A,D,E,F
;
CREATE:	CALL	CHKAMB
	LD	DE,FCB
	LD	A,19
	CALL	BDOS1		;DELETE
	LD	A,22
	CALL	BDOS1		;MAKE
	INC	A
	RET
;
;CHKAMB - Check for ambiguous filename.
; Destroys: A,D,E,F
;
CHKAMB:	PUSH	BC
	LD	DE,FCB
	LD	B,12
CHKAM1:	LD	A,(DE)
	CP	'?'
	JR	Z,AMBIG		;AMBIGUOUS
	INC	DE
	DJNZ	CHKAM1
	POP	BC
	RET
AMBIG:	LD	A,204
	CALL	EXTERR
	DEFM	"Bad name"
	DEFB	0
;
;SETDMA - Set "DMA" address.
;   Inputs: HL = address
; Destroys: A,F
;
SETDMA:	LD	A,26
	EX	DE,HL
	CALL	BDOS0
	EX	DE,HL
	RET
;
;FIND - Find file parameters from channel.
;   Inputs: E = channel
;  Outputs: DE addresses FCB
;           HL addresses pointer byte (FCB+37)
; Destroys: A,D,E,H,L,F
;
FIND:	INC	E		;N.B. channel 8 is SPOOL/EXEC
	DEC	E
	JR	Z,CHANER
	CALL	FIND1
	LD	HL,37
	ADD	HL,DE
	RET	NZ
CHANER:	LD	A,222
	CALL	EXTERR
	DEFM	"Invalid channel"
	DEFB	0
;
;FIND1 - Look up file table.
;   Inputs: E = channel
;  Outputs: Z-flag set = file not opened
;           If NZ, DE addresses FCB
;                  HL points into table
; Destroys: A,D,E,H,L,F
;
FIND1:	LD	A,E
	AND	7
	ADD	A,A
	LD	E,A
	LD	D,0
	LD	HL,TABLE
	ADD	HL,DE
	LD	E,(HL)
	INC	HL
	LD	D,(HL)
	LD	A,D
	OR	E
	RET
#endif
;
;SETUP - Set up File Control Block.
;   Inputs: HL addresses filename
;           Format  [A:]FILENAME[.EXT]
;           Device defaults to current drive
;           Extension defaults to .BBC
;           A = fill character
;  Outputs: HL updated
;           A = terminator
;           BC = 128
; Destroys: A,B,C,H,L,F
;
; MSX-DOS2 path-aware compatibility shim.
; Keep the raw path string in PATHBUF so command handlers can migrate from
; CP/M FCB parsing to path-based DOS calls without immediately breaking the
; legacy file layer.
;
PATHSAVE:	LD	DE,PATHBUF
	XOR	A
	LD	A,(HL)
	CP	'"'
	JR	NZ,PATHS1
	INC	HL
PATHS1:	LD	A,(HL)
	OR	A
	JR	Z,PATHS2
	CP	CR
	JR	Z,PATHS2
	CP	' '
	JR	Z,PATHS2
	CP	'='
	JR	Z,PATHS2
	CP	'"'
	JR	Z,PATHS2
	CP	'|'
	JR	Z,PATHS2
	CP	'/'
	JR	Z,PATHS3
	CP	5CH		; '\'
	JR	Z,PATHS3
	LD	(DE),A
	INC	DE
	INC	HL
	JR	PATHS1
PATHS3:	LD	A,5CH
	LD	(DE),A
	INC	DE
	INC	HL
	JR	PATHS1
PATHS2:	XOR	A
	LD	(DE),A
	RET
;
;PATHNORM - normalise a path string stored in PATHBUF to a DOS2-friendly form.
;   Normalises '/' to '\' and uppercases the drive/path characters.
;   The original FCB-based layer still receives the CP/M-compatible name, but
;   PATHBUF preserves the full path information needed for a later DOS2 switch.
;
PATHNORM:	PUSH	AF
	PUSH	DE
	PUSH	HL
	LD	HL,PATHBUF
PATHN1:	LD	A,(HL)
	OR	A
	JR	Z,PATHNEND
	CP	'/'
	JR	Z,PATHN2
	CP	5CH
	JR	Z,PATHN2
	CALL	UPPRC
	LD	(HL),A
	INC	HL
	JR	PATHN1
PATHN2:	LD	A,5CH
	LD	(HL),A
	INC	HL
	JR	PATHN1
PATHNEND:	POP	HL
	POP	DE
	POP	AF
	RET

; Add the BASIC default extension to PATHBUF when the supplied path has none.
DOS2_DEFAULT_EXT:
	PUSH	AF
	PUSH	BC
	PUSH	DE
	PUSH	HL
	LD	HL,PATHBUF
	LD	B,0
DOS2_EXT_SCAN:
	LD	A,(HL)
	OR	A
	JR	Z,DOS2_EXT_END
	CP	'.'
	JR	Z,DOS2_EXT_HAVE
	INC	HL
	INC	B
	JR	DOS2_EXT_SCAN
DOS2_EXT_END:
	LD	A,B
	CP	61			; PATHBUF capacity (including terminator)
	JR	NC,DOS2_EXT_HAVE
	LD	(HL),'.'
	INC	HL
	LD	(HL),'B'
	INC	HL
	LD	(HL),'B'
	INC	HL
	LD	(HL),'C'
	INC	HL
	LD	(HL),0
DOS2_EXT_HAVE:
	POP	HL
	POP	DE
	POP	BC
	POP	AF
	RET
;
#ifndef CPM
; DOS2 operations use PATHBUF directly, not a CP/M File Control Block.
SETUP0:
SETUP:
	CALL	PATHSAVE
	JP	SKIPSP
#endif

#ifdef CPM
;FCB FORMAT (36 BYTES TOTAL):
; 0      0=SAME DISK, 1=DISK A, 2=DISK B (ETC.)
; 1-8    FILENAME, PADDED WITH SPACES
; 9-11   EXTENSION, PADDED WITH SPACES
; 12     CURRENT EXTENT, SET TO ZERO
; 32-35  CLEARED TO ZERO
;
SETUP0:	LD	A,' '
SETUP:	PUSH	DE
	PUSH	HL
	PUSH	AF
	CALL	PATHSAVE
	POP	AF
	LD	DE,FCB+9
	LD	HL,BBC
	LD	BC,3
	LDIR
	LD	HL,FCB+32
	LD	B,4
SETUP1:	LD	(HL),C
	INC	HL
	DJNZ	SETUP1
	POP	HL
	LD	C,A
	XOR	A
	LD	(DE),A
	POP	DE
	CALL	SKIPSP
	CP	'"'
	JR	NZ,SETUP2
	INC	HL
	CALL	SKIPSP
	CALL	SETUP2
	CP	'"'
	INC	HL
	JR	Z,SKIPSP
BADSTR:	LD	A,253
	CALL	EXTERR
	DEFM	"Bad string"
	DEFB	0
;
PARSE:	LD	A,(HL)
	INC	HL
	CP	'`'
	RET	NC
	CP	'?'
	RET	C
	XOR	40H
	RET
;
SETUP2:	PUSH	DE
	INC	HL
	LD	A,(HL)
	CP	':'
	DEC	HL
	LD	A,B
	JR	NZ,DEVICE
	LD	A,(HL)		;DRIVE
	AND	31
	INC	HL
	INC	HL
DEVICE:	LD	DE,FCB
	LD	(DE),A
	INC	DE
	LD	B,8
COPYF:	LD	A,(HL)
	CP	'.'
	JR	Z,COPYF1
	CP	' '
	JR	Z,COPYF1
	CP	CR
	JR	Z,COPYF1
	CP	'='
	JR	Z,COPYF1
	CP	'"'
	JR	Z,COPYF1
	LD	C,'?'
	CP	'*'
	JR	Z,COPYF1
	LD	C,' '
	INC	HL
	CP	'|'
	JR	NZ,COPYF2
	CALL	PARSE
	JR	COPYF0
COPYF1:	LD	A,C
COPYF2:	CALL	UPPRC
COPYF0:	LD	(DE),A
	INC	DE
	DJNZ	COPYF
COPYF3:	LD	A,(HL)
	INC	HL
	CP	'*'
	JR	Z,COPYF3
	CP	'.'
	LD	BC,3*256+' '
	LD	DE,FCB+9
	JR	Z,COPYF
	DEC	HL
	POP	DE
	LD	BC,128
;
BBC:	DEFM	"BBC"
#endif

SKIPSP:	LD	A,(HL)
	CP	' '
	RET	NZ
	INC	HL
	JR	SKIPSP
;
;HEX - Read a hex string and convert to binary.
;   Inputs: HL = text pointer
;  Outputs: HL = updated text pointer
;           DE = value
;            A = terminator (spaces skipped)
; Destroys: A,D,E,H,L,F
;
HEX:	LD	DE,0		;INITIALISE
	CALL	SKIPSP
HEX1:	LD	A,(HL)
	CALL	UPPRC
	CP	'0'
	JR	C,SKIPSP
	CP	'9'+1
	JR	C,HEX2
	CP	'A'
	JR	C,SKIPSP
	CP	'F'+1
	JR	NC,SKIPSP
	SUB	7
HEX2:	AND	0FH
	EX	DE,HL
	ADD	HL,HL
	ADD	HL,HL
	ADD	HL,HL
	ADD	HL,HL
	EX	DE,HL
	OR	E
	LD	E,A
	INC	HL
	JR	HEX1
;
;OSCLI - Process an "operating system" command
;
OSCLI:	CALL	SKIPSP
	CP	CR
	RET	Z
	CP	'|'
	RET	Z
	CP	'.'
	JP	Z,DOT		;*.
	CP	'*'
	JR	NZ,OSCLIC
	INC	HL
OSCLIC:
	EX	DE,HL
	LD	HL,COMDS ; OS command table
OSCLI0:	LD	A,(DE)
	CALL	UPPRC
	CP	(HL)
	JR	Z,OSCLI2
	JP	C,HUH   ;END　OF　OS Command Table
OSCLI1:	BIT	7,(HL)  ;　 
	INC	HL
	JR	Z,OSCLI1
	INC	HL
	INC	HL
	JR	OSCLI0
;
OSCLI2:	PUSH	DE
OSCLI3:	INC	DE
	INC	HL
	LD	A,(DE)
	CALL	UPPRC
	CP	'.'		;ABBREVIATED?
	JR	Z,OSCLI4
	XOR	(HL)
	JR	Z,OSCLI3
	CP	80H
	JR	Z,OSCLI4
	POP	DE
	JR	OSCLI1
;
OSCLI4:	POP	AF
	INC	DE
OSCLI5:	BIT	7,(HL)
	INC	HL
	JR	Z,OSCLI5
	LD	A,(HL)
	INC	HL
	LD	H,(HL)
	LD	L,A
	PUSH	HL
	EX	DE,HL
	JP	SKIPSP
;
;
ERA:	CALL	SETUP0		;*ERA, *ERASE
	LD	DE,PATHBUF
	LD	C,4DH		; _DELETE
	CALL	BDOS
	OR	A
	RET	Z
	JP	HUH
;
RES:	LD	C,13		;*RESET
	CALL	BDOS
	RET
;
DRV:	CALL	SETUP0		;*DRIVE
	LD	A,(PATHBUF)
	CALL	UPPRC
	SUB	'A'
	JP	C,HUH
	LD	E,A
	LD	C,14
	CALL	BDOS
	RET
;
REN:	CALL	SETUP0		;*REN, *RENAME
	CP	'='
	JR	NZ,HUH
	INC	HL		;SKIP "="
	PUSH	HL
	LD	HL,PATHBUF
	LD	DE,PATHBUF2
REN1:	LD	A,(HL)
	LD	(DE),A
	INC	HL
	INC	DE
	OR	A
	JR	NZ,REN1
	POP	HL
	CALL	PATHSAVE
	CALL	PATHNORM
	LD	A,(HL)
	CP	CR
	JR	NZ,HUH
	LD	DE,PATHBUF2
	LD	HL,PATHBUF
	LD	C,4EH		; _RENAME
	CALL	BDOS
	OR	A
	RET	Z
	JP	HUH
HUH:	LD	A,254
	CALL	EXTERR
	DEFM	"Bad command"
	DEFB	0
;
#ifdef CPM
EXISTS:	LD	HL,DSKBUF
	CALL	SETDMA
	LD	DE,FCB
	LD	A,17
	CALL	BDOS1		;SEARCH
	INC	A
	RET	Z
	LD	A,196
	CALL	EXTERR
	DEFM	"File exists"
	DEFB	0
#endif
;
SAVLOD:	CALL	SETUP0		;PART OF *SAVE, *LOAD
	CALL	HEX
	CP	'+'
	PUSH	AF
	PUSH	DE
	JR	NZ,SAVLO1
	INC	HL
SAVLO1:	CALL	HEX
	CP	CR
	JR	NZ,HUH
	EX	DE,HL
	POP	DE
	POP	AF
	RET	Z
	OR	A
	SBC	HL,DE
	RET	NZ
	JR	HUH
;
DOT:	INC	HL
DIR:	CALL	PATHSAVE
	LD	A,(PATHBUF)
	OR	A
	JR	Z,DIRDOS2
	CALL	PATHNORM
	JP	DIRDOS2

#ifdef CPM
	LD	C,17
DIR0:	LD	B,4
DIR1:	CALL	LTRAP
	LD	DE,FCB
	LD	HL,DSKBUF
	CALL	SETDMA
	LD	A,C
	CALL	BDOS1		;SEARCH DIRECTORY
	JP	M,CRLF
	RRCA
	RRCA
	RRCA
	AND	60H
	LD	E,A
	LD	D,0
	LD	HL,DSKBUF+1
	ADD	HL,DE
	PUSH	HL
	LD	DE,8
	ADD	HL,DE
	LD	E,(HL)
	INC	HL
	BIT	7,(HL)		;SYSTEM FILE?
	POP	HL
	LD	C,18
	JR	NZ,DIR1
	PUSH	BC
	LD	A,(FCB)
	DEC	A
	LD	C,25
	CALL	M,BDC
	ADD	A,'A'
	CALL	OSWRCH
	LD	B,8
	LD	A,' '
	BIT	7,E		;READ ONLY?
	JR	Z,DIR3
	LD	A,'*'
DIR3:	CALL	CPTEXT
	LD	B,3
	LD	A,' '
	CALL	SPTEXT
	POP	BC
	DJNZ	DIR2
	CALL	CRLF
	JR	DIR0
;
DIR2:	PUSH	BC
	LD	B,5
PAD:	LD	A,' '
	CALL	OSWRCH
	DJNZ	PAD
	POP	BC
	JR	DIR1
#endif
;
; MSX-DOS2 directory search.  FFIRST/FNEXT use IX as a 64-byte
; file information block rather than a file handle.
;
DIRDOS2:
	LD	HL,PATHBUF
	LD	A,(HL)
	OR	A
	JR	NZ,DIRD21
	LD	(HL),'*'
	INC	HL
	LD	(HL),'.'
	INC	HL
	LD	(HL),'*'
	INC	HL
	LD	(HL),0
DIRD21:
	CALL	LTRAP
	LD	DE,PATHBUF
	LD	IX,DIRFIB
	LD	B,10H		; Include directory entries.
	LD	C,40H		; FFIRST
	CALL	BDOS
	OR	A
	JR	NZ,DIRD2END
	LD	B,4		; Four filenames per output line.
DIRD22:
	LD	HL,DIRFIB+1	; FIB filename field (ASCIIZ).
	CALL	DIRD2PUT
	DJNZ	DIRD23
	CALL	CRLF
	LD	B,4
DIRD23:
	PUSH	BC
	CALL	LTRAP
	LD	IX,DIRFIB
	LD	C,41H		; FNEXT
	CALL	BDOS
	POP	BC
	OR	A
	JR	Z,DIRD22
	LD	A,B
	CP	4
	CALL	NZ,CRLF
DIRD2END:
	RET
;
;DIRD2PUT - Print an ASCIIZ filename in a 13-character column.
;   Inputs: HL = address of filename
;   Destroys: A,C,H,L,F
;
DIRD2PUT:
	LD	C,13
DIRD2P1:
	LD	A,(HL)
	OR	A
	JR	Z,DIRD2P2
	INC	HL
	CALL	OSWRCH
	DEC	C
	JR	NZ,DIRD2P1
	RET
DIRD2P2:
	LD	A,' '
	CALL	OSWRCH
	DEC	C
	JR	NZ,DIRD2P2
	RET
;
OPT:	CALL	HEX		;*OPT
	LD	A,E
	AND	3
SETOPT:	LD	(OPTVAL),A
	RET
;
RESET:	XOR	A
	JR	SETOPT
;
EXEC:	LD	A,00000001B	;*EXEC
	JR	SPOOL1	;
SPOOL:	LD	A,00000010B	;*SPOOL
SPOOL1:
	PUSH	AF
	PUSH	HL
	CALL	SESHUT		;STOP SPOOL/EXEC
	POP	HL
	POP	BC
	LD	A,(HL)
	CP	CR		;JUST SHUT?
	RET	Z
	LD	A,(FLAGS)
	OR	B
	LD	(FLAGS),A	;SPOOL/EXEC FLAG
	RRA			;CARRY=1 FOR EXEC
	CALL	OPENIT	;OPEN SPOOL/EXEC FILE
	RET	Z		;DIR FULL / NOT FOUND
	POP	IX		;RETURN ADDRESS
JPIX:	JP	(IX)		;"RETURN"
;
UPPRC:	AND	7FH
	CP	'a'
	RET	C
	CP	'z'+1
	RET	NC
	AND	5FH		;CONVERT TO UPPER CASE
	RET
;
HELP:	LD	B,32
	LD	HL,VERMSG
	JP	PTEXT
;
;*ESC COMMAND
;
ESCCTL:	LD	A,(HL)
	CALL	UPPRC		;**
	CP	'O'
	JR	NZ,ESCC1
	INC	HL
ESCC1:	CALL	HEX
	LD	A,E
	OR	A
	LD	HL,FLAGS
	RES	6,(HL)		;ENABLE ESCAPE
	RET	Z
	SET	6,(HL)		;DISABLE ESCAPE
	RET
;
; OSのコマンド
;
COMDS:	DEFM	"BY"
	DEFB	'E'+80H
	DEFW	BYE
 	DEFM    "C"
    DEFB    'D'+80H	;CD
    DEFW    CHDIR
    DEFM    "CHDI"
    DEFB    'R'+80H	; CHDIR
    DEFW    CHDIR	
	DEFM	"DI"
	DEFB	'R'+80H
	DEFW	DIR
	DEFM	"DRIV"
	DEFB	'E'+80H
	DEFW	DRV
	DEFM	"ERAS"
	DEFB	'E'+80H
	DEFW	ERA
	DEFM	"ER"
	DEFB	'A'+80H
	DEFW	ERA
	DEFM	"ES"
	DEFB	'C'+80H
	DEFW	ESCCTL
	DEFM	"EXE"
	DEFB	'C'+80H
	DEFW	EXEC
	DEFM	"HEL"
	DEFB	'P'+80H
	DEFW	HELP
	DEFM	"LOA"
	DEFB	'D'+80H
	DEFW	STLOAD
	DEFM	"OP"
	DEFB	'T'+80H
	DEFW	OPT
	DEFM	"QUI"
	DEFB	'T'+80H
	DEFW	BYE
	DEFM	"RENAM"
	DEFB	'E'+80H
	DEFW	REN
	DEFM	"RE"
	DEFB	'N'+80H
	DEFW	REN
	DEFM	"RESE"
	DEFB	'T'+80H
	DEFW	RES
	DEFM	"SAV"
	DEFB	'E'+80H
	DEFW	STSAVE
	DEFM	"SPOO"
	DEFB	'L'+80H
	DEFW	SPOOL
	DEFM	"TYP"
	DEFB	'E'+80H
	DEFW	TYPE
	DEFB	0FFH
;
;PTEXT - Print text
;   Inputs: HL = address of text
;            B = number of characters to print
; Destroys: A,B,H,L,F
;
CPTEXT:	PUSH	AF
	LD	A,':'
	CALL	OSWRCH
	POP	AF
SPTEXT:	CALL	OSWRCH
PTEXT:	LD	A,(HL)
	AND	7FH
	INC	HL
	CALL	OSWRCH
	DJNZ	PTEXT
	RET
;
;OSINIT - Initialise RAM mapping etc.
;If BASIC is entered by BBCBASIC FILENAME then file
;FILENAME.BBC is automatically CHAINed.
;   Outputs: DE = initial value of HIMEM (top of RAM)
;            HL = initial value of PAGE (user program)
;            Z-flag reset indicates AUTO-RUN.
;  Destroys: A,B,C,D,E,H,L,F
;
OSINIT:	CALL	GETDOSVER
	LD	C,45		;*
	LD	E,254		;*
	CALL	BDOS		;*
	XOR	A
	LD	B,INILEN
	LD	HL,TABLE
CLRTAB:	LD	(HL),A		;CLEAR FILE TABLE ETC.
	INC	HL
	DJNZ	CLRTAB
	LD	DE,ACCS
	LD	HL,DSKBUF
	LD	C,(HL)
	INC	HL
	CP	C		;N.B. A=B=0
	JR	Z,NOBOOT
	LDIR			;COPY TO ACCS
NOBOOT:	EX	DE,HL
	LD	(HL),CR
	LD	DE,(6)		;DE = HIMEM
	LD	E,A		;PAGE BOUNDARY
	LD	HL,USER
	RET
;
;
;TRAP - Test ESCAPE flag and abort if set;
;       every 20th call, test for keypress.
; Destroys: A,H,L,F
;
;LTRAP - Test ESCAPE flag and abort if set.
; Destroys: A,F
;
TRAP:	LD	HL,TRPCNT
	DEC	(HL)
	CALL	Z,TEST20	;TEST KEYBOARD
LTRAP:	LD	A,(FLAGS)	;ESCAPE FLAG
	OR	A		;TEST
	RET	P
ABORT:	LD	HL,FLAGS	;ACKNOWLEDGE
	RES	7,(HL)		;ESCAPE
	JP	ESCAPE		;AND ABORT
;
;TEST - Sample for ESCape and CTRL/S. If ESCape
;       pressed set ESCAPE flag and return.
; Destroys: A,F
;
TEST20:	LD	(HL),20
TEST:	PUSH	DE
	CALL	msxKey
	POP	DE
	OR	A
	RET	Z
	CP	'S' & 1FH	;PAUSE DISPLAY?
	JR	Z,OSRDCH
	CP	ESC
	JR	Z,ESCSET
	LD	(INKEY),A
	RET
;
;OSRDCH - Read from the current input stream (keyboard).
;  Outputs: A = character
; Destroys: A,F
;
KEYGET:	LD	B,(IX-12)	;SCREEN WIDTH
	CALL	OSRDCH
	CP	DEL
	JR	Z,KEYDEL
	CP	224
	RET	NZ
	CALL	OSRDCH
	SUB	65
	RET
;
KEYDEL:	LD	A,BS
	RET
;
OSRDCH:	LD	A,(FLAGS)
	RRA			;*EXEC ACTIVE?
	JR	C,EXECIN
	PUSH	HL
	SBC	HL,HL		;HL=0
	CALL	OSKEY
	POP	HL
	RET	C
	JR	OSRDCH
;
;EXECIN - Read byte from EXEC file
;  Outputs: A = byte read
; Destroys: A,F
;
EXECIN:	PUSH	BC		;SAVE REGISTERS
	PUSH	DE
	PUSH	HL
	LD	E,8		;SPOOL/EXEC CHANNEL
	LD	HL,FLAGS
	RES	0,(HL)
	CALL	OSBGET
	LD	HL,FLAGS
	SET	0,(HL)
	PUSH	AF
	CALL	C,SESHUT	;END EXEC IF EOF
	POP	AF
	POP	HL		;RESTORE REGISTERS
	POP	DE
	POP	BC
	RET
;
;
;OSKEY - Read key with time-limit, test for ESCape.
;Main function is carried out in user patch.
;   Inputs: HL = time limit (centiseconds)
;  Outputs: Carry reset if time-out
;           If carry set A = character
; Destroys: A,H,L,F
;
OSKEY:	PUSH	HL
	LD	HL,INKEY
	LD	A,(HL)
	LD	(HL),0
	POP	HL
	OR	A
	SCF
	RET	NZ
	PUSH	DE
	CALL	GETKEY
	POP	DE
	RET	NC
	CP	ESC
	SCF
	RET	NZ
ESCSET:	PUSH	HL
	LD	HL,FLAGS
	BIT	6,(HL)		;ESC DISABLED?
	JR	NZ,ESCDIS
	SET	7,(HL)		;SET ESCAPE FLAG
ESCDIS:	POP	HL
	RET
;
;OSWRCH - Write a character to console output.
;   Inputs: A = character.
; Destroys: Nothing
;
OSWRCH:	PUSH	AF
	PUSH	DE
	PUSH	HL
	CALL  msxCHPUT
	POP	HL
	POP	DE
	POP	AF
	RET
;
;OSLINE - Read/edit a complete line, terminated by CR.
;   Inputs: HL addresses destination buffer.
;           (L=0)
;  Outputs: Buffer filled, terminated by CR.
;           A=0.
; Destroys: A,B,C,D,E,H,L,F
;
OSLINE:	
	LD	A,(FLAGS)
	BIT	0,A		; EXEC active?
	JR	NZ,OSLINE_EXEC
INLINE:
	XOR	A
	LD (CSTYLE),A		; curstyle square
	EX DE,HL
	PUSH DE
	CALL msxPINLINE   	; 一行入力 入力先 BUF
    POP DE
	JR C,OSLINE_STOP   ; CTRL-STOPが押されたら終わり
INLINE0:
	INC HL 		; HL=BUF-1 　だから
	LD A,(HL)
	LD (DE),A
	INC DE
	OR A
	JR NZ,INLINE0
	LD (DE),A	; NULL 終端 
	DEC DE
	LD A,CR
	LD (DE),A	; 0DH,NULL
	RET

OSLINE_STOP:
	LD A,CR
	LD (DE),A	; 0DH
	INC DE 
	XOR A
	LD (DE),A	; NULL 終端
	SCF			; CTRL-STOPが押されたことを示す
	RET

; Read an EXEC file line without invoking the keyboard line editor.
OSLINE_EXEC:
	EX	DE,HL
OSLINE_EXEC1:
	CALL	OSRDCH
	JR	C,OSLINE_EXEC_EOF
	PUSH	AF
	LD	HL,EXEC_CR_PENDING
	LD	A,(HL)
	OR	A
	JR	Z,OSLINE_EXEC_NO_PENDING
	XOR	A
	LD	(HL),A
	POP	AF
	CP	LF
	JR	Z,OSLINE_EXEC1
	JR	OSLINE_EXEC_STORE

OSLINE_EXEC_NO_PENDING:
	POP	AF
	JR	OSLINE_EXEC_STORE

OSLINE_EXEC_STORE:
	LD	(DE),A
	INC	DE
	CP	CR
	JR	Z,OSLINE_EXEC_CR
	CP	LF		; accept LF-only and CRLF text files
	JR	NZ,OSLINE_EXEC1
	XOR	A
	LD	(DE),A
	RET

OSLINE_EXEC_CR:
	LD	A,1
	LD	(EXEC_CR_PENDING),A
	XOR	A
	LD	(DE),A
	RET

OSLINE_EXEC_EOF:
	XOR	A
	LD	(EXEC_CR_PENDING),A
	LD	A,CR
	LD	(DE),A
	INC	DE
	XOR	A
	LD	(DE),A
	RET
;
; INIT SCREEN
;	
INITTXT:
	LD A,80
;
; SCREEN WIDTH
;
CHGWIDTH:	
	LD (WIDTH),A    ;  BBC-BASIC screen width setting
	LD (LINL40),A   ;  MSX-BIOS screen width setting
	JP msxINITXT80
;
; SCREEN MODE
;
OSCHGMOD:
	JP msxCHGMOD

OSSETSPRITESIZE:
	EX AF,AF'
	PUSH AF
	EX AF,AF'
	PUSH BC
	PUSH DE
	PUSH HL
	AND 1                  ; sprite size: 0=8x8, 1=16x16
	ADD A,A                ; VDP R#1 bit 1
	LD D,A
	LD A,B
	AND 1                  ; magnification: 0=normal, 1=double
	OR D                   ; VDP R#1 bit 0 + bit 1
	LD A,(RG1SAV)
	AND 0FCH
	OR D                   ; preserve VDP R#1 bits 2-7
	LD (RG1SAV),A
	LD B,A                 ; WRTVDP data
	LD C,1                 ; VDP register 1
	CALL msxWRTVDP
	POP HL
	POP DE
	POP BC
	EX AF,AF'
	POP AF
	EX AF,AF'
	RET

; MSX sprite APIs
OSCLRSPR:
	JP msxCLRSPR

OSCALATR:
	JP msxCALATR

OSCALPAT:
	JP msxCALPAT

OSGSPSIZ:
	JP msxGSPSIZ

OSLDIRVM:
	JP msxLDIRVM

; OSSPRITE - Define one sprite pattern.
; A = sprite pattern number, HL = source data address.
; The MSX BIOS supplies the VRAM destination and pattern size.
OSSPRITE:
	PUSH HL
	CALL msxCALPAT
	EX DE,HL
	POP HL
	PUSH DE
	PUSH HL
	CALL msxGSPSIZ
	POP HL
	POP DE
	LD C,A
	LD B,0
	JP msxLDIRVM

; OSSPRITEATTR - Write one sprite's four-byte attribute record.
; A = sprite number, HL = address of Y,X,pattern,colour data.
OSSPRITEATTR:
	PUSH IX
	PUSH HL
	POP IX
	CALL msxCALATR
	EX DE,HL
	LD A,(IX+0)
	PUSH DE
	LD H,D
	LD L,E
	CALL OSWRTVRM
	POP DE
	INC DE
	LD A,(IX+1)
	PUSH DE
	LD H,D
	LD L,E
	CALL OSWRTVRM
	POP DE
	INC DE
	LD A,(IX+2)
	PUSH DE
	LD H,D
	LD L,E
	CALL OSWRTVRM
	POP DE
	INC DE
	LD A,(IX+3)
	PUSH DE
	LD H,D
	LD L,E
	CALL OSWRTVRM
	POP DE
	POP IX
	RET

;---------------------------
;   OSVERCHK
OSVERCHK:
	JP msxCheckMSX2

;
; OS GET TICK
;
OSGETTICK:
	JP msxGETTICK	;

;------------------------------------------------------------------------------
; Check Msx-DOS Version (MSX1 or MSX2)
; ------------------------------------------------------------------------------
CheckMSXDOS:
	CALL GETDOSVER

	; --- バージョン表示 ---
	; DOS_VER is initialized by OSINIT so AUTO-RUN also uses DOS2 I/O.
	; --- 判定と表示 ---
	ld   a, (DOS_VER)
	cp   2
	jr   nc, print_dos2

print_dos1:
	LD HL, MSG_DOS1
	JP msxSTRPUT

print_dos2:
	LD HL, MSG_DOS2
	JP msxSTRPUT

GETDOSVER:
	ld   bc, 006Fh      ; MSX-DOS2 _DOSVER
	call BDOS
	ld   a, b            ; major version
	ld   (DOS_VER), a
	ret

; --- データエリア ---
MSG_DOS1: DEFB "MSX-DOS 1",0DH,0AH,00
MSG_DOS2: DEFB "MSX-DOS 2",0DH,0AH,00

; ======================================================
; HLレジスタの内容をASCII 4文字で画面に表示する
; ======================================================
PrintAddress:
    ld  a, h
    call PrintHexByte   ; 上位バイト(H)を表示
    ld  a, l            ; 下位バイト(L)を表示
    ; そのまま下の PrintHexByte へ流れる (Fall-through)

; --- 1バイト(A)を16進ASCII 2文字で表示 ---
PrintHexByte:
    push af             ; 下位ニブル保存用
    rrca 
	rrca 		        ; 上位4ビットを下位へ移動
    rrca 
	rrca
    call PrintNibble    ; 上位桁を表示
    pop  af             ; 下位ニブルを戻す
    ; そのまま下の PrintNibble へ流れる

; --- 下位4ビット(A)をASCII 1文字で表示 (DAAマジック) ---
PrintNibble:
    and  0Fh            ; 下位4ビットのみにマスク
    add  a, 90h         ; 10進補正を利用するためのオフセット
    daa                 ; 0-9はそのまま、A-Fは桁上げが発生
    adc  a, 40h         ; ASCII '0'(30h)や'A'(41h)への調整
    daa                 ; 最終的なASCIIコードに確定

; --- [システム依存] 1文字出力ルーチン ---
    ; Aレジスタの文字を表示します。
    ; お使いの環境に合わせて書き換えてください。
PUTCHAR::
	JP msxCHPUT ; 画面に表示 (自動的にXが+1される)    

PUTCRLF:
	LD A,CR
	CALL msxCHPUT
	LD  A,LF
	JP  msxCHPUT

PROMPT:
	LD	A,(FLAGS)
	BIT	0,A		; EXEC active?
	RET	NZ
	LD A,'>'
	JP msxCHPUT
;
; HLレジスタの指す文字列を画面に出力するルーチン
; 文字列はNULL(0)で終端されているもの
STRPUT:
    JP msxSTRPUT ; 文字列出力

;
;
;EDITST:	DEFM	"EDIT"
;LISTST:	DEFM	"LIST"
;
BEL	EQU	7
BS	EQU	8
HT	EQU	9
LF	EQU	0AH
VT	EQU	0BH
CR	EQU	0DH
ESC	EQU	1BH
DEL	EQU	7FH
;
FCB	EQU	5CH
DSKBUF	EQU	80H
;
FCBSIZ	EQU	128+36+2
BLOCKSIZE EQU 256
;
TRPCNT:	DEFB	10
TABLE:	DEFS	16		;FILE BLOCK POINTERS
FLAGS:	DEFB	0
INKEY:	DEFB	0
EDPTR:	DEFW	0
OPTVAL:	DEFB	0
INILEN	EQU	$-TABLE
;
FIN:	;END
