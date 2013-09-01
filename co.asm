section .data
    outfile db "outfile.out", 0
    errmsg db "an error occurred...", 13, 10, 0
    errlen equ $-errmsg-1
    usgmsg db "usage: co <source_file>", 13, 10, 0
    usglen equ $-usgmsg-1

    strbss db "section .bss", 0
    strbss_len equ $-strbss-1

    strtext db "section .text", 0
    strtext_len equ $-strtext-1

section .bss
    bufflen equ 1
    buffer resb bufflen

section .text

;----------------------------------------------
; puts:    print a string to outfile
;
%macro puts 1
    pushfd
    jmp %%putscall

%%putsmain:
    pop    ecx
%%putsout:
    mov    eax, 4
    mov    ebx, edi                   ; outfile
    mov    edx, 1
    int    0x80
    inc    ecx
    cmp    byte [ecx], 0
    jne    %%putsout
    jmp    %%end

%%putscall:
    call %%putsmain
    db %1, 0
%%end:
    popfd
%endmacro

;-----------------------------------------------
; print:   puts to stdout
;
%macro print 1
    jmp %%putscall

%%putsmain:
    pop    ecx
%%putsout:
    mov    eax, 4
    mov    ebx, 1                       ; stdout
    mov    edx, 1
    int    0x80
    inc    ecx
    cmp    byte [ecx], 0
    jne    %%putsout
    jmp    %%end

%%putscall:
    call %%putsmain
    db %1, 0
%%end:
%endmacro

;-----------------------------------------------
; perror:   puts to stderr
;
%macro perror 1
    jmp %%putscall

%%putsmain:
    pop    ecx
%%putsout:
    mov    eax, 4
    mov    ebx, 2                       ; stderr
    mov    edx, 1
    int    0x80
    inc    ecx
    cmp    byte [ecx], 0
    jne    %%putsout
    jmp    %%end

%%putscall:
    call %%putsmain
    db %1, 0
%%end:
%endmacro

;-----------------------------------------------
; putsl:    print a string with a new line (0xa)
;
%macro putsl 1
    puts %1
    puts 10
%endmacro

%macro printl 1
    print %1
    print 10
%endmacro

%macro perrorl 1
    perror %1
    perror 10
%endmacro

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
; printn:    print n characters to outfile
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
    cmp    eax, 0
    je     exit
    cmp    byte [buffer], 0x20
    je     %%read
    cmp    byte [buffer], 0xa
    je     %%read
    cmp    byte [buffer], 0x9
    je     %%read
    cmp    byte [buffer], 0xd
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

%macro lpap 0
    cmp    byte [buffer], 0x28
%endmacro

%macro rpap 0
    cmp    byte [buffer], 0x29
%endmacro

%macro semicolonp 0
    cmp    byte [buffer], 0x3b
%endmacro

%macro equp 0
    cmp    byte [buffer], 0x3d
%endmacro

%macro upalphap 0
    push   eax
    lahf
    and    ah, 0b10111111
    sahf
    cmp    byte [buffer], 0x41
    jl     %%end
    cmp    byte [buffer], 0x5a
    jg     %%end
    lahf
    or     ah, 0b01000000
    sahf
  %%end:
    pop    eax
%endmacro

%macro lowalphap 0
    push   eax
    lahf
    and    ah, 0b10111111
    sahf
    cmp    byte [buffer], 0x61
    jl     %%end
    cmp    byte [buffer], 0x7a
    jg     %%end
    lahf
    or     ah, 0b01000000
    sahf
  %%end:
    pop    eax
%endmacro

%macro alphap 0
    upalphap
    je    %%end
    lowalphap
  %%end:
%endmacro

;------------------------------------------------
;   underscore _ is counted as a letter in C
;
%macro letterp 0
    alphap
    je    %%end
    cmp   byte [buffer], 0x5f
  %%end:
%endmacro

%macro nump 0
    push   eax
    lahf
    and    ah, 0b10111111
    sahf
    cmp    byte [buffer], 0x30
    jl     %%end
    cmp    byte [buffer], 0x39
    jg     %%end
    lahf
    or     ah, 0b01000000
    sahf
  %%end:
    pop    eax
%endmacro

;------------------------------------------------
; alphanump:  determine if the character is valid
;             in a C identifier,
;             underscore _ is counted as a letter
;
%macro alphanump 0
    alphap
    je     %%end
    nump
    je     %%end
    cmp    byte [buffer], 0x5f
  %%end:
%endmacro

%macro escapep 0
    cmp    byte [buffer], 0x20    ; space
    je     %%end
    cmp    byte [buffer], 0x9     ; tab
    je     %%end
    cmp    byte [buffer], 0xa     ; nl
    je     %%end
    cmp    byte [buffer], 0xd     ; cr
    je     %%end
  %%end:
%endmacro

factor:
    lookc
    lpap
    jne    .nopa
    call   expression
    rpap
    je     .notend
    jne    .error
  .nopa:
    nump
    jne    .isidp
    puts   "mov eax, "
  .print:
    printn buffer, bufflen
    readc
    nump
    jne    .end
    jmp    .print
  .isidp:
    letterp
    jne    .error
    puts   "mov eax, ["
  .print2:
    printn buffer, bufflen
    readc
    alphanump
    jne    .here
    jmp    .print2
  .here:
    puts   "]"
    jmp    .end
  .notend:
    lookc
    jmp    .endnol
  .error:
    perrorl "error: in 'factor': invalid identifier"
    jmp    exit
  .end:
    puts   10
  .endnol:
    escapep
    je     .look
    jmp    .final
  .look:
    lookc
  .final:
    ret

term:
    call   factor
  .look:
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

expression:
    call   term
  .add_sub:
    addp
    je     .addcall
    subp
    je     .subcall
    jmp    .end
  .addcall:
    call   add
  .subcall:
    call   sub
    jmp    .add_sub

  .end:
    ret

mul:
    jne .end
    putsl  "push eax"
    call   factor
    putsl  "pop ebx"
    putsl  "mul ebx"
  .end:
    ret

div:
    jne .end
    putsl  "push eax"
    call   factor
    putsl  "pop ebx"
    putsl  "xchg eax, ebx"
    putsl   "div ebx"
  .end:
    ret

add:
    jne    .end
    putsl  "push eax"
    call   term
    putsl  "pop ebx"
    putsl  "add eax, ebx"
  .end:
    ret

sub:
    jne    .end
    putsl  "push eax"
    call   term
    putsl  "pop ebx"
    putsl  "xchg eax, ebx"
    putsl  "sub eax, ebx"
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

expre:
    call   expression
    semicolonp
    je     expre
    jne    .error
  .error:
    perrorl "error: in 'expre': expression not end with semicolon"
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