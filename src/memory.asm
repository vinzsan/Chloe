[bits 64]

extern print
extern mutex_lock
extern mutex_unlock

SYS_brk equ 12

CHUNK_FREE equ 1
CHUNK_USED equ 0

struc ChunkBase
    .size: resq 1
    .free: resb 1
        alignb 8
    .next: resq 1
endstruc

struc PageBase
    .size: resq 1
    .chunk_count: resq 1
        alignb 8
    .state: resb 1
endstruc

%if ChunkBase_size != 24
    %error "chunk size mismatch, unaligned"
%endif

section .rodata
    INT_M_E1: db "abort(): failed to allocate heap for metadata",0x0A,0
    INT_M_E2: db "abort(): free error, metadata missing",0x0A,0
    INT_M_E3: db "abort(): free twice",0x0A,0

section .data
    ; NOTE: ptr type
    ChunkHead: dq 0
    ChunkTail: dq 0

    LockGuard: dd 0

section .text
    global sbrk
    global vi_malloc
    global vi_free
    
sbrk:

    push rbx

    push rdi
    ; rdi request N

    mov rax,SYS_brk
    xor rdi,rdi
    syscall
    
    mov rbx,rax
    
    pop rdi
    lea rax,[rbx + rdi]

    mov rdi,rax
    mov rax,SYS_brk
    syscall

    cmp rax,-1
    jne .L01

    xor rax,rax
    pop rbx
    ret

.L01:

    pop rbx
    ret 
    
static_vi_search_free_block:
    ; NOTE: this function might be deprecate
    ; if you got something strane please check twice
    ; cause this using general loop, must be slower
    
    ; rdi size_t current_size
    mov rax,qword [rel ChunkHead]
    
.L01:

    test rax,rax
    jz .L02
    
    cmp byte [rax + ChunkBase.free],CHUNK_USED
    je .L04

    cmp qword [rax + ChunkBase.size],rdi
    jge .L03

.L04:
    
    mov rsi,qword [rax + ChunkBase.next]
    mov rax,rsi

    jmp .L01

.L02:
    
    xor rax,rax

.L03:

    ret

vi_malloc:
    ; NOTE: this function to sht, i dont give a shit
    ; bout this function, you know what, this sht is waste
    ; my time to much, and whatever you dont agree with this sht
    ; i js give a thanks, cause ts shit very very sht
    push rbx
    push r12
    
    push rbp
    mov rbp,rsp
    sub rsp,16
    
    ; rdi size_t nsize
    add rdi,7
    and rdi,-8

    mov rbx,rdi 
    mov r12,rdi
    push rdi

    lea rdi,[rel LockGuard]
    call mutex_lock

    mov rdi,r12
    call static_vi_search_free_block
    test rax,rax
    jz .L01
    
    push rax
    lea rdi,[rel LockGuard]
    call mutex_unlock
    pop rax

    mov byte [rax + ChunkBase.free],CHUNK_USED
    lea rax,[rax + ChunkBase_size]

    leave
    pop r12
    pop rbx
    ret

.L01:

    pop rdi
    add rdi,ChunkBase_size

    call sbrk

    test rax,rax
    je .L0E_1
    
    mov qword [rax + ChunkBase.size],rbx
    mov byte [rax + ChunkBase.free],CHUNK_USED
    mov qword [rax + ChunkBase.next],0

    mov rdx,rax

    cmp qword [rel ChunkHead],0
    je .L02

    mov rax,[rel ChunkTail]

    mov qword [rax + ChunkBase.next],rdx
    mov qword [rel ChunkTail],rdx
    
    jmp .L03

.L02:

    mov qword [rel ChunkHead],rdx
    mov qword [rel ChunkTail],rdx

.L03:

    push rdx
    lea rdi,[rel LockGuard]
    call mutex_unlock

    lea rax,[rdx + ChunkBase_size]

    leave
    pop r12
    pop rbx
    ret

.L0E_1:

    lea rdi,[rel INT_M_E1]
    call print

    ud2

vi_free:
    push rbp
    mov rbp,rsp

    lea rax,[rdi - ChunkBase_size]
    test rax,rax

    jz .L0E_1
    
    cmp byte [rax + ChunkBase.free],CHUNK_FREE
    je .L0E_2

    mov byte [rax + ChunkBase.free],CHUNK_FREE

    xor rax,rax
    leave
    ret

.L0E_1:
    
    lea rdi,[rel INT_M_E2]
    call print

    ud2

.L0E_2:

    lea rdi,[rel INT_M_E3]
    call print

    ud2