; Реализация алгоритма для получения 5-го элемента после сортировки массива
do_fifth:
    
    call sort_array        ; ссортируем
    
    ; Проверка: если count < 5, выведем последний доступный, иначе 5-й
    mov rax, [count]
    cmp rax, 5
    jl .low_count
    mov rax, [array + 4*8] ; 5-й элемент (индекс 4)
    jmp .print
    
.low_count:
    mov rax, -1      ; Если массив слишком мал, возвращаем -1
    
.print:
    mov rsi, msg_f
    call print_str

    call print_int
    jmp exit_child