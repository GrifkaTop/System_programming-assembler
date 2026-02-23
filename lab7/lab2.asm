format ELF64
public _start


include 'lib.asm'
include 'sort.inc'
include 'task_mode.inc'
include 'task_fifth.inc'
include 'task_quantile.inc'
include 'task_primes.inc'

; --- Настройка размера массива ---
ELEMENT_COUNT = 10

;----------------------------------Данные и константы-------------------------------
section '.data' writeable
    count       dq ELEMENT_COUNT 
    msg_m       db "1. Мода: ", 0 
    msg_f       db "2. 5-й элемент после сортировки: ", 0
    msg_q       db "3. 0.75 квантиль: ", 0
    msg_p       db "4. Количество простых чисел: ", 0
    nl          db 10, 0 

section '.bss' writeable
    ; Резервируем память под ELEMENT_COUNT 64-битных чисел
    array       rq ELEMENT_COUNT 

;----------------------------------Код-------------------------------
section '.text' executable
_start:
    ; 0. Генерируем случайные числа (системный вызов getrandom)
    mov rax, 318        ; sys_getrandom
    mov rdi, array
    mov rsi, [count]
    shl rsi, 3          ; count * 8 байт
    xor rdx, rdx        ; флаги = 0
    syscall

    ; 1. Приведение к натуральным числам < 1 000 000
    mov rcx, [count]
    test rcx, rcx
    jz .skip_init       ; Если массив пустой, выходим
    mov rsi, array
.make_natural:
    mov rax, [rsi]
    test rax, rax      
    jns .is_positive   
    neg rax            ; Модуль числа
.is_positive:
    xor rdx, rdx
    mov rbx, 1000000   
    div rbx            ; Ограничиваем диапазон
    mov [rsi], rdx      
    add rsi, 8
    loop .make_natural

.skip_init:

    ; 2. Создание 4-х дочерних процессов
    mov rcx, 4
.fork_loop: 
    push rcx            ; Сохраняем номер задачи (4, 3, 2, 1)
    mov rax, 57         ; sys_fork
    syscall
    
    test rax, rax 
    jz .child_work      ; Если RAX=0, это ребенок
    
    pop rcx             ; В родителе восстанавливаем счетчик
    loop .fork_loop     ; Цикл до 0

    ; 3. Родительский процесс: ждет всех детей
    mov rcx, 4
.wait_all:
    push rcx
    mov rax, 61         ; sys_wait4
    mov rdi, -1         ; Ждать любого ребенка
    xor rsi, rsi 
    xor rdx, rdx 
    xor r10, r10
    syscall 
    pop rcx 
    loop .wait_all
    
    mov rax, 60         ; Выход родителя
    xor rdi, rdi 
    syscall 


; --- Логика дочерних процессов ---
.child_work:
    pop rbx             ; Достаем ID задачи (номер из push rcx)
    cmp rbx, 4 
    je do_mode  ; Задача 1: Мода
    cmp rbx, 3 
    je do_fifth ; Задача 2: 5-й элемент после сортировки
    cmp rbx, 2  
    je do_quantile ; Задача 3: 0.75 квантиль
    cmp rbx, 1 
    je do_primes  ; Задача 4: Количество простых чисел
    jmp exit_child 
    
; --- Точка завершения любого ребенка ---
exit_child: 
    mov rsi, nl
    call print_str      
    mov rax, 60         ; sys_exit
    xor rdi, rdi 
    syscall
