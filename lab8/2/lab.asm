format ELF64
public _start

; Лабораторная работа 8, задание 2
; Вычисление суммы ряда и сравнение с эталоном для различных x и epsilon
; Ряд: Sum = Σ (-1)^n * cos(nx) / n^2, n=1..∞
; Эталон: f(x) = 0.25 * (x^2 - pi^2/3)
; сначала выводим эталон
; Выводим 5 значений п/5, .... до п/1
; все это записываем в таблицу
; также в таблице записать количество членов ряда, необходимых для достижения заданной точности (epsilon)
; точность достигается, когда |Sum - f(x)| < epsilon

extrn printf
extrn exit

section '.data' writeable
    ; Данные без выравнивания
    pi          dq 3.141592653589793
    epsilon     dq 0.0001
    three       dq 3.0
    quarter     dq 0.25
    minus_one   dq -1.0
    ; Маска для модуля (сброс 63-го бита)
    abs_mask    dq 0x7FFFFFFFFFFFFFFF, 0x7FFFFFFFFFFFFFFF
    
    x_values    dq 0.6283185307179586, 1.2566370614359172, \
                   1.8849555921538759, 2.5132741228718345, 3.141592653589793
    
    current_x   dq 0.0
    head_fmt    db 10, '   x   |  f(x) (Ref) |  Sum (Series) | Iterations', 10, \
                   '-------|-------------|---------------|-----------', 10, 0
    row_fmt     db '%.4f |   %.6f  |    %.6f   |    %ld', 10, 0

section '.text' executable
_start:
    sub rsp, 24         ; Резервируем место на стеке (выравнивание + буфер)

    ; Печать заголовка
    mov rdi, head_fmt
    xor rax, rax
    call printf

    mov r12, 0          ; Индекс x (0..4)

main_loop:
    cmp r12, 5
    je all_done

    movsd xmm0, [x_values + r12*8]
    movsd [current_x], xmm0

    ; 1. f(x) = 0.25 * (x^2 - pi^2/3)
    movsd xmm1, [pi]
    mulsd xmm1, xmm1
    divsd xmm1, [three]
    
    movsd xmm2, [current_x]
    mulsd xmm2, xmm2
    subsd xmm2, xmm1
    mulsd xmm2, [quarter]
    movsd xmm10, xmm2   ; xmm10 = Эталон

    ; 2. Ряд: Sum = Σ [(-1)^n * cos(nx)] / n^2
    pxor xmm11, xmm11   ; xmm11 = Sum
    mov r13, 1          ; r13 = n

series_loop:
    ; Аргумент для cos: n * x
    cvtsi2sd xmm0, r13
    mulsd xmm0, [current_x]
    
    ; Вычисляем cos(nx) через FPU (стек x87)
    movsd [rsp], xmm0
    fld qword [rsp]
    fcos
    fstp qword [rsp]
    movsd xmm1, [rsp]   ; xmm1 = cos(nx)

    ; Делим на n^2
    mov rax, r13
    imul rax, rax
    cvtsi2sd xmm2, rax
    divsd xmm1, xmm2

    ; Знак (-1)^n. Для n=1 должен быть минус.
    test r13, 1
    jz sign_plus
    mulsd xmm1, [minus_one]
sign_plus:
    addsd xmm11, xmm1

    ; Проверка точности: |Sum - f(x)| < epsilon
    movsd xmm3, xmm11
    subsd xmm3, xmm10   ; xmm3 = Sum - f(x)
    
    ; БЕЗОПАСНЫЙ МОДУЛЬ (без align 16):
    movupd xmm4, [abs_mask] ; Используем unaligned загрузку
    andpd xmm3, xmm4        ; Обнуляем бит знака
    
    ucomisd xmm3, [epsilon]
    jb print_row        ; Выход из цикла, если достигли точности

    inc r13
    cmp r13, 1000000    ; Лимит итераций
    jb series_loop

print_row:
    mov rdi, row_fmt
    movsd xmm0, [current_x]
    movsd xmm1, xmm10
    movsd xmm2, xmm11
    mov rsi, r13
    mov rax, 3
    call printf

    inc r12
    jmp main_loop

all_done:
    add rsp, 24
    xor rdi, rdi
    call exit