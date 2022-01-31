section .data
msg: db "Try to use this simple calculator:",0Ah,"Enter the whole Formula at one time:",0
inputFormula: db "%hd%c%hd",0
outputmsg: db "=%d",0Ah,0
left: dw 0
right: dw 0 
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

    mov ax, [left]
    mov bx, [right]
    xor ecx, ecx
    xor edx, edx
    mov ecx, [op]
    cmp ecx, '+'
    je addSeg
    cmp ecx, '-'
    je subSeg
    cmp ecx, '*'
    je mulSeg
    xor dx,dx
    idiv bx
    cmp ecx, "%"
    je remSeg
    cwd
    jmp output

remSeg:
    mov ax, dx
    cwd
    jmp output

mulSeg:
    imul bx
    jmp output

subSeg:
    sub ax, bx
    cwd
    jmp output

addSeg:
    add ax, bx
    cwd

output:
    push dx
    push ax
    push outputmsg
    call printf
    add esp, 6
    call exit
