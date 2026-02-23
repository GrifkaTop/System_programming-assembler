;--Задача 4: Подсчет простых чисел
do_primes: 
    
    xor r12, r12            ; Общий счетчик простых чисел
    mov rcx, [count]
    xor rbx, rbx            ; Смещение в массиве


.p_array_loop:
    push rcx 
    mov rax, [array + rbx]
    
    cmp rax, 2 ; Простые числа начинаются с 2
    jl .next_item ; Если число меньше 2, пропускаем
    je .is_prime ; 2 - простое число
    
    test rax, 1  ;
    jz .next_item  ; Если число четное и не равно 2, пропускаем

    mov rdi, rax  ; Сохраняем число для проверки
    mov rsi, 3 ; Начинаем проверку делителей с 3

; Цикл проверки делителей от 3 до sqrt(rax) с шагом 2 (только нечетные)
.p_div_loop:
    mov rax, rsi
    mul rax ; rax = rsi * rsi
    cmp rax, rdi ; Сравниваем rsi^2 с числом
    ja .is_prime ; Если rsi^2 > число, значит делителей нет, это простое число
    
    mov rax, rdi ;
    xor rdx, rdx ;
    div rsi ; rax = rdi / rsi, rdx = остаток
    test rdx, rdx ; Проверяем остаток от деления
    jz .next_item
    add rsi, 2 ; rsi = rsi + 2
    jmp .p_div_loop

.is_prime:
    inc r12

.next_item:
    add rbx, 8 ;
    pop rcx
    loop .p_array_loop

    mov rsi, msg_p
    call print_str
    
    mov rax, r12
    call print_int
    jmp exit_child