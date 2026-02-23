format ELF64
public _start

;-------------------------------- ДАННЫЕ ------------------ --------------

section '.data' writeable
    fd_in        dq 0
    fd_out       dq 0
    k_val        dq 0
    char_buf     db 0
    minus_char   db '-'      
    print_buffer rb 32       ; Буфер для конвертации числа в строку


;-------------------------------- КОД ------------------ --------------
section '.text' executable
_start:
    ; Аргументы: [rsp+16] - input, [rsp+24] - output, [rsp+32] - k
    mov rax, [rsp]
    cmp rax, 4
    jl error_exit

    ; 1. Открытие входного файла (O_RDONLY = 0)
    mov rax, 2          ; sys_open
    mov rdi, [rsp + 16] ; filename
    mov rsi, 0          ; flags
    syscall
    mov [fd_in], rax
    test rax, rax
    js error_exit

    ; 2. Создание/Открытие выходного файла (O_WRONLY|O_CREAT|O_TRUNC)
    mov rax, 2
    mov rdi, [rsp + 24]
    mov rsi, 65         ; O_WRONLY(1) | O_CREAT(64)
    mov rdx, 0644o      ; права доступа
    syscall
    mov [fd_out], rax

    ; 3. Получение k
    mov rsi, [rsp + 32]
    call atoi
    mov [k_val], rax
    ; проверка на 0
    test rax, rax
    jz exit

    mov r12, 1          ; r12 - счетчик текущего символа



process_loop:
    ; Читаем 1 байт
    mov rax, 0          ; sys_read
    mov rdi, [fd_in]
    mov rsi, char_buf
    mov rdx, 1
    syscall
    
    test rax, rax       ; EOF
    jz close_files

    ; Проверяем, является ли символ k-м
    mov rax, r12
    xor rdx, rdx
    div qword [k_val]
    test rdx, rdx
    jnz skip_char

    ; Записываем символ
    mov rax, 1          ; sys_write
    mov rdi, [fd_out]
    mov rsi, char_buf
    mov rdx, 1
    syscall

skip_char:
    inc r12
    jmp process_loop

close_files:
    mov rax, 3 ; sys_close
    mov rdi, [fd_in]
    syscall
    mov rax, 3
    mov rdi, [fd_out]
    syscall

exit:
    mov rax, 60
    xor rdi, rdi
    syscall

error_exit:
    mov rax, 60
    mov rdi, 1
    syscall

; -------------------------------- Функции ------------------ --------------
print_int:
    push rax  
    push rcx 
    push rdx
    push rdi
    push rsi

    ; Обработка отрицательного числа
    test rax, rax
    jns .prepare_convert

    push rax
    mov rax, 1          ; sys_write
    mov rdi, 1          ; stdout
    mov rsi, minus_char
    mov rdx, 1
    syscall
    pop rax
    neg rax             ; замена знака для деления

; Подготовка к конвертации числа в строку
.prepare_convert:
    mov rcx, 10
    mov rdi, print_buffer + 31

; Цикл конвертации числа в строку
.convert_loop:
    xor rdx, rdx 
    div rcx
    add dl, '0'
    mov [rdi], dl 
    dec rdi 
    test rax, rax
    jnz .convert_loop 

    inc rdi
    mov rsi, rdi
    mov rdx, print_buffer + 31
    sub rdx, rsi
    inc rdx

    mov rax, 1
    mov rdi, 1
    syscall

    pop rsi
    pop rdi
    pop rdx
    pop rcx
    pop rax
    ret

; Функция для конвертации строки в число
atoi:
    xor rax, rax            ; здесь будет результат
.loop:
    movzx rbx, byte [rsi]   ; берем символ
    test bl, bl             ; если конец строки (0), выходим
    jz .done
    cmp bl, '0'
    jb .done
    cmp bl, '9'
    ja .done
    sub bl, '0'             ; символ '5' превращаем в число 5
    imul rax, 10            ; умножаем текущий результат на 10
    add rax, rbx            ; добавляем новую цифру
    inc rsi                 ; следующий символ
    jmp .loop
.done:
    ret
