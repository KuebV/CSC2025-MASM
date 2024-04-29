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
operatorOutput		byte	'Operation Type: (+ = Addition | - = Subtraction | * = Multiplication | / = Division | ^ = Exponential): '
prompt				byte	"First Value: ", 0		; ends with strin terminator (NULL or 0)
prompt2				byte	"Second Value: ", 0
results				byte	"Output: ", 0
outputHandle		dword   ?						; Storage the the handle for input and output. uninitslized
written				dword   ?

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

count				dword	0
countDown			dword	?
wBIndex				dword	?
writeBuffer			byte	1024		DUP(00h)


.code


main PROC near
_main:

    ; handle = GetStdHandle(-11)
    push    -11
    call    _GetStdHandle@4
    mov     outputHandle, eax

	call	getFirstInput			; First input is now contained in firstNum
	call	getSecondInput			; Second input is now contained in the secondNum
	call	getOperationInput		; Prompts the user for the operation type, then converts it into its ASCII value. The value is contained in the bl register

	cmp		bl, 42
	jl		invalidInput

	; Exponential
	cmp		bl, 94
	je		doExponential

	; Multiplication
	cmp		bl, 42
	je		doMultiplication

	; Addition
	cmp		bl, 43
	je		doAddition

	; Subtraction
	cmp		bl, 45
	je		doSubtraction
	
	; Division
	cmp		bl, 47
	je		doDivision

	jmp invalidInput				; Acts as the else statement, if it goes through everything else

main ENDP

getResult PROC near
_getResult:
	
	mov		firstNum, eax									; Push the return pointer back to the top

	; WriteConsole(handle, &Prompt[0], 13, &written, 0)
	push	0
	push	offset written
	push	8
	push	offset results
	mov		eax, offset results
	push	outputHandle
	call	_WriteConsoleA@20

	push	firstNum
	call	writeInt
	
	push	0
	call	_ExitProcess@4

getResult ENDP

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

writeInt PROC near
_writeInt:
            pop ebx                         ; Save the return address
            pop eax                         ; Save first number to convert in register EAX
            push ebx                        ; Restore return address, this frees up EBX for use here.
            mov count, 0                    ; Reset count
_convertLoop:
            ; Find the remainder and put on stack
            ; The choices are div for 8-bit division and idiv for 64-bit division. To use full registers, I had to use 64-bit division
            mov  edx, 0                     ; idiv starts with a 64-bit number in registers edx:eax, therefore I zero out edx.
            mov  ebx, 10                    ; Divide by 10.
            idiv ebx
            add  edx,'0'                    ; Make remainder into a character
            push edx                        ; Put in on the stack for printing this digit
            inc  count
            cmp  eax, 0
            jg   _convertLoop               ; Go back if there are more characters
            mov  wBIndex, offset writeBuffer
            mov   ebx, wBIndex
            mov  byte ptr [ebx], ' '        ; Add starting blank space
            inc  ebx                        ; Go to next byte location
            mov   ecx, count                ; EBX is being reloading each divide, so I can use it here to
            mov   countDown, ecx            ; transfer value to set up counter to go through all numbers
_fillString:
            pop   eax                       ; Remove the first stacked digit
            mov  [ebx], al                  ; Write it in the array
            dec   countDown
            inc  ebx                        ; Go to next byte location
            cmp   countDown, 0
            jg   _fillString
            mov  byte ptr[ebx], 0           ; Add end zero
            inc  count                      ; Take into account extra space
            push count                      ; How many characters to print
            push offset writeBuffer         ; And the buffer itself
            call writeline

            ret                             ; And return
writeInt ENDP

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

	push	offset firstReadBuffer
	call	stringToInt				
	mov		firstNum, eax

	ret	; Returns the flow of the program back to main

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

	push	offset secondReadBuffer
	call	stringToInt				
	mov		secondNum, eax

	ret ; Returns the flow of the program back to main

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
	
	mov		bl, [opReadBuffer]
	ret

getOperationInput ENDP

;-------------------------------------------------------------;
;	Contains all the functions for the calculations			  ;
;	This includes Addition, Subtraction,					  ;
;   multiplication, division, and exponential numbers		  ;
;-------------------------------------------------------------;
doAddition PROC near
_doAddition:
	mov eax, firstNum
	mov edx, secondNum

	add eax, edx
	call	getResult
doAddition ENDP

doSubtraction PROC near
_doSubtraction:
	mov eax, firstNum
	mov edx, secondNum

	sub eax, edx
	call	getResult
doSubtraction ENDP

doMultiplication PROC near
_doMultiplication:
	mov eax, firstNum
	mov edx, secondNum

	imul eax, edx
	call	getResult
doMultiplication ENDP

; Division is slightly different than the rest of the instructions
; Quotient  is placed in EAX
; Remainder is placed in EDX
doDivision PROC near
_doDivision:
	mov		eax, firstNum
	cdq
	mov		ebx, secondNum
	idiv secondNum
	
	call	getResult
doDivision ENDP

doExponential PROC near
_doExponential:
	mov eax, firstNum
	mov edx, secondNum
	mov ebx, firstNum ; EBX acts as a constant
_iteration:
	imul eax, ebx 
	dec edx

	cmp edx, 1
	jle _endExponentLoop

	jmp _iteration
	
_endExponentLoop:
	call getResult

doExponential ENDP

END