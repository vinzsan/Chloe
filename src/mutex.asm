[bits 64]

SYS_futex equ 202

FUTEX_WAIT equ 0
FUTEX_WAKE equ 1
FUTEX_WAIT_CONTENDED equ 2

LOCKED equ 1
UNLOCKED equ 0

section .text
    global mutex_lock
    global mutex_unlock
    
mutex_lock:

    push rbx
    mov rbx,rdi

    xor eax,eax
    mov ecx,LOCKED
    lock cmpxchg [rbx],ecx
    jz .L02

.L01:

    mov eax,FUTEX_WAIT_CONTENDED
    xchg eax,[rbx]
    test eax,eax
    jz .L02

    mov rdi,rbx
    mov esi,FUTEX_WAIT
    mov edx,2
    xor r10,r10
    mov rax,SYS_futex
    syscall

    jmp .L01

.L02:

    pop rbx
    ret

mutex_unlock:

    push rbx
    mov rbx,rdi

    xor eax,eax
    xchg eax,[rbx]

    cmp eax,FUTEX_WAIT_CONTENDED
    jne .L01

    mov rdi,rbx
    mov esi,FUTEX_WAKE
    mov edx,1
    mov rax,SYS_futex
    syscall

.L01:

    pop rbx
    ret
    
