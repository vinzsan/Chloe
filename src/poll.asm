[bits 64]

POLLIN      equ 0x0001
POLLPRI     equ 0x0002
POLLOUT     equ 0x0004

POLLRDNORM  equ 0x0040
POLLRDBAND  equ 0x0080
POLLWRNORM  equ 0x0100
POLLWRBAND  equ 0x0200

POLLERR     equ 0x0008
POLLHUP     equ 0x0010
POLLNVAL    equ 0x0020

POLLRDHUP   equ 0x2000

SYS_poll equ 7

struc pollfd
    .fd: resd 1
    .event: resw 1
    .revents: resw 1
endstruc

%if pollfd_size != 8
    %error "pollfd struct size mismatch,unaligned"
%endif

