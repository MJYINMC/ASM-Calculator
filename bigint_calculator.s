section .data
left: times 50 db 0
right: times 50 db 0
answer: times 100 dw 0 ; 乘法运算中，有可能出现某一项的数字大于255的情况，使用双字
tmp: times 100 dw 0 ;除法运算中储存中间结果
llen: dw 0 ; 左操作数的原长度
rlen: dw 0 ; 右操作数的原长度
flexlen: dw 0 ; 在进行除法过程中, 对右操作数假想的长度
alen: dw 0 ; answer的长度
tlen: dw 0 ; tmp的长度
totallen: dw 0; totallen = llen + rlen
op: times 2 db 0 ; 存放运算符号
string: db "%s", 0
char: db "%c", 0
msg1: db "Input Left:", 0
msg2: db "Input Operator:", 0
msg3: db "Input Right:", 0

section .text 
	extern printf
	extern scanf 
	extern exit
	global main
main:; 输入运算数和操作符，之后按照操作符跳转到不同功能
	push msg1
	call printf
	add esp, 4
	
	push left
	push string
	call scanf 
	add esp, 8
	xor ecx, ecx
	mov ebx, left
	mov edx, llen
	call process
	
	push msg2
	call printf
	add esp, 4

	push op
	push string
 	call scanf
	add esp, 8
	
	push msg3
	call printf
	add esp, 4
	
	push right
	push string
	call scanf 
	add esp, 8
	mov ebx, right
	xor ecx, ecx
	mov edx, rlen
	call process
	call setMaxlen
	
	xor ecx, ecx
	cmp [op],byte '+'
	je cal_1
	cmp [op],byte '-'
	je cal_2
	cmp [op],byte '*'
	je cal_3
	cmp [op],byte '/'
	je cal_4
	cmp [op],byte '%'
	je cal_5


process:; 对输入的数字处理，去掉括号并统计长度
	cmp [ebx+ecx], byte 0
	je done
	sub [ebx+ecx], byte '0'
	inc ecx
	jmp process
done:
	mov [edx], ecx
	ret

setMaxlen:; 对结果设置长度，最大的可能是两个操作数位数和+1
	mov ax, [llen]
	add ax, [rlen]
	mov [totallen], ax
	inc ax
	mov [alen], ax
	mov [tlen], ax
	ret

print_bigint:; ebx =  bigint , dx = [len]
	dec edx
	cmp edx, 0
	jl end_print
	push edx
	xor ax, ax
	mov ax, [ebx+2*edx]
	add ax, '0'
	push ax
	push char
	call printf
	add esp, 6
	pop edx
	jmp print_bigint
	
end_print:
	push word 0Ah
	push char 
	call printf
	add esp, 6
	ret

format_bigint:; ebx = bigint, edi = len, ecx = 0 ,dx = [len]，
	cmp ecx,edx	
	je check_len
	cmp [ebx+2*ecx], word 0  
	jl less
	cmp [ebx+2*ecx], word 10
	jge greater
	inc ecx
	jmp format_bigint

greater:
	mov ax, [ebx+2*ecx]
	push edx
	xor dx, dx 
	mov dl, 10 
	div dl 
	mov dl, ah
	and ax, 00FFh
	mov [ebx+2*ecx], dx
	add [ebx+2*ecx+2], ax
	pop edx
	inc ecx
	jmp format_bigint   

less:
	add [ebx+2*ecx],word 10
	sub [ebx+2*ecx+2],word 1
	inc ecx
	jmp format_bigint

check_len:
	cmp [ebx+2*ecx],word 0; 数组高位存放bigint高位,因此从高位向低位遍历,一旦出现不为0的数字,则一定是bigint的最高位数字
	jne end_format
	cmp cx, 0; 说明bigint的所有位数均为0,因此bigint = 0，此时不能再dec cx直接跳转到结束语句
	je end_format
	dec ecx
	jmp check_len	

end_format:; 完成格式化bigint，并保存其长度
	inc ecx
	mov [edi], cx
	ret 

cal_1:; 完成加法功能
	mov ebx, answer
	mov cx, [llen]
	xor eax, eax
	xor edx, edx
	call copy
	mov cx, [rlen]
	xor eax, eax
	xor edx, edx
	call funcAdd
	jmp output	

cal_2:; 完成减法功能
	mov ebx, answer
	mov cx, [llen]
	xor eax, eax
	xor edx, edx
	call copy
	mov cx, [rlen]
	xor eax, eax
	xor edx, edx
	call funcSub
	jmp output

cal_3:; 完成乘法功能
	mov cx, [llen]
	mov dx, [rlen]
	call funcMul
	jmp output

cal_4:; 完成除法功能
	mov ax, [llen]
	cmp ax, [rlen]
	jb output
	ja l_bigger
	xor ecx, ecx
	call compare
	cmp ax, 0	
	jl output
	; 以上均为被除数小于除数
	jae l_bigger

