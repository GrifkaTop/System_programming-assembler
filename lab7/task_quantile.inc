; Реализация алгоритма для вычисления 0.75 квантиля в массиве
do_quantile:
    
    call sort_array        ; сортируем
    
    ; Расчет индекса динамически
    mov rax, [count]
    mov rbx, 75 
    mul rbx                ; rax = count * 75
    mov rbx, 100 
    div rbx                ; rax = (count * 75) / 100
    
    ; Извлекаем значение из массива по вычисленному индексу
    mov rsi, msg_q
    call print_str

    mov rax, [array + rax*8]
    call print_int
    jmp exit_child