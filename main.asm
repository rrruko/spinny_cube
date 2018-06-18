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
	ObjectCube:
		vert_0 dd -0.8, -0.8, -0.8
		vert_1 dd -0.8, -0.8,  0.8
		vert_2 dd -0.8,  0.8, -0.8
		vert_3 dd -0.8,  0.8,  0.8
		vert_4 dd  0.8, -0.8, -0.8
		vert_5 dd  0.8, -0.8,  0.8
		vert_6 dd  0.8,  0.8, -0.8
		vert_7 dd  0.8,  0.8,  0.8
	VECTOR_SIZE 	equ vert_7-vert_6
	OBJECT_CUBE_END equ $

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
	WORLD_CUBE_END equ $

	CubeEdges:
		dd 0, 1                ; Front face edges
		dd 1, 3
		dd 2, 0
		dd 3, 2

		dd 4, 5                ; Back face edges
		dd 5, 7
		dd 6, 4
		dd 7, 6

		dd 0, 4                ; Middle edges
		dd 1, 5
		dd 2, 6
		dd 3, 7

	 	EDGES_END  equ $
		EDGE_COUNT equ 12
		EDGE_SIZE  equ 8

	; These entries get filled in when the matrix update proc is called
	RotationMatrix:
		dd  0.0,  0.0,  0.0
		dd  0.0,  0.0,  0.0
		dd  0.0,  0.0,  0.0

	DotProductOut dd 0

	TwoDIntVector dd 0, 0

	TheNumberTwo    dd  2.00
	TheNumberTen    dd 10.00
	TheNumberTwenty dd 20.00
	TheNumberForty  dd 40.00

	timer dd 0.0
	timestep dd 0.025

	neg1 dd -1.0

	StartVector dd 0, 0
	EndVector   dd 0, 0

	ProjectionThingy dd 0.0

	xOffs dd 0.0
	yOffs dd 0.0
	zOffs dd 0.0

