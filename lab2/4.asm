format ELF64
public _start

section '.data' writeable
    num      dq 11223
    newline  db 10
    buffer   db 10 dup(0)    ; Буфер, куда запишем цифры для печати

section '.text' executable
_start:
    ; --- Часть 1: Считаем сумму цифр ---
    mov rax, [num]
    xor rbx, rbx            ; Здесь будет итоговая сумма

calc_sum:
    xor rdx, rdx
    mov rcx, 10
    div rcx                 ; RAX = RAX / 10, RDX = остаток (цифра)
    add rbx, rdx
    test rax, rax
    jnz calc_sum            ; Повторяем, пока число не кончится

    ;Перевод суммы в строку ---
    mov rax, rbx            ; Кладем сумму в RAX для деления
    lea rdi, [buffer + 9]   ; Начинаем заполнять буфер с конца

convert_loop:
    xor rdx, rdx
    mov rcx, 10
    div rcx                 ; Делим сумму на 10
    add dl, '0'             ; Превращаем цифру в символ (например, 4 -> '4')
    mov [rdi], dl           ; Пишем символ в буфер
    dec rdi                 ; Сдвигаемся влево
    test rax, rax
    jnz convert_loop        ; Пока сумма не кончилась

    ; После цикла RDI указывает на место ПЕРЕД первым символом.
    ; Нам нужно сдвинуть его вперед на 1, чтобы он указывал точно на начало строки. 
    inc rdi

    ; Вывод
    mov rsi, rdi            ; Адрес начала строки в буфере
    mov rdx, buffer + 10    ; Конец буфера
    sub rdx, rsi            ; Вычисляем длину строки (конец - начало)
    
    mov eax, 1              ; sys_write
    mov edi, 1              ; stdout
    syscall

    ; Печатаем перенос строки (красиво же должно быть)
    mov eax, 1
    mov edi, 1
    mov rsi, newline
    mov edx, 1
    syscall

    ; --- Выход ---
    mov eax, 60
    xor edi, edi
    syscall