cal_5:; 完成取余功能
	mov ax, [llen]
	cmp ax, [rlen]
	jb divisor_lager
	ja l_bigger
	xor ecx, ecx
	call compare
	cmp ax, 0
	jl divisor_lager
	; 以上均为被除数小于除数
	je output; 相等,REM = 0,直接输出
	ja l_bigger


l_bigger:; 左操作数更大
	call div_pre_process
	call funcDiv
	cmp [op], byte '/'
	je output; 除法运算直接输出除法结果
	mov ebx, tmp
	xor edx, edx
	xor ecx, ecx
	mov dx, [tlen]
	mov edi, tlen
	call format_bigint
	mov dx, [tlen]
	call print_bigint
	call exit; 取余运算输出残余的tmp

div_pre_process:
	mov ebx, tmp
	xor eax, eax
	xor edx, edx
	mov cx, [llen]
	call copy ; 拷贝
	mov ebx, tmp
	xor edx, edx
	xor ecx, ecx
	mov dx, [tlen]
	mov edi, tlen
	call format_bigint ; 格式化
	mov ax, [tlen]
	mov [flexlen], ax ; 提升
	ret

divisor_lager:
	mov ebx, answer
	xor eax, eax
	xor edx, edx
	mov cx, [llen]
	call copy
	jmp output

compare:; cx = 0,ax为返回值,当ax=-1是代表左操作数小于右边,ax=0代表等于,ax=1代表大于
	cmp cx, [llen]
	je equal
	xor ax, ax
	mov al, [left+ecx]
	cmp al, [right+ecx]
	jb smaller
	ja bigger
	inc cx
	jmp compare

bigger:
	mov ax, 1
	ret

equal:
	mov ax, 0
	ret

smaller:
	mov ax, -1
	ret

copy:; ebx = bigint, eax =0 , edx = 0 , cx = [llen]
	cmp cx, 0
	je copy_done
	mov al, [left+ecx-1]
	mov [ebx+2*edx], ax
	inc edx
	dec cx
	jmp copy

copy_done:
	ret 

funcAdd:
	cmp cx, 0
	je add_done
	mov al,[right+ecx-1]
	add [ebx+2*edx], ax
	inc edx
	dec cx
	jmp funcAdd

add_done:
	ret 

funcSub:; ebx= bigint, cx= [rlen], edx=0
	cmp cx, 0
	je sub_done
	mov al, [right+ecx-1]
	sub [ebx+2*edx], ax
	inc edx
	dec cx
	jmp funcSub

sub_done:
	ret

funcMul:
	cmp cx, 0
	je mul_done
	xor edx, edx
	mov dx, [rlen]

inner:; 嵌套循环的内层
	cmp dx, 0
	je inner_done
	xor ax, ax
	xor bx, bx
	mov al, [left+ecx-1]
	mov bl, [right+edx-1]
	mul bl
	push cx;
	push dx; 保护寄存器的值
	neg cx;
	neg dx;对cx和dx取补, 即转为对应的负数
	add cx, [totallen]
	add cx, dx; 即任务报告中的 cx = llen + rlen - i + j
	add [answer+2*ecx], ax
	pop dx
	pop cx; 恢复寄存器的值, 继续计数
	dec dx
	jmp inner

inner_done:
	dec cx
	jmp funcMul

mul_done:
	ret

funcDiv:
	xor ecx, ecx
	mov dx, [tlen]
	call div_compare
	cmp ax, 0
	jl  divisor_too_big
	jae div_sub   

div_compare:; cx = 0 , dx =[tlen]
	mov ax, [tlen]
	cmp ax, [flexlen]
	jb smaller
	je div_len_equal
	ja bigger

div_len_equal:
	cmp ecx, edx
	je equal
	xor ax, ax 
	mov al, [right+ecx]
	mov ebx, edx
	sub ebx, ecx; ebx = edx - ecx,从高位开始比较
	cmp ax, word [tmp+2*ebx-2]
	jb bigger
	ja smaller
	inc ecx
	jmp div_len_equal

divisor_too_big:
	sub word [flexlen], 1
	mov cx, [rlen]
	cmp cx, [flexlen]
	ja div_done
	jmp funcDiv

div_sub:
	mov ebx, tmp
	mov cx, [flexlen]; 减数按照调整后的位数算
	xor edx, edx
	call funcSub; 做减法
	
	mov ebx, tmp
	xor edx, edx
	xor ecx, ecx
	mov dx, [tlen]
	mov edi, tlen
	call format_bigint; 格式化tmp
	
	mov cx, [flexlen]
	sub cx, [rlen]
	add [answer+2*ecx],word 1
	jmp funcDiv

div_done:
	ret

output:; 输出answer
	mov ebx, answer
	xor edx, edx
	xor ecx, ecx
	mov dx, [alen]
	mov edi, alen
	call format_bigint
	mov dx, [alen]
	call print_bigint
	call exit
