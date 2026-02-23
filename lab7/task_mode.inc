; Реализация алгоритма для подсчета моды в массиве
do_mode:
    
    xor r12, r12            ; r12 - максимальное количество повторений
    xor r13, r13            ; r13 - само число (мода)
    mov rcx, [count]        ; Внешний цикл по всему массиву

.m_outer:
    push rcx
    mov rsi, [count]        ; Внутренний цикл
    mov rbx, [array + rcx*8 - 8] ; Берем текущее число для сравнения
    xor rdx, rdx            ; rdx - счетчик повторений текущего числа

.m_inner:
    cmp [array + rsi*8 - 8], rbx
    jne .m_skip
    inc rdx                 ; Если совпало, увеличиваем счетчик

.m_skip:
    dec rsi
    jnz .m_inner

    cmp rdx, r12            ; Если текущее число встречается чаще, чем мода
    jle .m_next
    mov r12, rdx            ; Обновляем рекорд частоты
    mov r13, rbx            ; Обновляем саму моду

.m_next:
    pop rcx
    loop .m_outer
    
    mov rsi, msg_m
    call print_str
    
    mov rax, r13
    
    call print_int
    jmp exit_child