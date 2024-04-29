; Recursive Functions
; Robert Thompson
; 18 April 2024
; Most of the lines are the same, except for the end of the file
; When pasting the original code from D2L it returns a couple errors so I have to modify the code to work on my machine
; Any lines that have been changed, Ive added -Rob to the start of the line

; WINAPI DOCS
;
; 
;BOOL WINAPI WriteConsole(
;  _In_             HANDLE  hConsoleOutput,
;  _In_       const VOID    *lpBuffer,
;  _In_             DWORD   nNumberOfCharsToWrite,
;  _Out_opt_        LPDWORD lpNumberOfCharsWritten,
;  _Reserved_       LPVOID  lpReserved
;)
;
;
;
;
;


.386P

.model flat

extern  _GetStdHandle@4:near
extern  _ExitProcess@4: near
extern  _WriteConsoleA@20:near
extern  _ReadConsoleA@20:near


.data
invalidInputMsg		byte	'Invalid Input',0
operatorOutput		byte	'Operation Type: (1 = Addition | 2 = Subtraction | 3 = Multiplication | 4 = Division | 5 = Exponential): '
prompt				byte	"First Value: ", 0		; ends with strin terminator (NULL or 0)
prompt2				byte	"Second Value: ", 0
results				byte	"You typed: ", 0
outputHandle		dword   ?						; Storage the the handle for input and output. uninitslized
written				dword   ?

ADDITION			byte	"+",0
SUBTRACTION			byte	"-",0
MULTIPLICATION		byte	"*",0
DIVISION			byte	"/",0
EXPONTENTIAL		byte	"^",0

readBuffer			byte	1024		DUP(00h)
numCharsToRead		dword	1024
numCharsRead		dword	?
inputHandle			dword   ?

; Handles the operation, ie: addition, subtraction, mulitplication, etc..
firstCharsToRead	dword	1024
firstCharsRead		dword	?
firstReadBuffer		byte	1024		DUP(00h)
firstNum			dword	?

opCharsToRead		dword	1024
opCharsRead			dword	?
opReadBuffer		byte	1024		DUP(00h)
opNum				dword	?

secondCharsToRead	dword	1024
secondCharsRead		dword	?
secondReadBuffer	byte	1024		DUP(00h)
secondNum			dword	?



.code


main PROC near
_main:

    ; handle = GetStdHandle(-11)
    push    -11
    call    _GetStdHandle@4
    mov     outputHandle, eax

	call	getFirstInput			; Handles everything related to prompting the user input for the first number

	; Convert the first input into an integer, and move it into the firstNum value
	push	offset firstReadBuffer
	call	stringToInt				
	mov		firstNum, eax

	call	getSecondInput			

	push	offset secondReadBuffer
	call	stringToInt				
	mov		secondNum, eax

	call	getOperationInput		; Gets the operation value

	push	offset opReadBuffer
	call	stringToInt				
	mov		opNum, eax

	cmp		secondNum, 5			; Check if the operation value is less than 
	jg		invalidInput

	cmp		opNum, 1
	jl		invalidInput



	; ExitProcess(uExitCode)
	push	0
	call	_ExitProcess@4

main ENDP

writeline PROC near
_writeline:
		pop		eax									; pop the top element of the stack into eax

		pop		edx									; Pop ReadBuffer into edx
		pop		ecx									; Pop numCharsRead into ecx

		push	eax									; Push content of EAX onto the top of the stack.

        ; WriteConsole(handle, &msg[0], numCharsToWrite, &written, 0)
        push    0									; handle
        push    offset written						; &msg
        push    ecx									; return ecx to the stack for the call to _WriteConsoleA@20 (20 is how many bits are in the call stack)
        push    edx									; &written
        push    outputHandle						; output handle
        call    _WriteConsoleA@20					
		ret
writeline ENDP

readline PROC near
_readline: 
		; ReadConsole(handle, &buffer, numCharToRead, numCharsRead, null)
		push	0									; handle
		push	offset numCharsRead					; &buffer
		push	numCharsToRead						; numCharToRead
		push	offset readBuffer					; numCharsRead
		push	inputHandle							; 
		call	_ReadConsoleA@20
		ret
