;n - целое число, введенное пользователем
;Вывести все числа от 1 до n, которые делятся на свои две последние цифры

format ELF64
public _start

section '.text' executable
_start:
    ; 1. Чтение n из stdin
    mov rax, 0
    mov rdi, 0
    mov rsi, input_buf
    mov rdx, 16
    syscall

    ; 2. Конвертация n
    mov rsi, input_buf
    call atoi
    mov [n_val], rax
    
    test rax, rax
    jz exit

    ; 3. Перебор чисел от 1 до n
    mov rbx, 1          ; rbx — текущее число (i)

main_loop:
    ; Получаем две последние цифры
    ; rax = i % 10 (последняя цифра)
    ; (i / 10) % 10 (предпоследняя цифра)
    
    mov rax, rbx
    xor rdx, rdx
    mov rcx, 10
    div rcx
    mov r13, rdx        ; r13 = последняя цифра (d2)
    
    xor rdx, rdx
    div rcx
    mov r14, rdx        ; r14 = предпоследняя цифра (d1)

    ; Проверка на 0 (на ноль делить нельзя)
    test r13, r13
    jz next_i
    test r14, r14
    jz next_i

    ; Проверка деления на d2 (последняя цифра)
    mov rax, rbx
    xor rdx, rdx
    div r13
    test rdx, rdx
    jnz next_i          ; если не делится, идем дальше

    ; Проверка деления на d1 (предпоследняя цифра)
    mov rax, rbx
    xor rdx, rdx
    div r14
    test rdx, rdx
    jnz next_i          ; если не делится, идем дальше

    ; Если прошли все проверки — печатаем число
    mov rax, rbx
    call print_int
    
    ; Печать пробела между числами
    mov rax, 1
    mov rdi, 1
    mov rsi, space_char
    mov rdx, 1
    syscall

next_i:
    inc rbx
    cmp rbx, [n_val]
    jle main_loop

    ; Печать переноса строки в конце
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
    n_val        dq 0
    input_buf    rb 16
    minus_char   db '-'
    space_char   db ' '
    nl           db 10  
    print_buffer rb 32