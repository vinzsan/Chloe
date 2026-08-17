[bits 64]

; created bindgen from pthread
; NOTE: beberapa instance tidak sesuai misal flags yang di set

SYS_clone3      equ 435
SYS_exit        equ 60

CLONE_VM        equ 0x00000100
CLONE_FS        equ 0x00000200
CLONE_FILES     equ 0x00000400
CLONE_SIGHAND   equ 0x00000800
CLONE_THREAD    equ 0x00010000
CLONE_SYSVSEM   equ 0x00040000

THREAD_FLAGS equ (CLONE_VM | CLONE_FS | CLONE_FILES | CLONE_SIGHAND | CLONE_THREAD | CLONE_SYSVSEM)

struc CloneArgs
    .flags: resq 1
    .pidfd: resq 1
    .child_tid: resq 1
    .parent_tid: resq 1
    .exit_signal: resq 1
    .stack: resq 1
    .stack_size: resq 1
    .tls: resq 1
    .set_tid: resq 1
    .set_tid_size: resq 1
    .cgroup: resq 1
endstruc

section .text
    global spawn_thread

spawn_thread:
    ; NOTE: this function is under construct
    ; spawn_thread(void (*func)(void), void *base, size_t n)
    
    push rbx
    push r12
    push r13
    sub rsp, CloneArgs_size

    mov rbx, rdi
    mov r12, rsi
    mov r13, rdx

    mov qword [rsp + CloneArgs.flags], THREAD_FLAGS
    mov qword [rsp + CloneArgs.pidfd], 0
    mov qword [rsp + CloneArgs.child_tid], 0
    
    mov qword [rsp + CloneArgs.parent_tid], 0
    mov qword [rsp + CloneArgs.exit_signal], 0
    mov qword [rsp + CloneArgs.stack], r12

    mov qword [rsp + CloneArgs.stack_size], r13
    mov qword [rsp + CloneArgs.tls], 0
    mov qword [rsp + CloneArgs.set_tid], 0
    mov qword [rsp + CloneArgs.set_tid_size], 0
    mov qword [rsp + CloneArgs.cgroup], 0

    mov rax, SYS_clone3
    mov rdi, rsp                 
    mov rsi, CloneArgs_size      
    syscall

    test rax, rax
    jnz .L1

    call rbx
    xor rdi, rdi
    mov rax, SYS_exit
    syscall

.L1:
    add rsp, CloneArgs_size
    pop r13
    pop r12
    pop rbx
    ret