format ELF64
public _start

_start:
    ; 1. Проверяем, передан ли символ (argc >= 2)
    ; [rsp] - argc, [rsp+8] - имя программы, [rsp+16] - адрес первого аргумента
    mov rax, [rsp]
    cmp rax, 2
    jl exit                 ; Если аргументов нет, выходим

    ; 2. Получаем адрес строки первого аргумента
    mov rsi, [rsp + 16]     
    
    ; 3. Извлекаем первый символ этой строки
    xor rax, rax            ; Чистим RAX
    mov al, [rsi]           ; Копируем 1 байт (код символа) в младший байт RAX
    
    ; Теперь в RAX лежит числовое значение ASCII-кода 
    
    ; 4. Вызываем функцию печати из library.asm 
    call print_int

    ; Печатаем перевод строки
    mov rax, 1
    mov rdi, 1
    mov rsi, nl
    mov rdx, 1
    syscall

exit:
    mov eax, 60
    xor edi, edi
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

;-------------------------------- ДАННЫЕ ------------------ --------------
section '.data' writeable
    nl db 10
    minus_char db '-'
    print_buffer rb 32

