; Реализация алгоритма сортировки массива (методом пузырька)
sort_array:
    push rax
    push rbx
    push rcx
    push rdx
    push rsi
    push r8
    push r9

    mov r8, [count]
    cmp r8, 1
    jle .sort_done           ; Если 0 или 1 элемент, сортировать нечего

    dec r8                   ; n-1 проходов
.outer_loop:
    mov rsi, array           ; Начало массива
    mov rcx, r8              ; Счетчик внутреннего цикла = r8
.inner_loop:
    mov rax, [rsi]           ; Текущий элемент
    mov rbx, [rsi+8]         ; Следующий элемент
    cmp rax, rbx
    jle .no_swap
    ; Меняем местами
    mov [rsi], rbx
    mov [rsi+8], rax
.no_swap:
    add rsi, 8               ; Переходим к следующей паре
    loop .inner_loop         ; Уменьшает rcx и прыгает

    dec r8                   ; Уменьшаем область сортировки
    jnz .outer_loop

.sort_done:
    pop r9
    pop r8
    pop rsi
    pop rdx
    pop rcx
    pop rbx
    pop rax
    ret