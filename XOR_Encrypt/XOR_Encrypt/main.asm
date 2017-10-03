TITLE XOR Encryption				(main.asm)
; Author:  Barrett Otte
; Started: 09-28-2017
;
; Purpose: Sometimes I like to play around with ASM for no good reason.
;		    This project will read in a text file and either encrypt or decrypt it
;			using simple XOR encryption.
;
; Reading:
;		Irvine32 Documentation:			http://programming.msjc.edu/asm/help/index.html?page=source%2Fabout.htm
;		Instruction Set Reference:		http://www.felixcloutier.com/x86/
;		ASCII Art Generator:			http://patorjk.com/software/taag/
;		Visual Studio Environment Setup	http://kipirvine.com/asm/gettingStartedVS2015/index.htm
;
;
; To Do:
;	- Binary file support
;	- Better encryption key. (Single character is kind of lame and limiting)
;	- Console file editing (READ, APPEND, WRITE, CREATE)
;
;
; Features:
;	- Encryption/Decryption of user inputted text file by a single hex character encryption key.
;
;
;
; Bugs:
;
;
;
;
;
;
; LAST UPDATED: 10-01-2017


; Include Files:
INCLUDE Irvine32.inc
INCLUDE macros.inc


; Constants:
BUFFER_SIZE = 50


; Macros:
mGotoxy MACRO X:REQ, Y:REQ							; Reposition cursor to x,y position
	PUSH  EDX
	MOV   DH, Y
	MOV   DL, X
	CALL  Gotoxy
	POP   EDX
ENDM

mWrite MACRO text:REQ								; Write string literals.
	LOCAL string
	.data
		string BYTE text, 0
	.code
		PUSH 	EDX
		MOV	EDX, OFFSET string
		CALL 	WriteString
		POP	EDX
ENDM

mWriteString MACRO buffer:REQ							; Write string variables
	PUSH  EDX
	MOV   EDX, OFFSET buffer
	CALL  WriteString
	POP   EDX
ENDM

mReadString MACRO var:REQ							; Read string from console
	PUSH ECX
	PUSH EDX
	MOV  EDX, OFFSET var
	MOV  ECX, SIZEOF var
	CALL ReadString
	POP  EDX
	POP  ECX
ENDM

BUFFER_SIZE = 5000

.data
	buffer		BYTE	BUFFER_SIZE	DUP(?)
	filename	BYTE	80		DUP(0)
	outputFileName	BYTE	80		DUP(0)
	fileHandle	HANDLE	?
	bytesRead	DWORD	?
	encryptionKey	BYTE	?
.code


main PROC
	CALL ProgramLoop
	RET
main ENDP


ProgramLoop PROC
	CALL	DrawTitleScreen
	loop_begin:
		CALL	ClrScr							; Main menu
		mGotoxy 0,0
		mWrite	"0) Encrypt/Decrypt a Text File [5000 BYTE MAX]"
		CALL	Crlf
		mWrite	"1) Exit Program"
		CALL	Crlf
		mWrite  "> "
		CALL	ReadChar						; Get Menu selection
		CALL	WriteChar
		CALL	Crlf
		CALL	Crlf
	ifEncryptText:
		CMP	AL, '0'
		JNE	ifEnd
		CALL	EncryptText
		JMP	loop_begin
	ifEnd:
		CMP	AL, '1'
		JNE	loop_begin
	loop_end:
		mWrite  "Program Terminated."
		mGotoxy 0,2
		INVOKE	ExitProcess, 0
ProgramLoop ENDP


