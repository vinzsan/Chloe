[bits 64]


;   Chloe (server)
;   Date: 17 August 2026
;   Dear programmer, please dont judge my code


THREAD_STACK_SIZE equ 65536
SOCKADDR_IN_SIZEOF equ 16
MAX_CLIENT equ 128

%include "include/export.inc"

section .rodata
    L1: db "Hello world",0x0A,0
    L2: db "INFO: client connected",0x0A,0
    L3: db "INFO: server shutdown",0x0A,0

    L4: db "INFO: pollfd server already setup",0x0A,0
    L5: db "ERROR: failed to poll",0x0A,0
    L6: db "INFO: client disconnected",0x0A,0
    
    L7: db "INFO: server socket initialize",0x0A,0
    L8: db "INFO: server success bind adress",0x0A,0

    INT_S_E1: db "ERROR: failed to create socket",0x0A,0
    INT_S_E2: db "ERROR: failed to setsockopt",0x0A,0
    INT_S_E3: db "ERROR: failed to bind address",0x0A,0

    HEADER: 
        db "HTTP/1.1 200 OK",0x0A,0x0D
        db "Content-Type: text/html",0x0A,0x0D
        db "Content-Length: 68",0x0D,0x0A,0x0D,0x0A
        db "<h1>Hello world</h1>",0x0A,0x0D
        db "<script>console.log('Hello world')</script>",0


section .data
    lock_guard: dd 0
    ndfs: dd 1

section .bss
    
section .text
    global _start

set_socket_non_blocking:

    mov rax,SYS_fcntl
    mov rsi,F_SETFL
    mov rdx,0 | O_NONBLOCK
    syscall

    test rax,rax
    jnz .L01

    ret

.L01:

    ud2

main:

    push rbx
    push r13
    push r12
    push rbp
    mov rbp,rsp
    sub rsp,80
    
    mov rax,SYS_socket
    mov rdi,AF_INET
    mov rsi,SOCK_STREAM
    xor rdx,rdx
    syscall

    cmp rax,0
    jl .E01

    mov dword [rbp-8],eax
    mov dword [rbp-16],1

    lea rdi,[rel L7]
    call print

    mov rax,SYS_setsockopt
    mov edi, dword [rbp-8]
    mov rsi,SOL_SOCKET
    mov rdx,SO_REUSSEADDR
    lea r10,[rbp-16]
    mov r8d,4
    syscall
    
    cmp rax,0
    jl .E02

    mov rax,SYS_setsockopt
    mov edi,dword [rbp-8]
    mov rsi,IPPROTO_TCP
    mov rdx,TCP_NODELAY
    lea r10,[rbp-16]
    mov r8d,4
    syscall
    
    lea rax,[rbp-48]

    mov word [rax + sockaddr_in.sin_family],AF_INET
    mov word [rax + sockaddr_in.sin_port],0x2923
    mov dword [rax + sockaddr_in.sin_addr],0
    mov qword [rax + sockaddr_in.sin_zero],0

    mov rax,SYS_bind
    mov edi, dword [rbp-8]
    lea rsi,[rbp-48]
    mov rdx,SOCKADDR_IN_SIZEOF
    syscall
    
    cmp rax,0
    jl .E03
    
    lea rdi,[rel L8]
    call print

    mov qword [rbp-16],8
    
    mov rax,SYS_listen
    mov edi, dword [rbp-8]
    mov rsi,MAX_CLIENT
    syscall
    
    mov edi, dword [rbp-8]
    call set_socket_non_blocking
    
    sub rsp,pollfd_size * MAX_CLIENT

    mov eax,dword [rbp-8]
    mov dword [rsp + pollfd.fd],eax
    mov word [rsp + pollfd.event],POLLIN

    lea rdi,[rel L4]
    call print
    

    
.L1: 
    ; server start
    mov rax,SYS_poll
    lea rdi,[rsp]
    mov esi, dword [rel ndfs]
    mov edx,-1
    syscall

    cmp rax,0
    jnl .L2

    cmp rax,EINTR
    je .L2
    
    lea rdi,[rel L5]
    call print

    ;jmp .L05

    ud2

