; utility macros and procedures

; open() function:
; input: filename
; description:
;     take a filename and open the file,
;     store the file descriptor in ebx.
;
%macro open 1
section .data
        fname db %1, 0
section .text
        mov    eax, 5
        mov    ebx, fname
        mov    ecx, 0
        int    0x80
        mov    ebx, eax
%endmacro

%macro creat 1
    section .data
        outfname db %1
    section .text
        mov    eax, 8
        mov    ebx, outfname
        int    0x80
        mov    ebp, eax
%endmacro

%macro init 1
    section .bss
        bufflen      equ  1
        buffer       resb bufflen
    section .text
        open %1
        creat 'a.out'
%endmacro

; skip spaces and get the first nonspace char
;
getcharss:
    mov    esi, ecx
    mov    eax, 3
    mov    ecx, buffer
    mov    edx, bufflen
    int    0x80
    cmp    byte [buffer], 0x20
    jz     getcharss
    mov    ecx, esi
    inc    ecx
    ret

%macro matchar 2
    section .data    
        %2 db %1
    section .text
        cld
        mov    esi, buffer
        mov    edi, %2
        cmpsb
%endmacro

%macro write 2
    section .data
        %2 db %1
        %2len equ $-%2
    section .text
        pusha
        mov    eax, 4
        mov    ebx, ebp
        mov    ecx, %2
        mov    edx, %2len
        int    0x80
        popa
%endmacro

%macro writebuf 2
    pusha
    mov    eax, 4
    mov    ebx, ebp
    mov    ecx, %1
    mov    ecx, %2
    int    0x80
    popa
%endmacro