[bits 64]

SYS_open equ 2
O_RDONLY equ 0

struc FileHandler
    .login_page: resq 1
    .register_page: resq 1
endstruc