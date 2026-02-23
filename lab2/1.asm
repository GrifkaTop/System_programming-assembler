format ELF64
public _start

section '.data' writeable
    msg db 'ywSzWnIvoXjsEqgFRwuyZYQwUGXWv'
    msg_len = $ - msg 

section '.text' executable
_start:
    mov rsi, msg + msg_len - 1 ; Адрес последнего символа
    mov rbx, msg_len           ; Сколько букв нам надо напечатать

reverse_loop:
    push rbx                   ; Сохраняем счетчик 
    
    ; Печатаем 1 символ, на который указывает RSI
    mov eax, 1                 ; Системный вызов №1 
    mov edi, 1                 ; Куда: в стандартный вывод (экран)
    mov edx, 1                 ; Сколько байт: 1
    syscall

    pop rbx                    ; Возвращаем счетчик
    dec rsi                    ; Переходим к ПРЕДЫДУЩЕМУ символу
    dec rbx                    ; Уменьшаем общее количество оставшихся букв
    jnz reverse_loop           ; Если еще не 0, повторяем

    mov eax, 60                ; Выход
    xor edi, edi
    syscall