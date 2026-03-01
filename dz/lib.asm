format ELF64

public array_create
public array_get_len
public array_get
public array_set
public array_free
public array_push_back
public array_pop_front
public array_remove_evens
public array_get_odd_numbers
public array_count_ending_with_1

section '.bss' writable
    mmap_ptr  rq 1    ; системный адрес начала блока (нужен для munmap)
    mmap_size rq 1    ; полный размер выделенной памяти

section '.text' executable

; --- Создание массива через mmap ---
; RDI: кол-во элементов
array_create:
    push rdi
    inc rdi           ; +1 под заголовок (длину)
    shl rdi, 3        ; Умножаем на 8 (размер qword)
    mov [mmap_size], rdi
    
    ; Подготовка аргументов для SYS_MMAP (rax=9)
    mov rsi, rdi      ; RSI = size
    mov r8, -1        ; R8  = fd (не используем файл)
    mov r10, 0x22     ; R10 = flags (MAP_PRIVATE | MAP_ANONYMOUS)
    mov rdx, 3        ; RDX = prot (PROT_READ | PROT_WRITE)
    xor rdi, rdi      ; RDI = addr (NULL, ядро само выберет адрес)
    mov rax, 9        ; Номер системного вызова mmap
    syscall           ; В RAX вернется указатель на выделенную память
    
    pop rdi
    mov [mmap_ptr], rax
    mov [rax], rdi    ; В первые 8 байт пишем текущую длину массива
    add rax, 8        ; пользователь видит только данные (сдвигаем)
    ret

; --- Получение длины ---
; RDI: указатель на данные массива
array_get_len:
    mov rax, [rdi - 8] ; Длина 
    ret

; --- Получение элемента по индексу ---
; RDI: массив, RSI: индекс
array_get:
    mov rax, [rdi + rsi * 8]
    ret

; --- Запись элемента ---
; RDI: массив, RSI: индекс, RDX: значение
array_set:
    mov [rdi + rsi * 8], rdx
    ret

; --- Освобождение памяти ---
array_free:
    mov rdi, [mmap_ptr]   ; Оригинальный адрес от mmap
    mov rsi, [mmap_size]  ; Тот же размер, что при выделении
    test rdi, rdi         ; Проверка на NULL
    jz .done
    mov rax, 11           ; SYS_MUNMAP
    syscall
    mov qword [mmap_ptr], 0
.done:
    ret

; --- Добавление в конец ---
; RDI: массив, RSI: значение
array_push_back:
    mov rcx, [rdi - 8]       ; Текущая длина
    mov [rdi + rcx * 8], rsi ; Пишем за последним элементом
    inc rcx                  ; Увеличиваем счетчик
    mov [rdi - 8], rcx       ; Обновляем в памяти
    mov rax, 1
    ret

; --- Удаление первого элемента (со сдвигом) ---
array_pop_front:
    mov rcx, [rdi - 8]
    test rcx, rcx
    jz .empty
    
    mov rax, [rdi]    ; Сохраняем первый элемент для возврата
    dec rcx           ; Новая длина
    mov [rdi - 8], rcx
    jz .done          ; Если массив стал пуст, сдвиг не нужен
    
    ; Сдвиг элементов влево через rep movsq
    push rax
    push rdi
    mov rsi, rdi
    add rsi, 8        ; Источник: второй элемент
    ; RDI уже содержит адрес первого элемента (куда копировать)
    ; RCX уже содержит кол-во элементов для копирования
    cld               ; Направление: вперед
    rep movsq         ; Копируем RCX * 8 байт
    pop rdi
    pop rax
.done:
    ret
.empty:
    xor rax, rax
    ret

; --- Удаление всех четных чисел (In-place) ---
; RDI: указатель на начало данных массива
array_remove_evens:
    mov rcx, [rdi - 8]   ; Загружаем текущую длину массива из заголовка
    test rcx, rcx        ; Ппуст?
    jz .re_done          
    
    xor r8, r8           ; R8 = "Указатель записи" (индекс, куда прилетит следующее нечетное)
    xor r9, r9           ; R9 = "Указатель чтения" (текущий элемент, который проверяем)

.re_loop:
    mov rax, [rdi + r9 * 8] ; Берем число из текущей позиции чтения
    
    ; Проверка на четность: 
    ; Младший бит у четных чисел всегда 0, у нечетных — 1.
    test rax, 1          
    jz .is_even          ; Если результат 0 (четное), просто пропускаем запись

    ; Если число нечетное:
    mov [rdi + r8 * 8], rax ; Копируем его в позицию записи
    inc r8                  ; Сдвигаем указатель записи вперед
    
.is_even:
    inc r9               ; Всегда сдвигаем указатель чтения
    cmp r9, rcx          ; Проверяем, не дошли ли до конца массива
    jl .re_loop          ; Если нет — на следующую итерацию

    ; Финальный шаг:
    ; R8 теперь содержит количество успешно записанных нечетных чисел.
    mov [rdi - 8], r8    ; Обновляем длину массива в заголовке [-8]

.re_done:
    ret

; --- Создание нового массива только из нечетных чисел ---
array_get_odd_numbers:
    push r12
    push r13
    push r14
    mov r12, rdi      ; Сохраняем указатель на входной массив
    
    ; 1. Считаем количество нечетных для выделения памяти
    mov rcx, [r12 - 8]
    xor r13, r13      ; Счетчик нечетных
    xor rdx, rdx
.cnt:
    cmp rdx, rcx
    jge .alloc
    mov rax, [r12 + rdx * 8]
    test rax, 1
    jz .ev
    inc r13
.ev:
    inc rdx
    jmp .cnt

    ; 2. Аллоцируем новый массив нужного размера
.alloc:
    mov rdi, r13
    call array_create ; Результат в RAX
    mov r14, rax      ; R14 = новый массив
    
    ; 3. Копируем данные
    mov rcx, [r12 - 8]
    xor r8, r8        ; Индекс в новом
    xor r9, r9        ; Индекс в старом
.fill:
    cmp r9, rcx
    jge .f_end
    mov rax, [r12 + r9 * 8]
    test rax, 1
    jz .f_ev
    mov [r14 + r8 * 8], rax
    inc r8
.f_ev:
    inc r9
    jmp .fill
.f_end:
    mov rax, r14      ; Возвращаем новый массив
    pop r14
    pop r13
    pop r12
    ret

; --- Подсчет чисел, заканчивающихся на 1 ---
; 
array_count_ending_with_1:
    mov rcx, [rdi - 8]
    xor r8, r8        ; Итоговый счетчик
    test rcx, rcx
    jz .c_done
.c_loop:
    mov rax, [rdi + rcx * 8 - 8]
    push rcx
    push rdi
    mov r9, 10
    xor rdx, rdx      ; Обязательно обнуляем RDX перед DIV
    div r9            ; RAX / 10, остаток в RDX
    cmp rdx, 1        ; Если остаток 1, значит число оканчивается на 1
    pop rdi
    pop rcx
    jne .c_next
    inc r8
.c_next:
    loop .c_loop      ; Цикл по RCX до нуля
.c_done:
    mov rax, r8
    ret