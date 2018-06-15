section .data
	deltaX dd 0.0
	deltaY dd 0.0
	deltaErr dd 0.0
	err dd 0.0
	currY dd 0

	half dd 0.5


section .text
global bresenham

; eax points to the start position, ebx points to the end
; ecx points to a buffer
bresenham:
	push ebx
	call plot_point
	pop ebx
	mov eax, ebx
	call plot_point
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
