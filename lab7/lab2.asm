format ELF64
public _start

; --- Константы ---
SYS_WRITE   equ 1
SYS_MMAP    equ 9
SYS_CLONE   equ 56
SYS_EXIT    equ 60
SYS_WAIT4   equ 61

PROT_RW     equ 0x3
MAP_ANON    equ 0x22
CLONE_VM_SH equ 0x111 

; ПАРАМЕТРЫ ВАРИАНТА
ARRAY_SIZE  equ 669       ; Ваш размер массива
STACK_SIZE  equ 65536     ; Размер стека для каждого потока в куче 64к

; --- Сегменты данных и кода ---
section '.data' writeable
    heap_ptr dq 0
    msg1 db "1. Самая частая цифра: ", 0
    msg2 db 10, "2. 5-й элемент: ", 0
    msg3 db 10, "3. 0.75 квантиль: ", 0
    msg4 db 10, "4. Кол-во простых чисел: ", 0

section '.text' executable
_start:
    ; 1. Выделение кучи под массив (669 элементов * 8 байт)
    mov rax, SYS_MMAP
    xor rdi, rdi
    mov rsi, ARRAY_SIZE * 8
    mov rdx, PROT_RW
    mov r10, MAP_ANON
    syscall
    mov [heap_ptr], rax

    ; Заполнение случайными числами (0-999)
    mov rcx, ARRAY_SIZE
    mov rdi, [heap_ptr]
.gen:
    rdrand rax      ; случайно числов в rax
    jnc .gen        ; если не сработал
    xor rdx, rdx    ; Очистим rdx для деления
    mov rbx, 1000   ; /1000
    div rbx         ; rax = rax / 1000, rdx = rax % 1000
    mov [rdi], rdx  ; Сохраняем число в массив
    add rdi, 8
    loop .gen

    ; --- СОРТИРОВКА  ---
    mov rcx, ARRAY_SIZE
    dec rcx         ; Для корректной работы j+1
.out:
    push rcx
    xor rbx, rbx
    mov rsi, [heap_ptr]
.in:
    mov rax, [rsi + rbx*8]
    mov rdx, [rsi + rbx*8 + 8]
    cmp rax, rdx
    jle .no_swp
    mov [rsi + rbx*8], rdx      ; Сохраняем меньшее число
    mov [rsi + rbx*8 + 8], rax  ; Сохраняем большее число
.no_swp:
    inc rbx
    cmp rbx, rcx
    jl .in
    pop rcx
    loop .out

    ; 2. Запуск потоков
    mov rsi, task_frequent_digit
    call spawn_thread
    mov rsi, task_fifth_after_min
    call spawn_thread
    mov rsi, task_quantile
    call spawn_thread
    mov rsi, task_count_primes
    call spawn_thread

    ; 3. Родитель ждет 4 завершения
    mov rcx, 4
.wait:
    push rcx
    mov rax, SYS_WAIT4
    mov rdi, -1 
    xor rsi, rsi 
    xor rdx, rdx
    xor r10, r10 
    syscall
    pop rcx
    loop .wait

    ; Завершение родителя
    mov rax, SYS_EXIT
    xor rdi, rdi
    syscall

; --- Хелпер создания потока ---
spawn_thread: 
    push rsi
    mov rax, SYS_MMAP    ; Стек потока тоже выделяем в куче
    xor rdi, rdi
    mov rsi, STACK_SIZE
    mov rdx, PROT_RW
    mov r10, MAP_ANON
    syscall
    lea rsi, [rax + STACK_SIZE]
    pop r8
    mov rax, SYS_CLONE
    mov rdi, CLONE_VM_SH
    syscall
    test rax, rax
    jz .child
    ret
.child:
    jmp r8


