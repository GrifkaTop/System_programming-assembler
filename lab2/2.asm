format ELF64
public _start

section '.data' writeable
    char db '!'
    nl   db 10

section '.text' executable
_start:
    mov r8, 6          ; Счётчик строк (M)
outer_loop:
    mov r9, 6          ; Счётчик символов (K)
inner_loop:
    ; Сохраняем регистры, так как syscall может их изменить
    push r8 r9
    mov eax, 1         ; sys_write
    mov edi, 1         ; stdout
    mov rsi, char
    mov edx, 1
    syscall
    pop r9 r8

    dec r9
    jnz inner_loop     ; Пока не напечатаем 9 символов

    ; Печать переноса строки
    push r8
    mov eax, 1
    mov edi, 1
    mov rsi, nl
    mov edx, 1
    syscall
    pop r8

    dec r8
    jnz outer_loop     ; Пока не напечатаем 5 строк

    mov eax, 60        ; sys_exit
    xor edi, edi
    syscall