;n - целое число, введенное пользователем
;Вывести количество чисел от 1 до n, которые не делятся на 5 и 11 одновременно

format ELF64
public _start


;-------------------------------- ДАННЫЕ ------------------ --------------
section '.data' writeable
    n_val        dq 0 ; Здесь будет храниться n после конвертации
    input_buf    rb 16
    minus_char   db '-'
    nl           db 10  
    print_buffer rb 32

;-------------------------------- КОД ------------------ --------------
section '.text' executable
_start:
    ; 1. Чтение n из stdin
    mov rax, 0          ; sys_read
    mov rdi, 0          ; stdin
    mov rsi, input_buf
    mov rdx, 16
    syscall

    ; 2. Конвертация в число n
    mov rsi, input_buf
    call atoi
    mov [n_val], rax
    
    test rax, rax
    jz exit

    ; 3. Вычисления
    ; rbx — текущее число (i), r12 — счетчик подходящих чисел
    xor r12, r12
    mov rbx, 1

loop_start:
    ; Проверка деления на 11
    xor rdx, rdx
    mov rax, rbx
    mov rcx, 11
    div rcx
    test rdx, rdx       ; rdx — остаток
    jnz count_it        ; если остаток != 0, число НЕ делится на 11 (подходит)

    ; Проверка деления на 5
    xor rdx, rdx
    mov rax, rbx
    mov rcx, 5
    div rcx
    test rdx, rdx
    jnz count_it        ; если остаток != 0, число НЕ делится на 5 (подходит)

    jmp next_iter       ; делится на оба — НЕ считаем

count_it:
    inc r12 ; увеличиваем счетчик подходящих чисел

next_iter:
    inc rbx
    cmp rbx, [n_val]
    jle loop_start

    ; 4. Печать результата
    mov rax, r12
    call print_int

    ; Перенос строки
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
