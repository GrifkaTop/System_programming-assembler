format ELF64
public _start

section '.data' writeable
    char db '8'
    nl   db 10

section '.text' executable
_start:
    mov r8, 1          ; Текущее количество символов в строке
tri_loop:
    mov r9, r8         ; Внутренний счетчик равен номеру строки
line_loop:
    push r8 r9
    mov eax, 1
    mov edi, 1
    mov rsi, char
    mov edx, 1
    syscall
    pop r9 r8
    dec r9
    jnz line_loop

    push r8
    mov eax, 1
    mov rsi, nl
    mov edx, 1
    syscall
    pop r8

    inc r8
    cmp r8, 10          ; Повторяем, пока не дойдем до 7-й строки
    jne tri_loop

    mov eax, 60
    xor edi, edi
    syscall