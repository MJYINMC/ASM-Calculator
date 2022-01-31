section .data
msg: db "Try to use this simple calculator:",0Ah,"Enter the whole Formula at one time:",0
inputFormula: db "%d%c%d",0
outputmsg: db "=%d",0Ah,0
left: dd 0
right: dd 0 
op: db 0
section .text
	extern printf
	extern scanf
	extern exit
	global main
main:
    push msg
    call printf
    add esp, 4

input:
    push right
    push op
    push left
    push inputFormula
    call scanf
    add esp, 16

    mov eax, [left]
    mov ebx, [right]
    xor ecx, ecx
    mov ecx, [op]
    cmp ecx, '+'
    je addSeg
    cmp ecx, '-'
    je subSeg
    cmp ecx, '*'
    je mulSeg
    xor edx, edx
    div ebx
    cmp ecx, "%"
    je remSeg
    jmp output

remSeg:
    mov eax, edx
    jmp output

mulSeg:
    mul ebx
    jmp output

subSeg:
    sub eax, ebx
    jmp output

addSeg:
    add eax, ebx

output:
    push eax
    push outputmsg
    call printf
    add esp, 8
    call exit