; ------------------------ ЗАДАЧИ ДЛЯ ПОТОКОВ --------------------------
; 1. Часто встречающаяся цифра
task_frequent_digit:
    push rbp
    mov rbp, rsp
    sub rsp, 80         ; Локальные счетчики на стеке потока (10 цифр * 8 байт)
    
    ; Обнуляем счетчики
    mov rdi, rsp
    mov rcx, 10
    xor rax, rax
    rep stosq           ; Заполняем нулями область [rsp..rsp+79] 

    mov rsi, [heap_ptr]
    mov rcx, ARRAY_SIZE
.l1: 
    mov rax, [rsi]      ; Берем число из массива в куче
    add rsi, 8
    push rcx            ; Сохраняем счетчик цикла
.l2: 
    xor rdx, rdx
    mov rbx, 10
    div rbx             ; Выделяем цифру в rdx
    inc qword [rbp - 80 + rdx*8] ; Увеличиваем счетчик этой цифры
    test rax, rax
    jnz .l2             ; Пока число не кончится
    pop rcx             ; Возвращаем счетчик цикла
    loop .l1

    ; Ищем максимум среди 10 счетчиков
    xor rbx, rbx        ; Индекс (цифра)
    xor rdx, rdx        ; Максимальное значение
    xor rcx, rcx
.m: 
    mov rax, [rbp - 80 + rcx*8]
    cmp rax, rdx
    jle .n
    mov rdx, rax
    mov rbx, rcx        ; rbx = самая частая цифра
.n: 
    inc rcx
    cmp rcx, 10
    jl .m
    
    push rbx            
    mov rdi, msg1
    call print_str
    pop rax            
    call print_int
    
    leave               
    jmp thread_exit

; 2. Пятое после минимального 
task_fifth_after_min:
    mov rsi, [heap_ptr]
    mov rax, [rsi + 5*8]
    
    push rax          
    mov rdi, msg2
    call print_str
    pop rax

    call print_int
    jmp thread_exit

; 3. 0.75 квантиль 
task_quantile:
    mov rsi, [heap_ptr]
    ; 669 * 3 / 4 = 501
    mov rax, [rsi + 501*8]
    
    push rax           
    mov rdi, msg3
    call print_str
    pop rax
    
    call print_int
    jmp thread_exit

; 4. Количество простых
task_count_primes:
    mov rsi, [heap_ptr]
    mov rcx, ARRAY_SIZE
    xor r12, r12
.p: mov rax, [rsi]
    push rcx
    call check_prime
    pop rcx
    add r12, rax
    add rsi, 8
    loop .p
    
    mov rax, r12 

    push rax
    mov rdi, msg4
    call print_str
    pop rax

    call print_int
    jmp thread_exit

thread_exit:
    mov rax, SYS_EXIT
    xor rdi, rdi
    syscall

; --- Проверка простоты ---
check_prime:
    cmp rax, 2
    jl .no
    je .yes
    mov rbx, 2
.c: xor rdx, rdx
    mov r8, rax
    div rbx
    test rdx, rdx
    jz .no
    inc rbx
    mov rax, rbx
    mul rbx
    cmp rax, r8
    mov rax, r8
    jle .c
.yes: mov rax, 1
    ret
.no: xor rax, rax
    ret

; --- Функции вывода ---
print_str:
    mov rsi, rdi
    xor rdx, rdx
.l: cmp byte [rsi+rdx], 0
    je .o
    inc rdx
    jmp .l
.o: mov rax, SYS_WRITE
    mov rdi, 1
    syscall
    ret

print_int:
    sub rsp, 40
    mov rbx, 10
    lea rdi, [rsp + 38]
    xor rcx, rcx
.c: xor rdx, rdx
    div rbx
    add dl, '0'
    mov [rdi], dl
    dec rdi
    inc rcx
    test rax, rax
    jnz .c
    inc rdi
    mov rsi, rdi
    mov rdx, rcx
    mov rax, SYS_WRITE
    mov rdi, 1
    syscall
    add rsp, 40
    ret