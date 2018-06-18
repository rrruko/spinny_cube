section .data
	buffer dd 0
	startX dd 0
	startY dd 0
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
bresenham:
	pushad
	mov [buffer], ecx
	mov ecx, [eax]
	mov [startX], ecx
	mov ecx, [eax+4]
	mov [startY], ecx
	mov ecx, [ebx]
	mov [endX], ecx
	mov ecx, [ebx+4]
	mov [endY], ecx
set_diffX_and_sx:
	mov eax, [endX]
	sub eax, [startX]
	jg .positive_sx
	.negative_sx:
		mov ebx, -1
		mov [sx], ebx
		jmp .proceed
	.positive_sx:
		mov ebx, 1
		mov [sx], ebx
	.proceed:
	call abs_val
	mov [diffX], eax
set_diffY_and_sy:
	mov eax, [endY]
	sub eax, [startY]
	jg .positive_sy
	.negative_sy:
		mov ebx, -1
		mov [sy], ebx
	.positive_sy:
		mov ebx, 1
		mov [sy], ebx
	.proceed:
	call abs_val
	mov [diffY], eax
set_err:
	mov eax, [diffX]
	sub eax, [diffY]
	jc .err_is_neg_diffY
	.err_is_diffX:
		mov eax, [diffX]
		mov [err], eax
		jmp .proceed
	.err_is_neg_diffY:
		xor eax, eax
		sub eax, [diffY]
		mov [err], eax
	.proceed:
	mov eax, [err]
	mov ebx, 2
	xor edx, edx
	div ebx
line_loop:
	; setPixel(x0, y0)
	mov eax, [startX]
	mov ebx, [startY]
	call set_pixel
	;jmp .break
	
	; if (x0 == x1 && y0 == y1) break
	mov eax, [startX]
	sub eax, [endX]
	mov ebx, [startY]
	sub ebx, [endY]
	or eax, ebx
	cmp eax, 0
	je .break

	; wtf
	mov eax, [startX]
	cmp eax, 0
	jl .break
	cmp eax, 80
	jg .break
	mov eax, [startY]
	cmp eax, 0
	jl .break
	cmp eax, 40
	jg .break

	; e2 = err
	mov eax, [err]
	mov [e2], eax

	mov eax, [e2]
	mov ebx, [diffX]
	neg ebx
	sub eax, ebx
	jg .e2_gt_neg_diffX ; Do i need to return back here?
	.e2_gt_neg_diffX_return:
	mov eax, [e2]
	sub eax, [diffY]
	jl .e2_less_diffY ; Do i need to return back here?
	.e2_less_diffY_return:
	jmp line_loop

	.e2_gt_neg_diffX:
	mov eax, [err]
	sub eax, [diffY]
	mov [err], eax

	mov eax, [startX]
	add eax, [sx]
	mov [startX], eax
	jmp .e2_gt_neg_diffX_return

	.e2_less_diffY:
	mov eax, [err]
	add eax, [diffX]
	mov [err], eax

	mov eax, [startY]
	add eax, [sy]
	mov [startY], eax
	jmp .e2_less_diffY_return

	.break:
	popad
	ret

; eax: x-coord, ebx: y-coord
set_pixel:
	pushad
	xchg eax, ebx
	mov ecx, dword 81
	xor edx, edx
	mul ecx
	add eax, ebx
	add eax, [buffer]
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
