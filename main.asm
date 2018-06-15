global _start

global DotProductOut

SCREEN_W equ 80
SCREEN_H equ 40
PIXEL_COUNT equ (SCREEN_W+1)*SCREEN_H ; +1 for newlines

section .bss
	RenderBuffer resb PIXEL_COUNT
	
section .data
	; I stole this code from here: https://stackoverflow.com/questions/30247644/clean-console-on-assembly
	; This is just a regular ordinary string containing an ANSI escape code.
	; ANSI escape codes are special strings that linux terminal apps interpret
	; as commands when printed to standard output. You can also get colored
	; output in linux terminals by using ANSI escape codes.
	;
	; Read more here: https://en.wikipedia.org/wiki/ANSI_escape_code
	ClearTerm	db 27,"[H",27,"[2J" ; <ESC> [H <ESC> [2J
	CLEARLEN 	equ $-ClearTerm ; Length of term clear string
	TestString	db "Hey babe"
	TESTLEN 	equ $-TestString ; Length of test string
	OneSixtiethSecond:
		tv_sec dd 0
		tv_nsec dd 16666666

	Acc db 0
	FuckingCube:
		vert_1 dd 0.0,0.0,0.0
		vert_2 dd 0.0,0.0,1.0
		vert_3 dd 0.0,1.0,0.0
		vert_4 dd 0.0,1.0,1.0
		vert_5 dd 1.0,0.0,0.0
		vert_6 dd 1.0,0.0,1.0
		vert_7 dd 1.0,1.0,0.0
		vert_8 dd 1.0,1.0,1.0
	VERTSIZE 	equ vert_8-vert_7
	WorldCube:
		w_vert_1 dd 0.0, 0.0, 0.0
		w_vert_2 dd 0.0, 0.0, 0.0
		w_vert_3 dd 0.0, 0.0, 0.0
		w_vert_4 dd 0.0, 0.0, 0.0
		w_vert_5 dd 0.0, 0.0, 0.0
		w_vert_6 dd 0.0, 0.0, 0.0
		w_vert_7 dd 0.0, 0.0, 0.0
		w_vert_8 dd 0.0, 0.0, 0.0
	RotationMatrix:
		dd 1.0, 0.0, 0.0
		dd 0.0, 0.0, 0.0
		dd 0.0, 0.0, 0.0

	DotProductOut dd 0
	
	TwoDIntVector dd 0, 0

	TheNumberFive   dd  5.00
	TheNumberTen    dd 10.00
	TenSqrtThree    dd 17.33
	TheNumberTwenty dd 20.00
	TheNumberThirty dd 30.00

	timer dd 0.0
	timestep dd 0.01

	neg1 dd -1.0

section .text
extern dot_product, rotate_vector
%include "mov_vector.mac"
	_start:
	jmp .main_loop
	
	; Linux syscall to `write`. Print the ClearTerm string to stdout.
	.clear_terminal:
	mov eax, 4
	mov ebx, 1
	mov ecx, ClearTerm
	mov edx, CLEARLEN
	int 80h
	ret
	
	; Sleep for 1/60 seconds!
	.sys_nanosleep:
	mov eax, 162
	mov ebx, OneSixtiethSecond
	mov ecx, 0
	int 80h
	ret
	
	.print_vertex_test:
	mov eax, 4
	mov ebx, 1
	mov ecx, vert_2
	mov edx, 16 ; a little more than the first vector
	int 80h
	ret

	.print_cube_rep:
	mov eax, 4
	mov ebx, 1
	mov ecx, RenderBuffer
	mov edx, PIXEL_COUNT
	int 80h
	ret

	; Didn't use a loop here because I'm too lazy
	.rotate_cube_step:
	mov ebx, RotationMatrix
	mov eax, vert_1
	mov ecx, w_vert_1
	call rotate_vector
	mov ebx, RotationMatrix
	mov eax, vert_2
	mov ecx, w_vert_2
	call rotate_vector
	mov ebx, RotationMatrix
	mov eax, vert_3
	mov ecx, w_vert_3
	call rotate_vector
	mov ebx, RotationMatrix
	mov eax, vert_4
	mov ecx, w_vert_4
	call rotate_vector
	mov ebx, RotationMatrix
	mov eax, vert_5
	mov ecx, w_vert_5
	call rotate_vector
	mov ebx, RotationMatrix
	mov eax, vert_6
	mov ecx, w_vert_6
	call rotate_vector
	mov ebx, RotationMatrix
	mov eax, vert_7
	mov ecx, w_vert_7
	call rotate_vector
	mov ebx, RotationMatrix
	mov eax, vert_8
	mov ecx, w_vert_8
	call rotate_vector
	ret

	.render_to_buffer:
	mov ecx, PIXEL_COUNT
	.render_loop:
	mov eax, ecx
	mov ebx, 81
	xor edx, edx
	div ebx
	cmp edx, 0
	je  .put_newline
	cmp edx, 1
	je .left_edge
	cmp edx, 80
	je .right_edge
	jmp .fill
	.put_newline:
	  mov ebx, RenderBuffer
	  add ebx, ecx
	  mov [ebx], byte 10
	jmp .loop_end
	.left_edge:
	  mov ebx, RenderBuffer
	  add ebx, ecx
	  mov [ebx], byte ' '
  	jmp .loop_end
	.right_edge:
	  mov ebx, RenderBuffer
	  add ebx, ecx
	  mov [ebx], byte ' '
	jmp .loop_end
	.fill:
       	  mov ebx, RenderBuffer
	  add ebx, ecx
          mov [ebx], byte ' '
	jmp .loop_end
	.loop_end:
	loop .render_loop
	; Okay now we want to draw the points.

	mov ecx, 84
	.draw_points_loop:
	mov eax, w_vert_1
	add eax, ecx
	mov ebx, TwoDIntVector
	call .project_vector
	mov ebx, RenderBuffer
	add ebx, [TwoDIntVector+4]
	mov eax, [TwoDIntVector]
	mov edx, 81
	mul edx
	add ebx, eax
	mov [ebx], byte '@'
	sub ecx, 12
	cmp ecx, 0
	jge .draw_points_loop
	ret
	
	.whatinthegoddamn:
	mov eax, 4
	mov ebx, 1
	mov ecx, TwoDIntVector
	mov edx, 8
	int 80h
	ret
	
	; Project a 3d floating vector (at eax) to a 2d int vector (at ebx)
	.project_vector:
	fld dword [eax+4]
	fmul dword [TheNumberTen]
	fadd dword [TheNumberTwenty]
	fistp dword [ebx]
	fld dword [eax+8]
	fmul dword [TheNumberTwenty]
	fadd dword [TheNumberThirty]
	fadd dword [TheNumberTen]
	fistp dword [ebx+4]
	ret

	.update_matrix:
	; increment timer by timestep
	fld dword [timer]
	fadd dword [timestep]
	fstp dword [timer]

	; write cosine entries to the matrix based on current time
	fld dword [timer]
	fcos
	fst  dword [RotationMatrix+16]
	fstp dword [RotationMatrix+32]

	; write sine entries to the matrix based on current time
	fld dword [timer]
	fsin
	fst  dword [RotationMatrix+28]
	fmul dword [neg1]
	fstp dword [RotationMatrix+20]
	ret

	.update_matrix_alt:
	fld dword [timer]
	fadd dword [timestep]
	fstp dword [timer]

	fld dword [timer]
	fcos
	fst dword [RotationMatrix]
	fst dword [RotationMatrix+16]

	fmul st0, st0
	fstp dword [RotationMatrix+32]

	fld dword [timer]
	fsin
	fst dword [RotationMatrix+8]
	fst dword [RotationMatrix+28]
	
	fmul st0, st0
	fstp dword [RotationMatrix+12]
	
	fld dword [timer]
	fsin
	fld dword [timer]
	fcos
	fmul
	fmul dword [neg1]
	fst dword [RotationMatrix+20]
	fst dword [RotationMatrix+24]
	ret
	
	.main_loop:
	call .sys_nanosleep
	call .clear_terminal
	call .rotate_cube_step
	call .update_matrix_alt
	call .render_to_buffer
	;call .whatinthegoddamn
	call .print_cube_rep
	jmp .main_loop
	
	; Exit syscall to signal the end of this process.
	.finish:
	mov eax, 1
	mov ebx, 0
	int 80h
