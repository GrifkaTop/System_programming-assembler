; n - целое число, введенное пользователем
; Вычислить сумму 1 - 2^2 + 3^2 - ... + (-1)^(n-1) * n^2
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

    ; 2. Конвертация в число n
    mov rsi, input_buf
    call atoi
    mov [n_val], rax

    test rax, rax
    jz nulle

    ; 3. Вычисление суммы 1 - 2^2 + 3^2 - ... + (-1)^(n-1) * n^2
    xor r12, r12        ; r12 = sum (Ответ)
    mov rbx, 1          ; rbx = i


loop_start:
    mov rax, rbx ; rax = rbx = i
    imul rax, rax       ; rax = i * i

    test rbx, 1         ; проверка на нечетность i (последний бит)
    jnz add_step        ; если i нечетное, добавляем к сумме
    sub r12, rax        ; если четное, вычитаем
    jmp next_iter 

add_step:
    add r12, rax        ; если нечетное, прибавляем

next_iter:
    inc rbx
    cmp rbx, [n_val]
    jle loop_start ; если i <= n, продолжаем цикл

    ; 4. Печать результата
    mov rax, r12
    call print_int

    ; Перенос строки
    mov rax, 1
    mov rdi, 1
    mov rsi, nl
    mov rdx, 1
    syscall 

nulle:
    ; Если n = 0, то результат 0, просто печатаем его
    mov rax, 0
    call print_int
    jz exit

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
    nl           db 10  
    print_buffer rb 32