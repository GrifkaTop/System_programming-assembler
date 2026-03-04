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

    eps        dq 0.000001     ; Точность
    x_curr     dq 0.5          ; Начальное приближение x1
    x_next     dq 0.0
    four       dq 4.0      
    f_val      dq 0.0
    iter_count dd 0

section '.text' executable

main:
    push rbp
    mov rbp, rsp
    and rsp, -16               ; Выравнивание стека

    ; Вывод заголовка
    lea rdi, [fmt_header]
    xor eax, eax
    call printf

.loop_iteration:
    inc [iter_count]

    ; --- 1. Вычисляем f(x) = 4x + ln(x) - cos(x) ---
    finit
    
    ; Считаем ln(x)
    fldln2
    fld qword [x_curr]
    fyl2x                      ; st0 = ln(x)
    
    ; Считаем cos(x)
    fld qword [x_curr]
    fcos                       ; st0 = cos(x), st1 = ln(x)
    
    ; ln(x) - cos(x)
    fsubp st1, st0             ; st0 = ln(x) - cos(x)
    
    ; 4x
    fld qword [x_curr]
    fmul qword [four]          ; st0 = 4x, st1 = ln(x) - cos(x)
    
    ; f(x) = 4x + ln(x) - cos(x)
    faddp st1, st0             ; st0 = 4x + ln(x) - cos(x)
    fst qword [f_val]          ; Сохраняем f(x) для таблицы

    ; --- 2. Вывод текущего состояния ---
    lea rdi, [fmt_row]
    mov esi, [iter_count]
    movsd xmm0, qword [x_curr]
    movsd xmm1, qword [f_val]
    mov eax, 2
    call printf

    ; --- 3. Вычисляем x_next = (cos(x) - ln(x)) / 4 ---
    fld qword [x_curr]
    fcos                       ; st0 = cos(x)
    
    fldln2
    fld qword [x_curr]
    fyl2x                      ; st0 = ln(x), st1 = cos(x)
    
    fsubp st1, st0             ; st0 = cos(x) - ln(x)
    fdiv qword [four]          ; st0 = (cos(x) - ln(x)) / 4
    fst qword [x_next]         ; Сохраняем x_next

    ; --- 4. Проверка на выход: |x_next - x_curr| < eps ---
    fsub qword [x_curr]
    fabs                       
    fcomp qword [eps]          
    fstsw ax
    sahf
    jb .done                   ; Если разница меньше eps — выходим

    ; Обновляем x_curr и повторяем
    movsd xmm0, qword [x_next]
    movsd qword [x_curr], xmm0
    
    ; Предохранитель
    cmp [iter_count], 100
    jl .loop_iteration

.done:
    ; Финальный результат
    lea rdi, [fmt_res]
    movsd xmm0, qword [x_next]
    mov eax, 1
    call printf

    mov rsp, rbp
    pop rbp
    xor edi, edi
    call exit