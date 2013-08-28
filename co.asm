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

read:
    mov    eax, 3
    mov    ebx, ebp
    mov    ecx, buffer
    mov    edx, bufflen
    int    0x80
    cmp    eax, 0
    je     exit
    jl     error

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

skip_space:
    cmp    byte [buffer], 0x20
    je     read

write:
    mov    eax, 4
    mov    ebx, edi
    mov    ecx, buffer
    mov    edx, bufflen
    int 0x80
    jmp    read

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