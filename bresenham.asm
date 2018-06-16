section .data
	deltaX dd 0.0
	deltaY dd 0.0
	deltaErr dd 0.0
	err dd 0.0
	currY dd 0
	deltaYSign dd 1
	
	startX dd 0
	endX dd 0

	half dd 0.5

	plotCoords dd 0, 0
	
	buffer dd 0

section .text
global bresenham

; eax points to the start position, ebx points to the end
; ecx points to a buffer
bresenham:
	pushad
	;jmp .test_plot
	
	mov [buffer], ecx

	call .compute_deltaX
	call .compute_deltaY
	call .compute_deltaYSign
	call .compute_deltaErr
	call .init_currY

	mov eax, [eax]
	mov [startX], eax
	mov ebx, [ebx]
	mov [endX], ebx

	mov ecx, [startX]              ; For x from x0 to x1
	cmp ecx, [endX]
	je .uhoh
	.line_loop:
		; plot (x,y)
		mov [plotCoords],   ecx
		mov ebx, [currY]
		mov [plotCoords+4], ebx
		mov eax, plotCoords
		push ecx
		mov ecx, [buffer]
		call plot_point
		pop ecx

		; error := error + deltaerr
		fld dword [err]
		fld dword [deltaErr]
		faddp
		fstp dword [err]
		
		.adjust_y: ; while error >= 0.5
			fld dword [half]
			fld dword [err]
			fcomp
			fstp st0
			fstsw ax
			fwait
			sahf
			jg .done_adjusting_y
			; y := y + sign(deltaY) * 1
			mov eax, [currY]
			add eax, [deltaYSign]
			mov [currY], eax

			; error := error - 1.0
			fld1
			fld dword [err]
			fsubp
			fstp dword [err]
		jmp .adjust_y
	.done_adjusting_y:
	inc ecx
	cmp ecx, [endX]
	jl .line_loop
	popad
	ret
	

.compute_deltaX:
	fild dword [eax]
	fild dword [ebx]
	fsubp
	fstp dword [deltaX]
	ret
.compute_deltaY:
	fild dword [eax+4]
	fild dword [ebx+4]
	fsubp
	fstp dword [deltaY]
	ret
.compute_deltaYSign:
	fld dword [deltaY]
	fld dword [deltaY]
	fabs
	fdivp
	fistp dword [deltaYSign]
	ret
.compute_deltaErr:
	fld dword [deltaX]
	fld dword [deltaY]
	fdivp
	fabs
	fstp dword [deltaErr]
	ret
.init_currY:
	push eax
	mov eax, [eax+4]
	mov [currY], eax
	pop eax
	ret

.test_plot:
	push ebx
	call plot_point
	pop ebx
	mov eax, ebx
	call plot_point
	ret

.uhoh:
	popad
	ret

; plot 2d vector in eax to buffer in ecx
plot_point:
	push eax
	mov eax, [eax+4]
	mov ebx, dword 81
	mul ebx
	pop dword ebx
	add eax, [ebx]
	add eax, ecx
	mov [eax], byte '$'
	ret

signum:
