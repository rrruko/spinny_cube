SHELL = /bin/sh

main : main.o dot_product.o bresenham.o
	ld -s -o main main.o dot_product.o bresenham.o

main.o : main.asm
	nasm -f elf main.asm

dot_product.o : dot_product.asm
	nasm -f elf dot_product.asm

bresenham.o : bresenham.asm
	nasm -f elf bresenham.asm

clean :
	rm main main.o bresenham.o dot_product.o
