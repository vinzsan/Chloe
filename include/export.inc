extern sbrk
extern print
extern printf

extern vi_malloc
extern vi_free

extern mutex_lock
extern mutex_unlock

extern init_runtime
extern spawn_thread

extern strlen
extern strcmp

SYS_write equ 1
SYS_clock_nanosleep equ 230

STDOUT_FILENO equ 1
CLOCK_MONOTONIC equ 1

SYS_mmap equ 9
SYS_munmap equ 11
SYS_socket equ 41
SYS_setsockopt equ 54
SYS_bind equ 49
SYS_accept equ 43
SYS_listen equ 50
SYS_read equ 0
SYS_sendto equ 44
SYS_recvfrom equ 45
SYS_close equ 3

AF_INET equ 2
SOCK_STREAM equ 1
SO_REUSSEADDR equ 2
SOL_SOCKET equ 1
IPPROTO_TCP equ 6
TCP_NODELAY equ 1

PROT_READ equ 0x01
PROT_WRITE equ 0x02

MAP_PRIVATE equ 0x02
MAP_ANONYMOUS equ 0x20

EINTR equ 4

%include "include/poll.inc"
%include "include/socket.inc"
%include "include/fcntl.inc"