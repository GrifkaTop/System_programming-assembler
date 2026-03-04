format ELF64

public main
extrn printf 
extrn exit

; -------------------- ДАННЫЕ -------------------------------
section '.data' writeable
    fmt_header db " n  |      x_n      |    f(x_n)    ", 10
               db "------------------------------------", 10, 0
    fmt_row    db "%3d | %12.10f | %12.10f", 10, 0
    fmt_res    db 10, "Root found: %12.10f", 10, 0

    half       dq 0.5
    x_curr     dq 0.5 ; начальное приближение x1
    eps        dq 0.0001     ; Точность        
    x_next     dq 0.0
    two        dq 2.0
    f_val      dq 0.0
    iter_count dd 0

section '.text' executable

main:
    and rsp, -16               ; Выравнивание стека

    ; Вывод заголовка
    lea rdi, [fmt_header]
    xor eax, eax
    call printf

.loop_iteration:
    inc [iter_count]

; --- 1. Вычисляем f(x) = ln(x) + cos(x) - 2x ---
    fld [x_curr]
    fcos               ; st0 = cos(x)
    fldln2             ; константа для ln
    fld [x_curr]       ; x
    fyl2x              ; st0 = ln(x), st1 = cos(x)
    faddp st1, st0     ; st0 = ln(x) + cos(x)
    fst [f_val]        ; Сохраняем f(x) для вывода

    ; --- 2. Вывод текущего состояния ---
    movsd xmm0, qword [x_curr]
    movsd xmm1, qword [f_val]
    mov edi, [iter_count]
    lea rdi, [fmt_row]
    mov esi, [iter_count]
    mov eax, 2
    call printf

; --- 3. Вычисляем x_next = x - 0.5 * f(x) ---
    fmul qword [half]  ; st0 = 0.5 * f(x) (
    fsubr [x_curr]     ; st0 = x_curr - (0.5 * f(x))
    fst [x_next]       ; Новое приближение

    ; --- 4. Проверка на выход: |x_next - x_curr| < eps ---
    fsub [x_curr]
    fabs                       ; st0 = |x_next - x_curr|
    fcomp [eps]                ; Сравниваем с eps
    fstsw ax
    sahf
    jb .done                   ; Если разница меньше eps — выходим

    ; Обновляем x_curr и повторяем
    fld [x_next]
    fstp [x_curr]
    
    ; Предохранитель от бесконечного цикла
    cmp [iter_count], 100
    jl .loop_iteration

.done:
    ; Финальный результат
    lea rdi, [fmt_res]
    movsd xmm0, qword [x_next]
    mov eax, 1
    call printf

    xor edi, edi
    call exit