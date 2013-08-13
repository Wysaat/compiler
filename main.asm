section .text
    global _start

_start:
    %include "lib.inc"

    init   "test.c"
    mov    ecx, 0

    call   getcharss
    write  "mov eax, ", b0
    writebuf buffer, 1
    write  "\n", b1

    matchar "+", k0
    call   getcharss
    write  "mov ebx, ", b2
    writebuf buffer, 1
    write  "\n", b3
    write  "add eax, ebx", b4
    write  "\n", b5

    matchar "-", k1
    call   getcharss
    write  "mov ebx, ", b6
    writebuf buffer, 1
    write  "\n", b7
    write  "sub eax, ebx", b8
    write  "\n", b9

    mov    eax, 1
    mov    ebx, 0
    int    0x80