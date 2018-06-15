section .text
global bresenham

; eax points to the start position, ebx points to the end
; ecx points to a buffer
bresenham:
	push dword [ebx]
	push dword [ebx+4]
	push dword [eax]
	push dword [eax+4]

	pop dword eax
	mov ebx, dword 81
	mul ebx
	pop dword ebx
	add eax, ebx
	
	push ecx
	add ecx, eax
	mov [ecx], byte 's'
	pop ecx

	pop dword eax
	mov ebx, dword 81
	mul ebx
	pop dword ebx
	add eax, ebx

	push ecx
	add ecx, eax
	mov [ecx], byte 'e'
	pop ecx
	ret
