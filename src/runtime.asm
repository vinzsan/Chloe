[bits 64]

extern vi_malloc
extern vi_free

extern strlen
extern char_contain

INTERNAL_BUFFER_DEF equ (1024 * 8)
STDOUT_FILENO equ 1
SYS_write equ 1

struc StdoutInternal
    .huge_buffer: resq 1
    .offset: resq 1
    .capacity: resq 1
endstruc

section .rodata
    INT_E1: db "abort(): stdout internal buffer failed to allocated",0x0A,0
    INT_E2: db "abort(): stdout internal failed to reallocated buffer",0x0A,0

section .bss
    stdout: resb StdoutInternal_size
    
section .text
    global init_runtime
    global printf 
    global stdout_buffer_append
    global print

print:

    push rbp
    mov rbp,rsp

    push rdi
    call strlen

    mov rdx,rax
    pop rsi
    mov rdi,STDOUT_FILENO
    mov rax,SYS_write
    syscall

    leave
    ret

init_runtime:

    ; fungsi ini harus di panggil di _start untuk runtime 
    ; beberapa fungsi runtime di embed kesini
    ; NOTE: this function under construct

    push rbx
    push rbp 
    mov rbp,rsp

    lea rbx,[rel stdout]
    
    mov rdi,INTERNAL_BUFFER_DEF
    call vi_malloc
    
    test rax,rax
    jz .L01

    mov qword [rbx + StdoutInternal.huge_buffer],rax
    mov qword [rbx + StdoutInternal.offset],0
    mov qword [rbx + StdoutInternal.capacity],INTERNAL_BUFFER_DEF

    leave
    pop rbx
    ret 

.L01:

    lea rdi,[rel INT_E1]
    call print

    ud2
    
stdout_buffer_append:

    ; rdi *const char *__str
    sub rsp,32
    mov qword [rsp],rdi

    call strlen
    mov qword [rsp+8],rax

    lea rax,[rel stdout]
    
    mov rdi,[rax + StdoutInternal.capacity]
    cmp qword [rsp+8],rdi
    jl .L01

    add rsp,32
    ret

.L01:

    mov rdi,[rax + StdoutInternal.offset]
    cmp rdi, qword [rax + StdoutInternal.capacity]
    jge .L02
    
    mov rsi,[rax + StdoutInternal.huge_buffer]
    lea r10,[rsi + rdi]
    
    mov rsi, qword [rsp]
    mov rdi,r10
    mov rcx, qword [rsp+8]
    rep movsb
    
    lea rax,[rel stdout]
    mov rcx, qword [rsp+8]
    add qword [rax + StdoutInternal.offset],rcx

.L02:

    add rsp,32
    ret 

printf:

    push rbx
    push r10
    push rbp 
    mov rbp,rsp 
    sub rsp,32

    ; rdi const char *__str
    mov qword [rbp-8],rdi
    call stdout_buffer_append

    mov rdi, qword [rbp-8]
    call .contains_nl
    
    test rax,rax
    jz .L1

    mov rdi, qword [rbp-8]
    call strlen
    
    mov qword [rbp-16],rax

    lea rax,[rel stdout]

    mov rdi, qword [rax + StdoutInternal.offset]
    add rdi, qword [rbp-16]
    
    cmp rdi,qword [rax + StdoutInternal.capacity]
    jge .L2
    
    jmp .L3

.L1:

    lea r10,[rel stdout]

    mov rsi, qword [r10 + StdoutInternal.huge_buffer]
    mov rdx, qword [r10 + StdoutInternal.offset]
    mov rdi, STDOUT_FILENO
    mov rax, SYS_write
    syscall

    mov qword [r10 + StdoutInternal.offset],0

    jmp .L3

.L2:

    mov rcx, qword [rax + StdoutInternal.capacity]

    imul rbx,rcx,2
    
    imul rdi,rbx
    call vi_malloc

    test rax,rax
    jz .EXC_E1
    
    mov r10,rax

    lea rax,[rel stdout]

    mov rsi, qword [rax + StdoutInternal.huge_buffer]
    mov rcx, qword [rax + StdoutInternal.capacity]
    rep movsb

    mov rdi, qword [rax + StdoutInternal.huge_buffer]
    call vi_free

    mov qword [rax + StdoutInternal.huge_buffer],r10
    mov qword [rax + StdoutInternal.capacity],r9

.L3:

    leave
    pop rbx
    pop r10
    ret 

.EXC_E1:

    lea rdi,[rel INT_E2]
    call print

    ud2

.contains_nl:
    ; for(int i = 0;__str[i];i++)
    xor rcx,rcx

.L01:
    
    cmp byte [rdi + rcx],0x0A
    je .L02
    inc rcx
    jmp .L01
    
    mov rax,1
    ret

.L02:

    xor rax,rax
    ret