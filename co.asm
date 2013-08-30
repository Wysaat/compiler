section .data
    outfile db "outfile.out", 0
    errmsg db "an error occurred...", 13, 10, 0
    errlen equ $-errmsg-1
    usgmsg db "usage: co <source_file>", 13, 10, 0
    usglen equ $-usgmsg-1

    eol  db 13, 10, 0
    eollen equ $-eol-1

    str1 db "mov eax, ", 0
    str1_len equ $-str1-1

    str2 db "mov ebx, ", 0
    str2_len equ $-str2-1

    stradd db "add eax, ebx", 0
    stradd_len equ $-stradd-1

    strsub db "sub eax, ebx", 0
    strsub_len equ $-strsub-1

    strmul db "mul ", 0
    strmul_len equ $-strmul-1

    strdiv db "div ", 0
    strdiv_len equ $-strdiv-1

section .bss
    bufflen equ 1
    buffer resb bufflen

section .text

;-----------------------------------------------
; readc:    read a single character from infile
;
%macro readc 0
    mov    eax, 3
    mov    ebx, ebp
    mov    ecx, buffer
    mov    edx, bufflen
    int    0x80
%endmacro

;-----------------------------------------------
; printc:    print n characters to outfile
; in: pointer to characters in %1,
;     number of characters in %2
;
%macro printn 2
    mov    eax, 4
    mov    ebx, edi
    mov    ecx, %1
    mov    edx, %2
    int    0x80
%endmacro

;-----------------------------------------------
; lookc:    read a single character and
;           ignore the spaces and newlines
;           and jump to exit if end of file
;
%macro lookc 0
  %%read:
    readc
    cmp    eax, 0
    je     exit
    cmp    byte [buffer], 0x20
    je     %%read
    cmp    byte [buffer], 0xa
    je     %%read
%endmacro

    global _start

_start:

init:
    ; open source
    mov    eax, 5
    pop    ebx
    pop    ebx
    pop    ebx
    cmp    ebx, 0
    je     usage
    mov    ecx, 0
    int    0x80
    mov    ebp, eax

delete:
    ; delete outfile.out
    ; no matter it exists or not
    mov    eax, 10
    mov    ebx, outfile
    int    0x80

    ; then create it
create:
    mov    eax, 8
    mov    ebx, outfile
    mov    ecx, 0q700
    int    0x80
    mov    edi, eax
;/////////////////////////////////////////////////
; initiation is over
;/////////////////////////////////////////////////


precalc:
    lookc

    ; print("mov eax, ", buffer, "\n")
    printn str1, str1_len
    printn buffer, bufflen
    printn eol, eollen

calcjudge:
    lookc

    ; add(0x2b), sub(0x2d), mul(0x2a), div(0x2f)
    cmp    byte [buffer], 0x2b
    je     add
    cmp    byte [buffer], 0x2d
    je     sub
    cmp    byte [buffer], 0x2a
    je     mul
    cmp    byte [buffer], 0x2f
    je     div
    jmp    error

add:
    lookc

    ; print("mov ebx, ", buffer, "\n")
    printn str2, str2_len
    printn buffer, bufflen
    printn eol, eollen

    ; print("add eax, ebx", "\n")
    printn stradd, stradd_len
    printn eol, eollen

    ; add is OK
    jmp    precalc

sub:
    lookc

    ; print("mov ebx, ", buffer, "\n")
    printn str2, str2_len
    printn buffer, bufflen
    printn eol, eollen

    ; print("sub eax, ebx", "\n")
    printn strsub, strsub_len
    printn eol, eollen

    ; sub is OK
    jmp    precalc

mul:
    lookc

    ; print("mul eax, ", buffer, "\n")
    printn strmul, strmul_len
    printn buffer, bufflen
    printn eol, eollen

    ; mul is OK
    jmp    precalc

div:
    lookc

    ; print("div ", buffer, "\n")
    printn strdiv, strdiv_len
    printn buffer, bufflen
    printn eol, eollen

    ; div is OK
    jmp    precalc

;////////////////////////////////////////////////
;////////////////////////////////////////////////

error:
    mov    eax, 4
    mov    ebx, 2
    mov    ecx, errmsg
    mov    edx, errlen
    int    0x80
    jmp    exit

usage:
    mov    eax, 4
    mov    ebx, 1
    mov    ecx, usgmsg
    mov    edx, usglen
    int    0x80
    jmp    exit

exit:
    ; close source
    mov    eax, 6
    mov    ebx, ebp
    int    0x80

    ; close out
    mov    eax, 6
    mov    ebx, edi
    int    0x80

    mov    eax, 1
    mov    ebx, 0
    int    0x80