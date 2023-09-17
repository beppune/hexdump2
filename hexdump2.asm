
;	Program:	Hexdump2
;	Author:		Giuseppe Manzo
;	Updated:	2023-09-23
;
;	compile with:
;		nasm  -f elf32 -g  -o hexdump2.o hexdump2.asm
;		ld  -m  elf_i386  -o hexdump2 hexdump2.o
;

global _start

section .data

	; This table is used for ASCII character translation, into the ASCII
	; portion of the hex dump line, via XLAT or ordinary memory lookup.
	; All printable characters “play through“ as themselves. The high 128
	; characters are translated to ASCII period (2Eh). The non-printable
	; characters in the low 128 are also translated to ASCII period, as is
	; char 127.
	DotXlat:
			db 2Eh,2Eh,2Eh,2Eh,2Eh,2Eh,2Eh,2Eh,2Eh,2Eh,2Eh,2Eh,2Eh,2Eh,2Eh,2Eh
			db 2Eh,2Eh,2Eh,2Eh,2Eh,2Eh,2Eh,2Eh,2Eh,2Eh,2Eh,2Eh,2Eh,2Eh,2Eh,2Eh
			db 20h,21h,22h,23h,24h,25h,26h,27h,28h,29h,2Ah,2Bh,2Ch,2Dh,2Eh,2Fh
			db 30h,31h,32h,33h,34h,35h,36h,37h,38h,39h,3Ah,3Bh,3Ch,3Dh,3Eh,3Fh
			db 40h,41h,42h,43h,44h,45h,46h,47h,48h,49h,4Ah,4Bh,4Ch,4Dh,4Eh,4Fh
			db 50h,51h,52h,53h,54h,55h,56h,57h,58h,59h,5Ah,5Bh,5Ch,5Dh,5Eh,5Fh
			db 60h,61h,62h,63h,64h,65h,66h,67h,68h,69h,6Ah,6Bh,6Ch,6Dh,6Eh,6Fh
			db 70h,71h,72h,73h,74h,75h,76h,77h,78h,79h,7Ah,7Bh,7Ch,7Dh,7Eh,2Eh
			db 2Eh,2Eh,2Eh,2Eh,2Eh,2Eh,2Eh,2Eh,2Eh,2Eh,2Eh,2Eh,2Eh,2Eh,2Eh,2Eh
			db 2Eh,2Eh,2Eh,2Eh,2Eh,2Eh,2Eh,2Eh,2Eh,2Eh,2Eh,2Eh,2Eh,2Eh,2Eh,2Eh
			db 2Eh,2Eh,2Eh,2Eh,2Eh,2Eh,2Eh,2Eh,2Eh,2Eh,2Eh,2Eh,2Eh,2Eh,2Eh,2Eh
			db 2Eh,2Eh,2Eh,2Eh,2Eh,2Eh,2Eh,2Eh,2Eh,2Eh,2Eh,2Eh,2Eh,2Eh,2Eh,2Eh
			db 2Eh,2Eh,2Eh,2Eh,2Eh,2Eh,2Eh,2Eh,2Eh,2Eh,2Eh,2Eh,2Eh,2Eh,2Eh,2Eh
			db 2Eh,2Eh,2Eh,2Eh,2Eh,2Eh,2Eh,2Eh,2Eh,2Eh,2Eh,2Eh,2Eh,2Eh,2Eh,2Eh
			db 2Eh,2Eh,2Eh,2Eh,2Eh,2Eh,2Eh,2Eh,2Eh,2Eh,2Eh,2Eh,2Eh,2Eh,2Eh,2Eh
			db 2Eh,2Eh,2Eh,2Eh,2Eh,2Eh,2Eh,2Eh,2Eh,2Eh,2Eh,2Eh,2Eh,2Eh,2Eh,2Eh

	DumpLin:	db	" 00 00 AA 00 AA AA AA AA AA AA AA AA AA AA AA AA ",0Ah
	DUMPLEN		equ $-DumpLin

	HexStr:	db "0123456789ABCDEF"

