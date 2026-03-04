format ELF64
public _start

section '.data' writable
    msg_start    db "Сервер запущен. Ожидание клиента...", 10, 0
    msg_conn     db "Клиент подключен. ждем q", 10, 0
    fmt_res      db "Среднее значение: ", 0
    
    server_addr:
        dw 2            ; AF_INET
        db 0x1F, 0x90   ; Port 8080 (0x1F90)
        dd 0            ; INADDR_ANY
        dq 0

section '.bss' writable
    server_sock  rq 1
    client_sock  rq 1
    buffer       rb 256
    sum          rq 1    ; Сумма чисел
    count        rq 1    ; Количество чисел

section '.text' executable
_start:
    ; 1. Создание сокета
    mov rax, 41         ; sys_socket
    mov rdi, 2          ; AF_INET
    mov rsi, 1          ; SOCK_STREAM
    xor rdx, rdx
    syscall
    mov [server_sock], rax

    ; 2. Bind
    mov rax, 49         ; sys_bind
    mov rdi, [server_sock]
    lea rsi, [server_addr]
    mov rdx, 16
    syscall

    ; 3. Listen
    mov rax, 50         ; sys_listen
    mov rdi, [server_sock]
    mov rsi, 1
    syscall

    mov rdi, msg_start
    call print_str

    ; 4. Accept
    mov rax, 43         ; sys_accept
    mov rdi, [server_sock]
    xor rsi, rsi
    xor rdx, rdx
    syscall
    mov [client_sock], rax

    mov rdi, msg_conn
    call print_str

    xor r12, r12        ; Сумма 
    xor r13, r13        ; Счетчик 

main_loop:
    ; Читаем число от клиента
    mov rax, 0          ; sys_read
    mov rdi, [client_sock]
    lea rsi, [buffer]
    mov rdx, 255
    syscall
    
    test rax, rax
    jz calc_and_send    ; Если клиент отключился

    ; Проверка на символ выхода 'q'
    cmp byte [buffer], 'q'
    je calc_and_send

    ; Превращаем строку в число
    lea rsi, [buffer]
    call str_to_int     ; Результат в RAX
    
    add r12, rax        ; sum += val
    inc r13             ; count++
    jmp main_loop

calc_and_send:
    test r13, r13
    jz exit_server      ; Если чисел не было

    ; Считаем среднее: RAX = r12 / r13
    mov rax, r12
    xor rdx, rdx
    div r13            

    ; Превращаем результат обратно в строку для отправки
    lea rdi, [buffer]
    call int_to_str     ; Записывает в buffer

    ; Отправляем клиенту
    mov rdx, rax        ; Длина строки из int_to_str
    mov rax, 1          ; sys_write
    mov rdi, [client_sock]
    lea rsi, [buffer]
    syscall

exit_server:
    mov rax, 60
    xor rdi, rdi
    syscall

; --- Утилиты ---

str_to_int: ; RSI -> Buffer, RAX <- Result
    xor rax, rax
    xor rcx, rcx
.loop:
    mov cl, [rsi]
    cmp cl, '0'
    jb .done
    cmp cl, '9'
    ja .done
    sub cl, '0'
    imul rax, 10
    add rax, rcx
    inc rsi
    jmp .loop
.done:
    ret

int_to_str: ; RAX = число, RDI = буфер. Возвращает длину в RAX
    mov rbx, 10
    xor rcx, rcx
.push_chars:
    xor rdx, rdx
    div rbx
    add rdx, '0'
    push rdx
    inc rcx
    test rax, rax
    jnz .push_chars
    mov r8, rcx         ; Сохраним длину
.pop_chars:
    pop rax
    stosb
    loop .pop_chars
    mov byte [rdi], 10  ; Добавим перевод строки
    mov rax, r8
    inc rax             ; +1 для '\n'
    ret

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