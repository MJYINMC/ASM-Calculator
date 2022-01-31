section .data
; 由于WSL无法使用int 80h中断,我只好调用libc的exit函数, 任务报告中加入了关闭程序的代码,求原谅
msg:db "Input a formula:", 0
out: db "=%hd ", 0 
format: db "%s", 0
formula: times 1000 db 0
transed: times 1000 dw 0
type: times 1000 db 0
section .text
	global main
	extern printf
	extern scanf
	extern exit
main:	
	mov ebp, esp
	push msg
	call printf
	add esp, 4 
	
	push formula
	push format
	call scanf
	add esp, 8
	mov ecx, 0
	xor edx, edx

judge:	; 判断该位为数字还是运算符
	xor eax, eax
	cmp [formula+ecx],byte 0
	je all_done
	cmp [formula+ecx], byte '/'
	ja digit

digit: ; 将字符形式的数字转换为真实的数字, 例如"123",经过处理后，ax = 123
	xor ebx, ebx
	mov bl, [formula+ecx]
	sub bl, '0'
	imul eax, eax, 10
	add eax, ebx
	inc ecx
	cmp [formula+ecx],byte '/'
	ja digit

a_digit_done:
	mov [transed+2*edx], ax; 存入数字
	mov [type+edx], byte 1; 标记该位为数字
	inc edx; 游标右移一位
	cmp [formula+ecx], byte 0
	je all_done
	cmp [formula+ecx], byte '*'; 高优先级运算符与低优先级运算符入栈处理规则不同
	je higher
	cmp [formula+ecx], byte '/'
	je higher
	cmp [formula+ecx], byte '%'
	je higher

lower: 
	cmp ebp, esp
	je push_op
	pop word [transed+2*edx]
	inc edx
	cmp [esp],word '+'
	je lower
	cmp [esp],word '-'
	je lower
	jmp push_op
higher:
	cmp [esp],word '*'
	je store
	cmp [esp],word '/'
	je store
	cmp [esp],word '%'
	je store
	jmp push_op; 栈顶优先级较低, 直接压栈
store: ; 栈顶操作符出栈，并存于转换后数组中
	pop word [transed+2*edx]
	inc edx
	jmp higher; 继续判断

push_op:; 将目前读入的操作符进行压栈
	xor ax, ax
	mov al, byte [formula + ecx]
	push ax
	inc ecx
	cmp [formula+ecx], byte 0; 还未结束, 判断下一位是数字还是操作符
	jne judge

all_done:
	cmp ebp, esp
	je clear
	pop word [transed+2*edx]
	inc edx
	jmp all_done
clear:	
	xor edx, edx
	xor eax, eax
start_cal:; 开始进行运算
	cmp [type+edx], byte 1
	je push_num
	mov cx, [transed+2*edx]
	cmp cx,  0
	je output
	cmp cx, '+'
	je cal_1
	cmp cx, '-'
	je cal_2
	cmp cx, '*'
	je cal_3
	cmp cx, '/'
	je cal_4
	cmp cx, '%'
	je cal_5
push_num:
	push word [transed+2*edx]
	inc edx
	jmp start_cal
cal_1:
	pop ax
	pop bx
	add ax, bx 
	push ax
	inc edx
	jmp start_cal
cal_2:
	pop ax
	pop bx
	sub bx, ax
	push bx
	inc edx 
	jmp start_cal
cal_3:
	pop ax
	pop bx
	push edx 
	mul bx
	pop edx
	push ax
	inc edx
	jmp start_cal
cal_4:	
	pop bx
	pop ax
	push edx
	xor edx, edx
	div bx
	pop edx
	push ax
	inc edx 
	jmp start_cal
cal_5:
	pop bx
	pop ax
	push edx
	xor edx, edx
	div bx
	mov ax, dx 
	pop edx
	push ax
	inc edx
	jmp start_cal
output:
	push out
	call printf
	add esp, 6
	call exit
