global _start

global DotProductOut

SCREEN_W equ 81 ; 80 printable chars + 1 newline per row
SCREEN_H equ 40
PIXEL_COUNT equ SCREEN_W*SCREEN_H

section .bss
	RenderBuffer resb PIXEL_COUNT

section .data
	; I stole the code for ClearTerm from here: https://stackoverflow.com/questions/30247644/clean-console-on-assembly
	;
	; This is just a regular ordinary string containing an ANSI escape
	; code. ANSI escape codes are special strings that linux terminal apps
	; interpret as commands when printed to standard output. You can also
	; get colored output in linux terminals by using ANSI escape codes.
	;
	; Read more here: https://en.wikipedia.org/wiki/ANSI_escape_code

	ClearTerm	db 27,"[H",27,"[2J" ; <ESC> [H <ESC> [2J
	CLEARLEN 	equ $-ClearTerm ; Length of term clear string

	; Struct used by sleep system call
	OneSixtiethSecond:
		tv_sec dd 0
		tv_nsec dd 16666666

	; The cube's object coordinates,
	; which should never be mutated
	FuckingCube:
		vert_0 dd -0.8, -0.8, -0.8
		vert_1 dd -0.8, -0.8,  0.8
		vert_2 dd -0.8,  0.8, -0.8
		vert_3 dd -0.8,  0.8,  0.8
		vert_4 dd  0.8, -0.8, -0.8
		vert_5 dd  0.8, -0.8,  0.8
		vert_6 dd  0.8,  0.8, -0.8
		vert_7 dd  0.8,  0.8,  0.8
	VECTOR_SIZE 	equ vert_7-vert_6

	; The cube's world coordinates
	; These are computed from the object coordinates each frame
	WorldCube:
		w_vert_0 dd 0.0, 0.0, 0.0
		w_vert_1 dd 0.0, 0.0, 0.0
		w_vert_2 dd 0.0, 0.0, 0.0
		w_vert_3 dd 0.0, 0.0, 0.0
		w_vert_4 dd 0.0, 0.0, 0.0
		w_vert_5 dd 0.0, 0.0, 0.0
		w_vert_6 dd 0.0, 0.0, 0.0
		w_vert_7 dd 0.0, 0.0, 0.0

	CubeEdges:
		dd 0, 1
		dd 1, 3
		dd 2, 0
		dd 3, 2

		dd 4, 5
		dd 5, 7
		dd 6, 4
		dd 7, 6

		dd 0, 4
		dd 1, 5
		dd 2, 6
		dd 3, 7

	 	EDGES_END  equ $
		EDGE_COUNT equ 12
		EDGE_SIZE  equ 8

	; These entries get filled in when the matrix update proc is called
	RotationMatrix:
		dd  1.0,  0.0,  0.0
		dd  0.0,  0.0,  0.0
		dd  0.0,  0.0,  0.0

	DotProductOut dd 0

	TwoDIntVector dd 0, 0

	TheNumberTwo    dd  2.00
	TheNumberFive   dd  5.00
	TheNumberTen    dd 10.00
	TenSqrtThree    dd 17.33
	TheNumberTwenty dd 20.00
	TheNumberForty  dd 40.00

	timer dd 0.0
	timestep dd 0.025

	neg1 dd -1.0

	bumbo1 dd 0, 0
	bumbo2 dd 79, 3

	projection_thingy dd 10.0

	NaNTest dd 0.0

section .text
extern dot_product, rotate_vector, bresenham
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
	mov eax, vert_0
	mov ecx, w_vert_0
	call rotate_vector
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
	ret

	.render_to_buffer:
	mov ecx, PIXEL_COUNT
	.render_loop:                  ; Write a background to the buffer
	mov eax, ecx                   ; (all ' ' spaces)
	mov ebx, SCREEN_W              ; while also inserting newlines each row
	xor edx, edx
	div ebx
	cmp edx, 0
	je  .put_newline
	cmp edx, 1
	je .left_edge
	cmp edx, (SCREEN_W-1)
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

	mov ecx, (EDGES_END-EDGE_SIZE)
	.draw_edges_loop:
	  mov eax, [ecx]
	  mov ebx, VECTOR_SIZE
	  mul ebx
	  add eax, w_vert_0
	  mov ebx, TwoDIntVector
	  call .project_vector
	  mov eax, bumbo1
	  mov edx, [ebx]
	  mov [eax], edx
	  add eax, 4
	  mov edx, [ebx+4]
	  mov [eax], edx
	  mov eax, [ecx+4]
	  mov ebx, VECTOR_SIZE
	  mul ebx
	  add eax, w_vert_0
	  mov ebx, TwoDIntVector
	  call .project_vector
	  mov eax, bumbo2
	  mov edx, [ebx]
	  mov [eax], edx
	  add eax, 4
	  mov edx, [ebx+4]
	  mov [eax], edx

	  push ecx
	  mov eax, bumbo1
	  mov ebx, bumbo2
	  mov ecx, RenderBuffer
	  call bresenham
	  pop ecx

	sub ecx, EDGE_SIZE
	cmp ecx, CubeEdges
	jge .draw_edges_loop

	ret

	; Project a 3d floating vector (at eax) to a 2d int vector (at ebx)
	.project_vector:
	push ecx

	fld dword [TheNumberTwo]
	fadd dword [eax]
	fstp dword [projection_thingy]

	; Shrink the vertical axis by half since terminal characters aren't
	; squares
	fld dword [eax+8]
	fmul dword [TheNumberTen]
	fdiv dword [projection_thingy]
	fadd dword [TheNumberTwenty]
	fistp dword [ebx+4]

	fld dword [eax+4]
	fmul dword [TheNumberTwenty]
	fdiv dword [projection_thingy]
	fadd dword [TheNumberForty]
	fistp dword [ebx]

	pop ecx
	ret

	; This constructs a matrix that rotates a
	; vector by (timer) radians along the X and Y axes.
	.update_matrix:
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
	fstp dword [RotationMatrix+24]
	ret

	.main_loop:
	call .sys_nanosleep
	call .clear_terminal
	call .rotate_cube_step
	call .update_matrix
	call .render_to_buffer
	call .print_cube_rep
	jmp .main_loop

	; Exit syscall to signal the end of this process.
	.finish:
	mov eax, 1
	mov ebx, 0
	int 80h