section .text
extern dot_product, rotate_vector, bresenham
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

	.rotate_cube_step:
	mov eax, ObjectCube
	mov ecx, WorldCube
	.loop_rotate_each_vert:
	mov ebx, RotationMatrix        ; Need to repeatedly set ebx
	call rotate_vector             ;   since rotate_vector mutates it
	add ecx, VECTOR_SIZE
	add eax, VECTOR_SIZE
	cmp eax, OBJECT_CUBE_END
	jl .loop_rotate_each_vert
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
	jmp .fill
	.put_newline:
	  mov ebx, RenderBuffer
	  add ebx, ecx
	  mov [ebx], byte 10
	jmp .loop_end
	.fill:
       	  mov ebx, RenderBuffer
	  add ebx, ecx
          mov [ebx], byte ' '
	jmp .loop_end
	.loop_end:
	loop .render_loop

	; Okay now we want to draw the edges.
	; Iterate through the edges table, use each entry to look up
	; a pair of joined vertices, and pass those two vectors
	; into bresenham's line algorithm (after projecting them to 2d).
	
	mov ecx, (EDGES_END-EDGE_SIZE)
	.draw_edges_loop:
	  mov eax, [ecx]
	  mov ebx, VECTOR_SIZE
	  mul ebx
	  add eax, WorldCube
	  mov ebx, TwoDIntVector
	  call .project_vector
	  mov eax, StartVector
	  mov edx, [ebx]
	  mov [eax], edx
	  add eax, 4
	  mov edx, [ebx+4]
	  mov [eax], edx
	  mov eax, [ecx+4]
	  mov ebx, VECTOR_SIZE
	  mul ebx
	  add eax, WorldCube
	  mov ebx, TwoDIntVector
	  call .project_vector
	  mov eax, EndVector
	  mov edx, [ebx]
	  mov [eax], edx
	  add eax, 4
	  mov edx, [ebx+4]
	  mov [eax], edx

	  push ecx                     ; We acquired the 2d vectors, so we
	  mov eax, StartVector         ;   are ready to draw the line. We push
	  mov ebx, EndVector           ;   and pop ecx so we don't lose it when
	  mov ecx, RenderBuffer        ;   bresenham overwrites it, since we
	  call bresenham               ;   need it in order to keep iterating.
	  pop ecx
	sub ecx, EDGE_SIZE
	cmp ecx, CubeEdges
	jge .draw_edges_loop
	ret

	; Project a 3d floating vector (at eax) to a 2d int vector (at ebx)
	.project_vector:
	push ecx                       ; Be sure to pop this later.

	; This chunk of code computes the distance from the vector to the
	; camera. It adds 2 to the X component of the vector because the camera
	; is at (-2, 0, 0). The Euclidean distance is stored in a variable.
	fld dword [TheNumberTwo]
	fadd dword [eax]
	fadd dword [zOffs]
	fmul st0, st0
	fld dword [eax+4]
	fmul st0, st0
	fld dword [eax+8]
	fmul st0, st0
	faddp
	faddp
	fsqrt
	fstp dword [ProjectionThingy]

	; Next, take the Y and Z components of the 3d vector, 
	; scale them up so we can see them, scale them down by the
	; perspective projection factor, add an offset, and write to
	; the target 2d vector in ebx.
	; The Y component of the 2d vector gets scaled and offset by half
	; as much as the X component, since terminal characters are tall.

	fld dword [eax+8]
	fmul dword [TheNumberTen]
	fdiv dword [ProjectionThingy]
	fadd dword [TheNumberTwenty]
	fadd dword [yOffs]
	fistp dword [ebx+4]

	fld dword [eax+4]
	fmul dword [TheNumberTwenty]
	fdiv dword [ProjectionThingy]
	fadd dword [TheNumberForty]
	fadd dword [xOffs]
	fistp dword [ebx]

	pop ecx
	ret

	; This constructs a matrix that rotates a
	; vector by (timer) radians along the X and Y axes.
	;
	; | cosx	0	sinx		|
	; | sin^2 x	cosx	-sinx cosx	|
	; | -sinx cosx	sinx	cos^2 x		|
	;
	.update_matrix:
	fld dword [timer]
	fadd dword [timestep]
	fstp dword [timer]

	; 0
	fldz
	fstp dword [RotationMatrix+4]

	; cosx
	fld dword [timer]
	fcos
	fst dword [RotationMatrix]
	fst dword [RotationMatrix+16]

	; cos^2 x
	fmul st0, st0
	fstp dword [RotationMatrix+32]

	; sinx
	fld dword [timer]
	fsin
	fst dword [RotationMatrix+8]
	fst dword [RotationMatrix+28]

	; sin^2 x
	fmul st0, st0
	fstp dword [RotationMatrix+12]

	; -sinx cosx
	fld dword [timer]
	fsin
	fld dword [timer]
	fcos
	fmul
	fmul dword [neg1]
	fst dword [RotationMatrix+20]
	fstp dword [RotationMatrix+24]
	ret

	; Move the cube around on screen according to the sin and cos of
	; the current timer value.
	.update_offsets:
	fld dword [timer]              ; Set xOffs to 20cos(t/2)
	fdiv dword [TheNumberTwo]
	fcos
	fld dword [TheNumberTwenty]
	fmulp
	fstp dword [xOffs]
	fld dword [timer]              ; Set yOffs to 10sin(t)
	fsin
	fld dword [TheNumberTen]
	fmulp
	fstp dword [yOffs]
	fld dword [timer]              ; Set zOffs to sin(t/c)
	fldl2e                         ;   where c is some random builtin
	fdivp                          ;   constant (roughly 1.44) which I
	fsin                           ;   just chose to make the period
	fstp dword [zOffs]             ;   irrational.
	ret

	.main_loop:
	call .sys_nanosleep
	call .clear_terminal
	call .rotate_cube_step
	call .update_matrix
	call .update_offsets
	call .render_to_buffer
	call .print_cube_rep
	jmp .main_loop

	; Exit syscall to signal the end of this process.
	.finish:
	mov eax, 1
	mov ebx, 0
	int 80h
