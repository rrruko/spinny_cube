section .data
	buffer dd 0
	currX dd 0
	currY dd 0
	endX dd 0
	endY dd 0
	diffX dd 0
	diffY dd 0
	sx dd 0
	sy dd 0
	err dd 0
	e2 dd 0

section .text
global bresenham

; eax points to the start position, ebx points to the end
; ecx points to a buffer
; 
; I ported this procedure I found on Rosetta Code from C to x86
bresenham:
	pushad
	mov [buffer], ecx
	mov ecx, [eax]
	mov [currX], ecx
	mov ecx, [eax+4]
	mov [currY], ecx
	mov ecx, [ebx]
	mov [endX], ecx
	mov ecx, [ebx+4]
	mov [endY], ecx

set_diffX_and_sx:
	mov eax, [endX]
	sub eax, [currX]
	mov ebx, 1
	jg .proceed
	neg ebx
	.proceed:
	mov [sx], ebx
	call abs_val
	mov [diffX], eax
set_diffY_and_sy:
	mov eax, [endY]
	sub eax, [currY]
	mov ebx, 1
	jg .proceed
	neg ebx
	.proceed:
	mov [sy], ebx
	call abs_val
	mov [diffY], eax
set_err:
	mov eax, [diffX]
	cmp eax, [diffY]
	jg .err_is_diffX
		mov eax, [diffY]
		neg eax
		jmp .proceed
	.err_is_diffX:
		mov eax, [diffX]
	.proceed:
	mov ebx, 2
	cdq
	idiv ebx
	mov [err], eax
line_loop:
	; setPixel(x0, y0)
	mov eax, [currX]
	mov ebx, [currY]
	call set_pixel

	; if (x0 == x1 && y0 == y1) break
	mov eax, [endX]
	sub eax, [currX]
	jnz .nvm
	mov ebx, [endY]
	sub ebx, [currY]
	jz .break
	.nvm:

	; e2 = err
	mov eax, [err]
	mov [e2], eax

	mov eax, [e2]
	mov ebx, [diffX]
	neg ebx
	cmp eax, ebx
	jg .e2_gt_neg_diffX
	.e2_gt_neg_diffX_return:
	mov eax, [e2]
	cmp eax, [diffY]
	jl .e2_less_diffY
	.e2_less_diffY_return:
	jmp line_loop
.e2_gt_neg_diffX:
	mov eax, [err]
	sub eax, [diffY]
	mov [err], eax

	mov eax, [currX]
	add eax, [sx]
	mov [currX], eax
	jmp .e2_gt_neg_diffX_return
.e2_less_diffY:
	mov eax, [err]
	add eax, [diffX]
	mov [err], eax

	mov eax, [currY]
	add eax, [sy]
	mov [currY], eax
	jmp .e2_less_diffY_return
.break:
	popad
	ret

; eax: x-coord, ebx: y-coord
set_pixel:
	pushad
	xchg eax, ebx                  ; eax = ycoord, ebx = xcoord
	mov ecx, 81                    ; ecx = 81
	xor edx, edx                   ; edx = 0
	mul ecx                        ; eax = ycoord*81
	add eax, ebx                   ; eax = ycoord*81 + xcoord
	add eax, [buffer]              ; eax = buffer + ycoord*81+xcoord
	mov [eax], byte '@'
	popad
	ret

abs_val:
	cmp eax, 0
	jl .is_negative
	ret
	.is_negative:
	neg eax
	ret
