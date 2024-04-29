.386P
.model flat

.data
prompt				byte	"First Value: ", 0		; ends with strin terminator (NULL or 0)
prompt2				byte	"Second Value: ", 0
results				byte	"You typed: ", 0
outputHandle		dword   ?						; Storage the the handle for input and output. uninitslized
written				dword   ?


