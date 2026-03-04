format ELF64
public _start

section '.data' writable
    prompt       db "Введите число ('q' -конец): ", 0
    res_msg      db "Результат от сервера: ", 0
    ip_addr      db "127.0.0.1", 0
    
    server_addr:
        dw 2
        db 0x1F, 0x90
        dd 0 ; Будет заполнено
        dq 0

section '.bss' writable
    sock_fd     rq 1
    buffer      rb 256

section '.text' executable
_start:
    mov dword [server_addr + 4], 0x0100007F ; 127.0.0.1 в сетевом порядке

    ; Создание сокета
    mov rax, 41
    mov rdi, 2
    mov rsi, 1
    xor rdx, rdx
    syscall
    mov [sock_fd], rax

    ; Connect
    mov rax, 42
    mov rdi, [sock_fd]
    lea rsi, [server_addr]
    mov rdx, 16
    syscall

input_loop:
    ; Просим число
    mov rdi, prompt
    call print_str

    ; Читаем с клавиатуры
    mov rax, 0
    mov rdi, 0
    lea rsi, [buffer]
    mov rdx, 255
    syscall
    
    ; Отправляем на сервер (включая символ 'q' если ввели его)
    mov rdx, rax
    mov rax, 1
    mov rdi, [sock_fd]
    lea rsi, [buffer]
    syscall

    cmp byte [buffer], 'q'
    je wait_result
    jmp input_loop

wait_result:
    ; Получаем ответ
    mov rax, 0
    mov rdi, [sock_fd]
    lea rsi, [buffer]
    mov rdx, 255
    syscall
    
    mov rbx, rax ; Сохраним длину

    mov rdi, res_msg
    call print_str

    ; Печатаем само число
    mov rax, 1
    mov rdi, 1
    lea rsi, [buffer]
    mov rdx, rbx
    syscall

    ; Выход
    mov rax, 60
    xor rdi, rdi
    syscall

print_str:
    push rdi
    xor rdx, rdx
  .l: cmp byte [rdi+rdx], 0
    je .p
    inc rdx
    jmp .l
  .p: mov rax, 1
    mov rsi, rdi
    mov rdi, 1
    syscall
    pop rdi
    ret