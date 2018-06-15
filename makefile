SHELL = /bin/sh

main : main.o dot_product.o
	ld -s -o main main.o dot_product.o

main.o : main.asm
	nasm -f elf main.asm

dot_product.o : dot_product.asm
	nasm -f elf dot_product.asm

clean :
	rm main main.o
