section .data
msg: db "Try to use this simple calculator:",0Ah,"Enter the whole Formula at one time:",0
inputFormula: db "%lf%c%lf",0
outputmsg: db "=%lf",0Ah,"Hex=",0
hexmsg: db "%x",0
endmsg : db 0Ah,0
left: dq 0
right: dq 0 
op: db 0
result dq 0
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
    fld qword [left]
    fld qword [right]
    xor ecx, ecx
    mov ecx, [op]
    cmp ecx, '+'
    je addSeg
    cmp ecx, '-'
    je subSeg
    cmp ecx, '*'
    je mulSeg
    cmp ecx, "%"
    fdiv
    fstp qword [result]
    jmp output

mulSeg:
    fmul
    fstp qword [result]
    jmp output

subSeg:
    fsub
    fstp qword [result]
    jmp output

addSeg:
    fadd 
    fstp qword [result]

output:
    push dword [result+4]
    push dword [result]
    push outputmsg
    call printf
    add esp, 12 
    push dword [result+4]
    push hexmsg
    call printf
    add esp, 8
    push dword [result]
    push hexmsg
    call printf
    add esp, 8 
    push endmsg
    call printf
    add esp, 4
    call exit
