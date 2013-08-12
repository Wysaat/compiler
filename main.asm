section .text
    global _start

_start:
    %include "lib.inc"

    init   "test.c"
    mov    ecx, 0
read:
    call   getchar
    cmp    buffer, 0x20
    jnz    read
    dec    ecx
    call   getword
    iskeyword int
    call   getcharss
    jmp    read