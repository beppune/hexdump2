
hexdump2:	hexdump2.o
	ld  -m  elf_i386  -o hexdump2 hexdump2.o

hexdump2.o:	hexdump2.asm
	nasm  -f elf32 -g  -o hexdump2.o hexdump2.asm

clean:
	rm hexdump2 hexdump2.o

ifneq ($(EDITOR),)
e:
	${EDITOR} hexdump2.asm
endif

