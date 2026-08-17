[bits 64]
section .text
    global char_contain
    global strlen
    global strcmp

strcmp:

    ; rdi const char *__dst
    ; rsi const char *__src
    cld

.L01:

    lodsb
    scasb
    jne .L02

    test al,al
    jz .L03
    jmp .L01

.L02:

    mov rax,1
    ret

.L03:

    xor rax,rax
    ret

strlen:
    ; rdi const char *__src
    xor rax,rax
    
.L01:

    cmp byte [rdi + rax],0 
    je .L02
    inc rax
    jmp .L01

.L02:

    ret