readline ENDP

stringToInt PROC
_stringToInt:
    ; Save the need information
    pop edx                     ; Save the current stack pointer
    pop ecx                     ; Save the address of the buffer with the number string
    push edx                    ; Restore stack pointer to the top of the stack.

    ; Take what was read and convert to a number
    mov   eax, 0                ; Initialize the number
    mov   ebx, 0                ; Make sure upper bits are all zero.
    
_findNumberLoop:
    mov   bl, [ecx]      ; Load the low byte of the EBX reg with the next ASCII character.
    cmp   bl, '9'               ; Make sure it is not too high
    jg   _endNumberLoop
    sub   bl, '0'               
    cmp   bl, 0                 ; or too low
    jl    _endNumberLoop
    mov   edx, 10              ; save multiplier for later need
    mul   edx
    add   eax, ebx
    inc   ecx                   ; Go to next location in number
    jmp   _findNumberLoop

 _endNumberLoop:
    ret                         ; EAX has the new integer when the code completes. And ) if no digits found.
 stringToInt ENDP

 ; Terminate the process with an error code of 1, signifying that an error occured
invalidInput PROC near
_invalidInput:
	push	0
	push	offset written
	push	13
	push	offset invalidInputMsg
	mov		eax, offset invalidInputMsg
	push	outputHandle
	call	_WriteConsoleA@20

	; ExitProcess(uExitCode)
	push	1
	call	_ExitProcess@4
invalidInput ENDP

doAddition PROC near
_doAddition:
	mov ecx, firstNum
	mov edx, 5

	add ecx, edx ; ecx contains return value
	ret
doAddition ENDP

getFirstInput PROC near
_getFirstInput:

	; WriteConsole(handle, &Prompt[0], 13, &written, 0)
	push	0
	push	offset written
	push	13
	push	offset prompt
	mov		eax, offset prompt
	push	outputHandle
	call	_WriteConsoleA@20

	; handle = GetStdHandle(-10) | Output -> Input
	push	-10
	call	_GetStdHandle@4					; Set the handle to accept input
	mov		inputHandle, eax				; Move the inputHandle to the eax register
	
	; ReadConsole(handle, &buffer, numCharToRead, numCharsRead, null)
	push	0									; handle
	push	offset firstCharsRead				; &buffer
	push	firstCharsToRead					; numCharToRead
	push	offset firstReadBuffer				; numCharsRead
	push	inputHandle							; 
	call	_ReadConsoleA@20
	ret

getFirstInput ENDP

getSecondInput PROC near
_getSecondInput:

	; WriteConsole(handle, &Prompt[0], 13, &written, 0)
	push	0
	push	offset written
	push	14
	push	offset prompt2
	mov		eax, offset prompt2
	push	outputHandle
	call	_WriteConsoleA@20
	
	; ReadConsole(handle, &buffer, numCharToRead, numCharsRead, null)
	push	0									; handle
	push	offset secondCharsRead				; &buffer
	push	secondCharsToRead					; numCharToRead
	push	offset secondReadBuffer				; numCharsRead
	push	inputHandle							; 
	call	_ReadConsoleA@20
	ret

getSecondInput ENDP

getOperationInput PROC near
_getOperationInput:

	; WriteConsole(handle, &Prompt[0], 13, &written, 0)
	push	0
	push	offset written
	push	104
	push	offset operatorOutput
	mov		eax, offset operatorOutput
	push	outputHandle
	call	_WriteConsoleA@20
	
	; ReadConsole(handle, &buffer, numCharToRead, numCharsRead, null)
	push	0									; handle
	push	offset opCharsRead				; &buffer
	push	opCharsToRead					; numCharToRead
	push	offset opReadBuffer				; numCharsRead
	push	inputHandle							; 
	call	_ReadConsoleA@20
	ret

getOperationInput ENDP


END