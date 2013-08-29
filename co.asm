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
    mov    eax, 3
    mov    ebx, ebp
    mov    ecx, buffer
    mov    edx, bufflen
    int    0x80
    cmp    eax, 0
    ;;; end of file
    je     exit    
    cmp    byte [buffer], 0x20
    je     precalc
    cmp    byte [buffer], 0xa
    je     precalc

    ; print("mov eax, ", buffer, "\n")
    mov    eax, 4
    mov    ebx, edi
    mov    ecx, str1
    mov    edx, str1_len
    int    0x80

    mov    eax, 4
    mov    ebx, edi
    mov    ecx, buffer
    mov    edx, bufflen
    int    0x80

    mov    eax, 4
    mov    ebx, edi
    mov    ecx, eol
    mov    edx, eollen
    int    0x80

calcjudge:
    mov    eax, 3
    mov    ebx, ebp
    mov    ecx, buffer
    mov    edx, bufflen
    int    0x80
    cmp    byte [buffer], 0x20
    je     calcjudge
    cmp    byte [buffer], 0xa
    je     calcjudge

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
    mov    eax, 3
    mov    ebx, ebp
    mov    ecx, buffer
    mov    edx, bufflen
    int    0x80
    cmp    byte [buffer], 0x20
    je     add
    cmp    byte [buffer], 0xa
    je     add

    ; print("mov ebx, ", buffer, "\n")
    mov    eax, 4
    mov    ebx, edi
    mov    ecx, str2
    mov    edx, str2_len
    int    0x80

    mov    eax, 4
    mov    ebx, edi
    mov    ecx, buffer
    mov    edx, bufflen
    int    0x80

    mov    eax, 4
    mov    ebx, edi
    mov    ecx, eol
    mov    edx, eollen
    int    0x80

    ; print("add eax, ebx", "\n")
    mov    eax, 4
    mov    ebx, edi
    mov    ecx, stradd
    mov    edx, stradd_len
    int    0x80
    mov    eax, 4
    mov    ebx, edi
    mov    ecx, eol
    mov    edx, eollen
    int    0x80

    ; add is OK
    jmp    precalc

sub:
    mov    eax, 3
    mov    ebx, ebp
    mov    ecx, buffer
    mov    edx, bufflen
    int    0x80
    cmp    byte [buffer], 0x20
    je     sub
    cmp    byte [buffer], 0xa
    je     sub

    ; print("mov ebx, ", buffer, "\n")
    mov    eax, 4
    mov    ebx, edi
    mov    ecx, str2
    mov    edx, str2_len
    int    0x80

    mov    eax, 4
    mov    ebx, edi
    mov    ecx, buffer
    mov    edx, bufflen
    int    0x80

    mov    eax, 4
    mov    ebx, edi
    mov    ecx, eol
    mov    edx, eollen
    int    0x80

    ; print("sub eax, ebx", "\n")
    mov    eax, 4
    mov    ebx, edi
    mov    ecx, strsub
    mov    edx, strsub_len
    int    0x80
    mov    eax, 4
    mov    ebx, edi
    mov    ecx, eol
    mov    edx, eollen
    int    0x80

    ; sub is OK
    jmp    precalc


mul:
    mov    eax, 3
    mov    ebx, ebp
    mov    ecx, buffer
    mov    edx, bufflen
    int    0x80
    cmp    byte [buffer], 0x20
    je     mul
    cmp    byte [buffer], 0xa
    je     mul

    ; print("mul eax, ", buffer, "\n")
    mov    eax, 4
    mov    ebx, edi
    mov    ecx, strmul
    mov    edx, strmul_len
    int    0x80

    mov    eax, 4
    mov    ebx, edi
    mov    ecx, buffer
    mov    edx, bufflen
    int    0x80

    mov    eax, 4
    mov    ebx, edi
    mov    ecx, eol
    mov    edx, eollen
    int    0x80

    ; mul is OK
    jmp    precalc

div:
    mov    eax, 3
    mov    ebx, ebp
    mov    ecx, buffer
    mov    edx, bufflen
    int    0x80
    cmp    byte [buffer], 0x20
    je     div
    cmp    byte [buffer], 0xa
    je     div

    ; print("div ", buffer, "\n")
    mov    eax, 4
    mov    ebx, edi
    mov    ecx, strdiv
    mov    edx, strdiv_len
    int    0x80

    mov    eax, 4
    mov    ebx, edi
    mov    ecx, buffer
    mov    edx, bufflen
    int    0x80

    mov    eax, 4
    mov    ebx, edi
    mov    ecx, eol
    mov    edx, eollen
    int    0x80

    ; div is OK
    jmp    precalc

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