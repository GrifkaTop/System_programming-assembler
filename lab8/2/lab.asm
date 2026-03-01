format ELF64

public main
extrn printf 
extrn exit
; -------------------- ДАННЫЕ -------------------------------
section '.data' writeable
    ; Форматы для вывода таблицы
    fmt_header db "     x     |    f(x)    |    Sum     | n", 10
               db "------------------------------------------", 10, 0
    fmt_row    db "%10.5f | %10.5f | %10.5f | %d", 10, 0

    eps        dq 0.00001  ; Заданная точность (epsilon)
    three      dq 3.0 
    one_fourth dq 0.25
    five       dq 5.0

    x_step     dq 0.0
    x_val      dq 0.0
    ref_val    dq 0.0
    sum_val    dq 0.0
    n_val      dq 0.0

    int_n      dd 0
    step_count dd 0

section '.text' executable

main:
    ; Выравнивание стека для корректного вызова C-функций (System V ABI)
    and rsp, -16

    ; 1. Вывод заголовка таблицы
    lea rdi, [fmt_header]
    xor eax, eax
    call printf

    ; 2. Вычисление шага: x_step = pi / 5
    fldpi
    fdiv [five]
    fstp [x_step]

    ; Инициализация x = pi / 5
    fld [x_step]
    fstp [x_val]

    mov [step_count], 1

.loop_x:
    ; --- Вычисление эталона: f(x) = 0.25 * (x^2 - pi^2 / 3) ---
    fld [x_val]
    fmul st0, st0      ; st0 = x^2
    fldpi
    fmul st0, st0      ; st0 = pi^2, st1 = x^2
    fdiv [three]       ; st0 = pi^2/3, st1 = x^2
    fsubp st1, st0     ; st0 = x^2 - pi^2/3
    fmul [one_fourth]  ; st0 = 0.25 * (x^2 - pi^2/3)
    fstp [ref_val]

    ; --- Вычисление суммы ряда ---
    fldz
    fstp [sum_val]     ; sum = 0

    fld1
    fstp [n_val]       ; n = 1

.loop_series:
    ; Член ряда term = cos(n*x) / n^2
    fld [n_val]
    fmul [x_val]
    fcos               ; st0 = cos(n*x)

    fld [n_val]
    fmul st0, st0      ; st0 = n^2, st1 = cos(n*x)
    fdivp st1, st0     ; st0 = cos(n*x) / n^2

    ; Учет знака (-1)^n (если n нечетное — меняем знак)
    fld [n_val]
    fistp [int_n]
    test [int_n], 1
    jz .even_n
    fchs               ; Смена знака на минус

.even_n:
    ; Прибавляем вычисленный член к общей сумме
    fld st0            ; Дублируем term в стеке FPU
    fadd [sum_val]
    fstp [sum_val]     ; sum = sum + term

    ; Проверка достижения точности: |term| < eps
    fabs               ; st0 = |term|
    fld [eps]          ; st0 = eps, st1 = |term|
    fcomip st0, st1    ; Сравниваем eps и |term|, устанавливаем флаги и выталкиваем eps
    fstp st0           ; Выталкиваем |term| (очистка стека FPU)
    ja .series_done    ; Если eps > |term|, прерываем цикл ряда

    ;(n++)
    fld [n_val]
    fld1
    faddp
    fstp [n_val]
    jmp .loop_series

.series_done:
    ; --- Форматирование и вывод строки таблицы ---
    movsd xmm0, qword [x_val]
    movsd xmm1, qword [ref_val]
    movsd xmm2, qword [sum_val]
    lea rdi, [fmt_row]
    mov esi, [int_n]
    mov eax, 3         ; Сообщаем printf, что используем 3 регистра XMM
    call printf

    ; Переход к следующему значению (x = x + pi/5)
    fld [x_val]
    fadd [x_step]
    fstp [x_val]

    inc [step_count]
    cmp [step_count], 5
    jle .loop_x

    ; Завершение программы
    xor edi, edi
    call exit