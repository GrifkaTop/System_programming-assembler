format ELF64
public _start

;-------------------------------- ДАННЫЕ ------------------ --------------
section '.data' writeable
    fd_in    dq 0
    fd_out   dq 0
    k_pos    dq 0
    m_steps  dq 0
    char_buf db 0
    minus_char   db '-'    
    print_buffer rb 32

; -------------------------------- КОД ------------------ --------------
section '.text' executable
_start:
    ; Аргументы в стеке: 
    ; [rsp] - argc (должно быть 5: имя программы, in, out, k, m)
    ; [rsp+16] - input file
    ; [rsp+24] - output file
    ; [rsp+32] - k (стартовая позиция)
    ; [rsp+40] - m (количество шагов раскачки)
    
    mov rax, [rsp]
    cmp rax, 5
    jl error_exit

    ; 1. Открытие входного файла
    mov rax, 2          ; sys_open
    mov rdi, [rsp + 16] 
    mov rsi, 0          ; O_RDONLY
    syscall
    mov [fd_in], rax
    test rax, rax
    js error_exit  

    ; 2. Создание выходного файла
    mov rax, 2
    mov rdi, [rsp + 24]
    mov rsi, 65         ; O_WRONLY | O_CREAT
    mov rdx, 0644o
    syscall
    mov [fd_out], rax

    ; 3. Конвертация параметров k и m
    mov rsi, [rsp + 32]
    call atoi
    mov [k_pos], rax

    mov rsi, [rsp + 40]
    call atoi
    mov [m_steps], rax

    ; 4. Цикл раскачки
    ; r15 — текущее смещение (от 0 до m)
    xor r15, r15

swing_loop:
    ; 1: Запись символа (k + r15)
    mov rdi, [k_pos]
    add rdi, r15
    call seek_read_write

    ; Если r15 = 0, то (k - 0) это та же позиция, пропускаем вторую запись
    test r15, r15
    jz next_step

    ; 2: Запись символа (k - r15)
    mov rdi, [k_pos]
    sub rdi, r15
    call seek_read_write


next_step: ; Увеличиваем r15 и проверяем, не превысили ли m
    inc r15
    cmp r15, [m_steps]
    jle swing_loop

close_exit: ; Закрываем файлы и выходим
    mov rax, 3
    mov rdi, [fd_in]
    syscall
    mov rax, 3
    mov rdi, [fd_out]
    syscall
    mov rax, 60
    xor rdi, rdi
    syscall

error_exit: ;
    mov rax, 60
    mov rdi, 1
    syscall

; ---- Вспомогательная функция: seek -> read -> write -------------------------------
; seek - установка указателя в файле
seek_read_write:
    ;rdx - смещение от начала файла
    ; rdi - позиция для чтения (k ± r15)
    ; Возвращает 0 при ошибке, 1 при успешной записи символа
    push rdi
    ; Установка указателя в файле
    mov rax, 8          ; sys_lseek
    mov rdi, [fd_in]
    pop rsi             ; смещение из rdi
    mov rdx, 0          ; SEEK_SET (от начала файла)
    syscall
    
    test rax, rax       ; Проверка на отрицательное смещение или ошибку
    js .ret

    ; Чтение одного символа
    mov rax, 0          ; sys_read
    mov rdi, [fd_in]
    mov rsi, char_buf
    mov rdx, 1
    syscall
    
    cmp rax, 1          ; Если не удалось прочитать байт (конец файла), выходим
    jne .ret

    ; Запись одного символа
    mov rax, 1          ; sys_write
    mov rdi, [fd_out]
    mov rsi, char_buf
    mov rdx, 1
    syscall
.ret:
    ret

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
    sub bl, '0'             ; преобразуем символ в число
    imul rax, 10            ; умножаем текущий результат на 10
    add rax, rbx            ; добавляем новую цифру
    inc rsi                 ; следующий символ (++)
    jmp .loop
.done:
    ret
