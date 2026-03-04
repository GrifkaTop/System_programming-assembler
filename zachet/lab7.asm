format ELF64

public main
extrn printf 
extrn exit

; -------------------- ДАННЫЕ -------------------------------
section '.data' writeable
    fmt_header db " n  |      x_next   ", 10
               db "---------------- ----", 10, 0
    fmt_row    db "%3d | %12.10f", 10, 0
    fmt_res    db 10, "Root found: %12.10f", 10, 0

    eps        dq 0.00001     ; Точность
    x_curr     dq 0.1     ; Начальное приближение x1
    x_next     dq 0.0      
    two        dq 2.0      ; Делитель
    iter_count dd 0

section '.text' executable

; x = (ln(x) - cos(x)) / 2
main:
    push rbp
    mov rbp, rsp
    and rsp, -16               ; Выравнивание стека

    ; Вывод заголовка
    lea rdi, [fmt_header]
    xor eax, eax
    call printf

.loop_iteration:
    inc dword [iter_count]

    ; 2. Вычисляем x_next = phi(x) = (-ln(x) + cos(x)) / 2
    finit                      ; Очистка стека FPU
    
    ; Считаем ln(x)
    ;fcos
    fldln2                     ; st0 = cos()
    fld qword [x_curr]         ; st0 = x, st1 = cos
    fyl2x                      ; st0 = cos

    ; Считаем cos(x)
    fld qword [x_curr]         ; st0 = x, st1 = cos
    fcos                       ; st0 = ln, st1 = cos
    ;fldln2  

    ; Вычитаем и делим
    fsubp st1, st0             ; st0 = cos - ln
    fchs

    fdiv qword [two]           ; st0 = (cos - ln) / 2
    
    ;fabs                       ; 
    fst qword [x_next]         ;   

    ; 1. Вывод текущего состояния
    lea rdi, [fmt_row]
    mov esi, [iter_count]
    movsd xmm0, qword [x_next]
    mov eax, 1                 
    call printf

    ; 3. |x_next - x_curr| < eps 
    fld qword [x_next]
    fsub qword [x_curr]        ; st0 = x_next - x_curr
    fabs                       
    fcomp qword [eps]          
    fstsw ax
    sahf
    jb .done                   ; < eps  

    ; Обновляем x_curr для следующей итерации
    movsd xmm0, qword [x_next]
    movsd qword [x_curr], xmm0
    
    ; < 100 операций
    cmp dword [iter_count], 1000000
    jl .loop_iteration

.done:
    ; Ответ
    lea rdi, [fmt_res]
    movsd xmm0, qword [x_next]
    mov eax, 1
    call printf

    mov rsp, rbp
    pop rbp
    xor edi, edi
    call exit