EncryptText PROC
	mWrite  "To Decrypt a file, reopen previously encrypted file "
	mWrite  <"and use same encryption key.", 0dh, 0ah, 0dh, 0ah>
	mWrite	"Enter a File Name for Input File [Required to already exist]: "
	mReadString fileName
	MOV	EDX,OFFSET filename
	CALL	OpenInputFile							; Open user specified text file
	MOV	fileHandle, EAX
	CMP	EAX, INVALID_HANDLE_VALUE
	JNE	file_ok					
	mWrite	<"Unable to find this text file.", 0dh, 0ah>
	JMP	quit		

	file_ok:
		MOV	EDX, OFFSET buffer					; Read text file
		MOV	ECX, BUFFER_SIZE
		CALL	ReadFromFile
		MOV	bytesRead, EAX
		mWrite	"File size: "						; Print file size
		CALL	WriteDec
		mWrite  " BYTES"
		CALL	Crlf
		JNC	check_buffer_size			
		mWrite	"Error reading file. "	
		CALL	WriteWindowsMsg
		JMP	close_file
	check_buffer_size:
		CMP	EAX, BUFFER_SIZE				; Is the buffer big enough?
		JB	buf_size_ok				
		mWrite	<"Error: Buffer too small for the file", 0dh, 0ah>
		JMP	quit					
	buf_size_ok:	
		MOV	buffer[EAX], 0		
		mWrite	<"Original Buffer:", 0dh, 0ah, 0dh, 0ah>		; Prepare file for encryption
		MOV	EDX, OFFSET buffer
		CALL	WriteString
		CALL	Crlf
		mWrite  "Enter an Encryption Key [Single Character]: "		; Get Hex Encryption key
		CALL	ReadChar
		CALL	WriteChar
		MOV	DL, AL
		CALL	Crlf
		MOV	ESI, OFFSET buffer
		MOV	ECX, bytesRead
	encrypt:
		MOV	AL, BYTE PTR [ESI]				; XOR encrypt byte by byte
		XOR	AL, DL								
		MOV	BYTE PTR [ESI], AL
		INC	ESI
		LOOP	encrypt
	write_file:
		mWrite	"Enter a File Name for Output File: "
		mReadString outputFileName	
		MOV	EDX, OFFSET buffer
		CALL	WriteString
		CALL	Crlf
		MOV	EDX, OFFSET outputFileName
		CALL	CreateOutputFile					; Create user specified Output file
		PUSH	EAX
		MOV	EDX, OFFSET buffer
		MOV	ECX, bytesRead
		CALL	WriteToFile						; Write to Output file
		POP	EAX
		CALL	CloseFile
		CALL	Crlf
	close_file:
		MOV	EAX, fileHandle						; Close Output file
		CALL	CloseFile
		mWrite	"Written to "
		mWriteString outputFileName
	quit:
		CALL	Crlf
		CALL	WaitMsg
		RET
EncryptText ENDP


DrawTitleScreen PROC
	CALL	ClrScr
	mGotoxy 27,2
	mWrite	" __   ______  _____    ______                             _   "
	mGotoxy 27,3
	mWrite	" \ \ / / __ \|  __ \  |  ____|                           | |  "
	mGotoxy 27,4
	mWrite	"  \ V / |  | | |__) | | |__   _ __   ___ _ __ _   _ _ __ | |_ "
	mGotoxy 27,5
	mWrite	"   > <| |  | |  _  /  |  __| | '_ \ / __| '__| | | | '_ \| __|"
	mGotoxy 27,6
	mWrite	"  / . \ |__| | | \ \  | |____| | | | (__| |  | |_| | |_) | |_ "
	mGotoxy 27,7
	mWrite	" /_/ \_\____/|_|  \_\ |______|_| |_|\___|_|   \__, | .__/ \__|"
	mGotoxy 27,8
	mWrite	"                                               __/ | |        " 
	mGotoxy 27,9
	mWrite	"                                              |___/|_|        "
	mGotoxy 50, 20
	mWrite	"Barrett Otte 2017"
	mGotoxy 52, 22
	mWrite	"Assembly(x86)"
	mGotoxy 50, 23
	mWrite	"MASM and Irvine32"
	mGotoxy 45, 28
	INVOKE	Sleep, 200
	CALL	WaitMsg
	mGotoxy 0,0
	RET
DrawTitleScreen ENDP


END main
