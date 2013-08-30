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

    streax db "eax", 0
    streax_len equ $-streax-1

    strebx db "ebx", 0
    strebx_len equ $-strebx-1

    strpush db "push ", 0
    strpush_len equ $-strpush-1

    strpop db "pop ", 0
    strpop_len equ $-strpop-1

    strxchg db "xchg eax, ebx", 0
    strxchg_len equ $-strxchg-1

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
;
;
%macro lookc 0
  %%read:
    readc
    cmp    byte [buffer], 0x20
    je     %%read
    cmp    byte [buffer], 0xa
    je     %%read
%endmacro

%macro addp 0
    cmp    byte [buffer], 0x2b
%endmacro

%macro subp 0
    cmp    byte [buffer], 0x2d
%endmacro

%macro mulp 0
    cmp    byte [buffer], 0x2a
%endmacro

%macro divp 0
    cmp    byte [buffer], 0x2f
%endmacro

factor:
    lookc
    printn str1, str1_len
    printn buffer, bufflen
    printn eol, eollen
    ret

term:
    call   factor
  .look:
    lookc
    mulp
    je     .mulcall
    divp
    je     .divcall
    jmp    .end
  .mulcall:
    call   mul
  .divcall:
    call   div
    jmp    .look
  .end:
    ret

mul:
    jne .end
    printn strpush, strpush_len
    printn streax, streax_len
    printn eol, eollen
    call   factor
    printn strpop, strpop_len
    printn strebx, strebx_len
    printn eol, eollen

    printn strmul, strmul_len
    printn strebx, strebx_len
    printn eol, eollen

  .end:
    ret

div:
    jne .end
    printn strpush, strpush_len
    printn streax, streax_len
    printn eol, eollen
    call   factor
    printn strpop, strpop_len
    printn strebx, strebx_len
    printn eol, eollen

    printn strxchg, strxchg_len
    printn eol, eollen

    printn strdiv, strdiv_len
    printn strebx, strebx_len
    printn eol, eollen

  .end:
    ret

add:
    jne    .end
    printn strpush, strpush_len
    printn streax, streax_len
    printn eol, eollen
    call   term
    printn strpop, strpop_len
    printn strebx, strebx_len
    printn eol, eollen

    printn stradd, stradd_len
    printn eol, eollen

  .end:
    ret

sub:
    jne    .end
    printn strpush, strpush_len
    printn streax, streax_len
    printn eol, eollen
    call   term
    printn strpop, strpop_len
    printn strebx, strebx_len
    printn eol, eollen

    printn strxchg, strxchg_len
    printn eol, eollen

    printn strsub, strsub_len
    printn eol, eollen

  .end:
    ret
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

    call   term
  add_sub:
    addp
    je     addcall
    subp
    je     subcall
    jmp    end
  addcall:
    call   add
  subcall:
    call   sub
    jmp    add_sub

  end:
    jmp    exit

;/////////////////////////////////////////////////
;/////////////////////////////////////////////////

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