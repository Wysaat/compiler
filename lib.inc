; utility macros and procedures

; open() function:
; input: filename
; description:
;     take a filename and open the file,
;     store the file descriptor in ebx.
;
%macro open 1
    fname db %1
    mov    eax, 5
    mov    ebx, fname
    mov    ecx, 0
    int    0x80
    mov    ebx, eax
%endmacro

%macro init 1
    section .bss
        bufflen equ 1
        buffer resb bufflen
    section .text
        open %1
%endmacro

getchar:
    mov    esi, ecx
    mov    eax, 3
    mov    ecx, buffer
    mov    edx, bufflen
    int    0x80
    push   buffer
    mov    ecx, esi
    inc    ecx

; skip spaces and get the first nonspace char
;
getcharss:
    mov    esi, ecx
    mov    eax, 3
    mov    ecx, buffer
    mov    edx, bufflen
    int    0x80
    cmp    buffer, 0x20
    jz     skipspace
    push   buffer
    mov    ecx, esi
    inc    ecx

getword:
    pop    byte [buffer+ecx]
    loop   getword

%macro iskeyword 1
    section .data
        keyword db %1
    section .text
        cld
        mov    si, buffer
        mov    di, keyword
        repe cmpsb