format ELF64

public _start

;------------------------------- КОНСТАНТЫ И ДАННЫЕ -------------------------------
section '.data' writable
    msg_enter_ip    db "Введите IP сервера: ", 0
    wait_msg        db "Подключение к серверу...", 10, 0
    ask             db "K", 0 
    err_msg         db "Ошибка подключения!", 10, 0
    
    server_addr:
        dw 2              ; AF_INET
        db 0x1F, 0x90     ; Port 8080
        dd 0              ; IP будет заполнен
        dq 0

section '.bss' writable
    sock_fd         rq 1
    buffer          rb 256
    ip_input        rb 32  

;------------------------------- КОД -------------------------------
section '.text' executable
_start:
    ; 0. Ввод IP
    mov rdi, msg_enter_ip; 
    call std_print_string 

    mov rax, 0          ; sys_read
    mov rdi, 0          ; stdin
    lea rsi, [ip_input]
    mov rdx, 31
    syscall
    
    ; 0.2 Парсинг IP
    lea rsi, [ip_input] 
    lea rdi, [server_addr + 4] 
    call parse_ip

    mov rdi, wait_msg
    call std_print_string

    ; 0.3 Подключение
    mov rax, 41         ; socket
    mov rdi, 2
    mov rsi, 1
    mov rdx, 0
    syscall
    mov [sock_fd], rax

    mov rax, 42         ; connect
    mov rdi, [sock_fd]
    lea rsi, [server_addr]
    mov rdx, 16
    syscall
    
    test rax, rax
    js conn_error

game_loop:
    ; 1. Получение данных от сервера
    mov rax, 0             
    mov rdi, [sock_fd]
    mov rsi, buffer
    mov rdx, 255
    syscall

    test rax, rax
    jz server_disconnected 
    
    ; Сохранение типа сообщения
    mov byte [buffer + rax], 0
    
    ; Печать полученного сообщения 
    mov rdi, buffer
    inc rdi 
    call std_print_string

    ; 2. Подтверждение хода игрока
    mov rax, 1 
    mov rdi, [sock_fd]
    lea rsi, [ask] 
    mov rdx, 1
    syscall

    ; 3. Ожидание ответа от сервера (1 - делать ход, 2 - выход)
    cmp byte [buffer], 1
    je .do_turn
    
    cmp byte [buffer], 2
    je exit_game         

    jmp game_loop

; ОБРАБОТЧИКИ ИГРЫ 
.do_turn:
    ; Читаем ввод игрока 
    mov rax, 0     
    mov rdi, 0     
    lea rsi, [buffer]
    mov rdx, 2      
    syscall
    
    ; Отправляем ход на сервер
    mov rax, 1          
    mov rdi, [sock_fd] 
    lea rsi, [buffer] 
    mov rdx, 1       
    syscall
    
    jmp game_loop


server_disconnected: ;
exit_game: 
    mov rax, 3
    mov rdi, [sock_fd]
    syscall
    
    mov rax, 60
    xor rdi, rdi
    syscall

conn_error: ; Ошибка подключения
    mov rdi, err_msg
    call std_print_string

    mov rax, 60
    mov rdi, 1
    syscall

parse_ip: ; Парсит строку формата "x.x.x.x" в 4 байта по адресу rdi
    push rbx
    push rcx
    push rdx
    
    xor eax, eax    
    xor ecx, ecx    
    xor rdx, rdx    

    .next_char:
        mov bl, [rsi]
        inc rsi
        
        cmp bl, '.' 
        je .save_byte
        cmp bl, 10      
        je .finish
        cmp bl, 0       
        je .finish
        
        sub bl, '0'
        movzx rbx, bl
        
        imul ecx, 10
        add ecx, ebx
        jmp .next_char

    .save_byte:
        mov [rdi], cl
        inc rdi
        xor ecx, ecx
        jmp .next_char

    .finish:
        mov [rdi], cl
        pop rdx
        pop rcx
        pop rbx
        ret

std_print_string:
    push rdi
    xor rdx, rdx
  .loop:
    cmp byte [rdi + rdx], 0
    je .print
    inc rdx
    jmp .loop
  .print:
    mov rax, 1
    mov rsi, rdi
    mov rdi, 1
    syscall
    pop rdi
    ret