section .bss
	BUFFLEN	equ		16
	Buffer:	resb	BUFFLEN


section .text

	; DumpByte:		Dump a Byte representation into Dumplin
	; UPDATED:		15/09/2023
	; IN:			AL:  byte to represent
	;				EDI: zero-based address of DumpLin byte represented.
	; MODIFIES:		DumpLin at given position
	; DESCRIPTION:	Separate the nybbles at AL and for each nybble
	;				modify the matching position at DumpLin.
	;				Caller must provide the elementg address in EDI of DumpLin
	;				table by the following formula: [DumpLin + index *3]
	;				EDI + 2 Least Significant Nybble
	;				EDI + 1 Most Significant Nybble
	;				Use HexStr as translation table for the nybbles
	DumpByte:

			xor ebx, ebx

			mov bl, al
			and bl, 0Fh
			mov bl, [HexStr + ebx]

			mov [edi + 2], bl

			mov bl, al
			shr bl, 4
			mov bl, [HexStr + ebx]

			mov [edi + 1], bl

			ret

	; ScanBuffer	Scan Buffer and Dump eah read byte into DumpLin
	; UPDATED:		15/09/2023
	; IN:			ECX: # of bytes read
	; RETURNS:		Nothing
	; MODIFIES:		DumpLin
	; CALL:			DumpChar
	; DESCRIPTION:	For each byte in Buffer put the byte in al and
	;				the matching DumpLin position based on current index
	ScanBuffer:

			push esi
			push edx
			push eax
			push edi

			mov esi, ecx
			xor eax, eax
			xor ecx, ecx

		.loop:
			mov edx, ecx
			shl edx, 1
			add edx, ecx

			mov al, [Buffer + ecx]
			lea edi, [DumpLin + edx]

			call DumpByte

			inc ecx
			cmp ecx, esi
			jnz .loop

			pop edi
			pop eax
			pop edx
			pop esi

			ret


	; DumpAll:		Set to zero representation the whole DumpLin string
	; UPDATED:		14/09/2023
	; IN:			None
	; RETURNS:		Nothing
	; MODIFIES:		DumpLin
	; CALL:			DumpChar
	; DESCRIPTION:	Set each represented byte to 00 into string DumpLin by
	;				calling DumpChar whith input AL: 0 and ECX from 0 to 15
	;				in a loop
	DumpAll:
			push eax
			push ebx
			push ecx
			push edx

			xor eax, eax
			xor ebx, ebx

			mov al, 0
			mov ecx, 0

		.loop:
			mov edx, ecx
			shl edx, 1
			add edx, ecx

			lea edi, [DumpLin + edx]

			call DumpByte

			inc ecx
			cmp ecx, 16
			jnz .loop

			pop edx
			pop ecx
			pop ebx
			pop eax
			ret


	; LoadBuf:		Fills Buffer from stdin
	; UPDATED:		14/09/2023
	; IN:			No input
	; RETURNS:		# of bytes
	; MODIFIES:		ECX, EBP, Buffer
	; CALLS:		sys_write
	; DESCRIPTION:	Load at most BUFFLEN bytes from stdin to Buffer
	;				Sets ECX to zero as starting index for Buffer
	;				Saves # of bytes read into EBP. Caller must
	;				test ebp value for errors
	LoadBuf:
			push eax
			push ebx
			push edx

			mov eax, 3
			mov ebx, 0
			mov ecx, Buffer
			mov edx, BUFFLEN
			int 80h

			mov ebp, eax
			xor ecx, ecx

			pop edx
			pop ebx
			pop eax

			ret

_start:

	nop

		call LoadBuf
		cmp ebp, 0
		jz Exit

		mov ecx, ebp
		call ScanBuffer

		mov eax, 4
		mov ebx, 1
		mov ecx, DumpLin
		mov edx, DUMPLEN
		int 80h


Exit:	mov eax, 1		; sys_exit
		mov ebx, 0		; exit with value 0
		int 80h			; kernel

	nop

