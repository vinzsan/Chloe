[bits 64]

extern vi_malloc
extern vi_free
extern print

struc VectorInt
    .data_ptr: resq 1
    .size: resq 1
    .capacity: resq 1
endstruc

%if VectorInt_size != 24 
    %error "vector size mismatch,unaligned size"
%endif

section .rodata
    L1: db "ERROR: failed to allocated memory",0x0A,0
    
section .text
    global init_vector
    global push_vector
    global get_vector_by_index
    global cleanup_vector

init_vector:

    ; rdi struct *__vec
    push rdi

    mov rdi,4
    call vi_malloc
    pop rdi

    mov qword [rdi + VectorInt.data_ptr],rax
    mov qword [rdi + VectorInt.size],0
    mov qword [rdi + VectorInt.capacity],0

    ret

push_vector:

    ; rdi struct *__vec
    ; rsi const int
    push rbx
    push r15
    push rsi

    mov r15,rdi

    mov rax, qword [r15 + VectorInt.capacity]
    cmp qword [r15 + VectorInt.size],rax
    jne .L01
    
    cmp qword [r15 + VectorInt.capacity],0
    je .L02
    
    mov rax,qword [r15 + VectorInt.capacity]
    shl rax,1
    mov qword [r15 + VectorInt.capacity],rax

    jmp .L03

.L02:

    mov qword [r15 + VectorInt.capacity],4

.L03:
    
    mov rdi,qword [r15 + VectorInt.capacity]
    call vi_malloc

    test rax,rax
    jz .L04
    
    mov rbx,rax

    mov rsi,qword [r15+ VectorInt.data_ptr]
    mov rdi,rbx
    mov rcx,qword [r15 + VectorInt.capacity]
    rep movsb

    mov rdi,qword [r15 + VectorInt.data_ptr]
    call vi_free
    
    mov qword [r15 + VectorInt.data_ptr],rbx

.L01:

    pop rsi
    mov qword [r15 + VectorInt.size],rsi
    inc qword [r15 + VectorInt.size]
    
    pop r15
    pop rbx
    xor rax,rax
    ret

.L04:

    lea rdi,[rel L1]
    call print

    ud2