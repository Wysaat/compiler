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

    k_int db "int", 0
    k_char db "char", 0

section .bss
    bufflen equ 1
    buffer resb bufflen
    stringbuf resb 1

section .text

;----------------------------------------------
; puts:    print a string to outfile
;
%macro puts 1
    pushfd
    pushad
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
    popad
    popfd
%endmacro

;-----------------------------------------------
; pstdout:   puts to stdout
;
%macro pstdout 1
    pushad
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
    popad
%endmacro

;-----------------------------------------------
; perror:   puts to stderr
;
%macro perror 1
    pushad
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
    popad
%endmacro

;-----------------------------------------------
; putsl:    print a string with a new line (0xa)
;
%macro putsl 1
    puts %1
    puts 10
%endmacro

%macro pstdoutl 1
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
    pushad
    mov    eax, 3
    mov    ebx, ebp
    mov    ecx, buffer
    mov    edx, bufflen
    int    0x80
    cmp    eax, 0
    je     exit
    popad
%endmacro

;----------------------------------------------
; readword:    read from nonspace until first
;              nonalphanumeric char to stringbuf
;              (caution: buffer is changed)
;
%macro readword 0
    pushad
    mov    ecx, buffer
    mov    eax, stringbuf
    push   eax
    lookc
    jmp    %%write
  %%read:
    push   eax
    mov    eax, 3
    mov    ebx, ebp
    mov    edx, 1
    int    0x80
    alphanump
    ;----------------------------------------------
    ; must check zf right after comparing
    ;----------------------------------------------
    jne    %%end
  %%write:
    pop    eax
    mov    bl, byte [buffer]
    mov    byte [eax], bl
    inc    eax
    jmp    %%read

%%end:
    pop    eax
    mov    byte [eax], 0
    popad
%endmacro

;-----------------------------------------------
; printn:    print n characters to outfile
; in: pointer to characters in %1,
;     number of characters in %2
;
%macro printn 2
    pushad
    mov    eax, 4
    mov    ebx, edi
    mov    ecx, %1
    mov    edx, %2
    int    0x80
    popad
%endmacro

;-----------------------------------------------
; print:    print a null terminated string to outfile
; in:       %1: pointer to the string
%macro print 1
    pushad
    mov    ecx, %1
  %%write:
    mov    eax, 4
    mov    ebx, edi
    mov    edx, 1
    int    0x80
    inc    ecx
    cmp    byte [ecx], 0
    jne    %%write
    popad
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
    cmp    byte [buffer], 0x9
    je     %%read
    cmp    byte [buffer], 0xd
    je     %%read
%endmacro

;------------------------------------------------
;  compare:
;
%macro compare 2
    pushad
    cld
    mov    esi, %1
    mov    edi, %2
  %%comp:
    cmpsb
    jne    %%end
    cmp    byte [esi-1], 0
    je     %%end
    jne    %%comp
  %%end:
    popad
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

%macro squotep 0
    cmp    byet [buffer], 0x27
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

identifier:
    push   eax
    push   ebx
    lookc
    letterp
    mov    al, byte [buffer]
    mov    ebx, stringbuf
    mov    byte [ebx], al
    jne    .error
  .read:
    readc
    alphanump
    je     .store
    jmp    .end
  .store:
    mov    al, byte [buffer]
    inc    ebx
    mov    byte [ebx], al
    jmp    .read
  .error:
    perrorl "error: in 'identifier': invalid identifier"
    jmp    exit
  .end:
    escapep
    je     .look
    jmp    .final
  .look:
    lookc
    jmp    .final
  .final:
    inc    ebx
    mov    byte [ebx], 0
    pop    ebx
    pop    eax
    ret

chardeclare:
    readword
    cmp    stringbuf, 0x2a     ; if read *
    putsl  "section .bss"
    print  stringbuf
    putsl  " resb 1"
    putsl  "section .text"
    escapep
    je     .read
  .read:
    lookc
    semicolonp
    je     .end
    lookc                      ; read left single quote
    lookc
    puts    "mov byte ["
    print   stringbuf
    puts    "], '"
    printn  buffer, bufflen
    putsl   "'"
    lookc                      ; read right single quote
    lookc                      ; read ;
  .end:
    ret

declaration:
    readword
    compare stringbuf, k_int
    je      .declare
    compare stringbuf, k_char
    jne     .wait
    call    chardeclare
    jmp     .end
  .declare:
    readword
    putsl   "section .bss"
    print   stringbuf
    putsl   " resb 4"
    putsl   "section .text"
  .wait:
    escapep
    jne    .assign
    lookc
  .assign:
    semicolonp
    je      .end
    call    expression
    puts    "mov dword ["
    print   stringbuf
    putsl   "], eax"
  .end:
    ret

assignment:
    call   identifier
    equp
    jne    .error
    call   expression
    puts   "mov dword ["
    print  stringbuf
    putsl  "], eax"
    ret
  .error:
    perrorl "error: in 'assignment': should be a equal sign"
    jmp    exit

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
    puts   "mov eax, dword ["
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

declare:
    call   declaration
    semicolonp
    je     declare
    jne    .error
  .error:
    perrorl "error: in 'declare': expression not end with semicolon"
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