section .text
global dot_product, rotate_vector
extern DotProductOut

; Vectors in eax and ebx as 32-bit float arrays.
dot_product:
        fld  dword [eax]
        fmul dword [ebx]
        fld  dword [eax+4]
	fmul dword [ebx+4]
	fld  dword [eax+8]
	fmul dword [ebx+8]
	fadd
	fadd
	fstp dword [DotProductOut]
	ret

; Vector in eax, 3x3 matrix in ebx, pointer to output in ecx.
rotate_vector:
	call dot_product
	mov edx, [DotProductOut]
	mov [ecx], edx
	add ebx, 12
	call dot_product
	mov edx, [DotProductOut]
	mov [ecx+4], edx
	add ebx, 12
	call dot_product
	mov edx, [DotProductOut]
	mov [ecx+8], edx
	ret