.L2:
    
    lea rax,[rsp]
    test word [rax + pollfd.revents],POLLIN
    jz .L04

    mov qword [rbp-64],0

    mov rax,SYS_accept
    mov edi, dword [rbp-8]
    lea rsi,[rbp-64]
    lea rdx,[rbp-16]
    syscall
    
    mov dword [rbp-72],eax

    cmp rax,0
    jle .L04

    cmp dword [rel ndfs],MAX_CLIENT
    jge .L3
    
    mov edi,dword [rbp-72]
    call set_socket_non_blocking
    
    mov rax,SYS_setsockopt
    mov edi,dword [rbp-72]
    mov rsi,IPPROTO_TCP
    mov rdx,TCP_NODELAY
    lea r10,[rbp-16]
    mov r8d,4
    syscall
    
    movzx rax,dword [rel ndfs]
    mov edx,dword [rbp-72]
    mov dword [rsp + rax * pollfd_size + pollfd.fd],edx
    mov word [rsp + rax * pollfd_size + pollfd.event],POLLIN

    inc dword [rel ndfs]

    lea rdi,[rel L2]
    call print

    jmp .L04

.L3:
    
    mov rax,SYS_close
    mov edi, dword [rbp-72]
    syscall
    
    lea rdi,[rel L6]
    call print

.L04:
    
    mov r12,1

.L05:
    
    cmp r12d, dword [rel ndfs]
    jge .L1

    movzx eax,word [rsp + r12 * pollfd_size + pollfd.revents]
    test ax,POLLIN | POLLERR | POLLHUP
    jz .L08

    mov rdi,1024
    call vi_malloc

    mov r13,rax
    
    mov rax,SYS_recvfrom
    mov edi,dword [rsp + r12 * pollfd_size + pollfd.fd]
    mov rsi,r13
    mov rdx,1024
    xor r10,r10
    xor r8,r8
    xor r9,r9
    syscall

    cmp rax,0
    jg .L07
    
    cmp rax,0
    je .L06
    
    cmp rax,-EAGAIN
    je .L08

.L06:
    
    mov rax,SYS_close
    mov edi, dword [rsp + r12 * pollfd_size + pollfd.fd]
    syscall
    
    movzx rax, dword [rel ndfs]
    sub rax,1

    mov edi, dword [rsp + rax * pollfd_size + pollfd.fd]
    mov dword [rsp + r12 * pollfd_size + pollfd.fd],edi

    dec dword [rel ndfs]
    inc r12

    mov rdi,r13
    call vi_free

    jmp .L05

.L07:
    
    lea rdi,[rel HEADER]
    call strlen

    mov rdx,rax
    
    mov rax,SYS_sendto
    mov edi,dword [rsp + r12 * pollfd_size + pollfd.fd]
    lea rsi,[rel HEADER]
    mov r10,MSG_NOSIGNAL
    xor r8,r8
    xor r9,r9
    syscall
    
    mov rdi,r13
    call print

    mov rdi,r13
    call vi_free
    
    mov rax,SYS_shutdown
    mov edi,dword [rsp + r12 * pollfd_size + pollfd.fd]
    mov esi,SHUT_RDWR
    syscall
    
.L08:
    inc r12
    jmp .L05

    add rsp,pollfd_size * MAX_CLIENT

    leave
    xor rax,rax
    pop r12
    pop r13
    pop rbx

    ret

.E01:

    lea rdi,[rel INT_S_E1]
    call print

    ud2

.E02:

    lea rdi,[rel INT_S_E2]
    call print

.E03:

    lea rdi,[rel INT_S_E3]
    call print

    ud2

_start:

    xor rbp,rbp 
    and rsp,-16 

    push rbx
    push r12

    call init_runtime

    call main
    
    pop r12
    pop rbx

    mov rdi,rax
    mov rax,60
    syscall

section .note.GNU-stack,"",@progbits