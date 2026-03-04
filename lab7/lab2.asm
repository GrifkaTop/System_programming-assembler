format ELF64
public _start

; --- Настройка размера массива ---
ARRAY_SIZE = 10

; -------данные--------------
section '.data' writeable
    space db ' '

    array    rq ARRAY_SIZE
    digit_counters rb 10
    delay    dq 1, 0
    buffer   rb 32 ; ! динмаически должен быть..... йоу 
    buffer_end = $ - 1

    msg1 db "Наиболее часто встречающаяся цифра:"
    msg1_len = $ - msg1
    msg2 db "5 число: "
    msg2_len = $ - msg2
    msg3 db "0.75 квалитет: "
    msg3_len = $ - msg3
    msg4 db "Количество простых: "
    msg4_len = $ - msg4

    ; Свои стеки для каждого треда
    stack1 rb 4096
    stack1_end:
    stack2 rb 4096
    stack2_end:
    stack3 rb 4096
    stack3_end:
    stack4 rb 4096
    stack4_end:

section '.text' executable

_start:
    ; 1. Заполнение "кучи" (массива) случайными данными
    mov rcx, ARRAY_SIZE
    mov rdi, array
  .gen:
    rdrand rax
    jnc .gen
    and rax, 0x3FF          ; Ограничим числа до 1023 для удобства
    mov [rdi], rax
    add rdi, 8
    loop .gen

    ; 2. Сортировка (необходима для квантиля и поиска 5-го числа)
    mov rcx, ARRAY_SIZE
  .sort_1:
    push rcx
    mov rsi, array
    mov rcx, ARRAY_SIZE - 1
  .sort_2:
    mov rax, [rsi]
    mov rbx, [rsi+8]
    cmp rax, rbx
    jbe .no_swap
    mov [rsi], rbx
    mov [rsi+8], rax
  .no_swap:
    add rsi, 8
    loop .sort_2
    pop rcx
    loop .sort_1

    ; 3. Запуск Тредов (клонов)
    ; Параметры spawn_thread: (адрес функции, адрес вершины стека)
    
    mov rdx, task_most_freq
    mov rsi, stack1_end
    call spawn_thread

    mov rdx, task_fifth_min
    mov rsi, stack2_end
    call spawn_thread

    mov rdx, task_quantile
    mov rsi, stack3_end
    call spawn_thread

    mov rdx, task_primes
    mov rsi, stack4_end
    call spawn_thread

    ; Родительский процесс просто ждет (sleep)
    mov rax, 35
    mov rdi, delay
    xor rsi, rsi
    syscall

    ; вывести массив.
    call print_array 

    mov rax, 60             ; Выход из основной программы
    xor rdi, rdi
    syscall

; --- Реализация системного вызова CLONE ---
spawn_thread:
    ; Флаги CLONE_VM | CLONE_FS | CLONE_FILES | CLONE_SIGHAND (0x0f00)
    ; Они заставляют процесс работать как поток (тред) в общей памяти
    mov rdi, 0x0f00
    mov rax, 56             ; sys_clone
    syscall
    test rax, rax
    jz .child               ; Если RAX=0, прыгаем в код потока
    ret                     ; Иначе возвращаемся в родителя
.child:
    call rdx                ; Выполняем подзадачу
    mov rax, 60             ; Поток завершается сам через exit
    xor rdi, rdi
    syscall

; 1. подсчет цифр
task_most_freq:
    ; (Считаем цифры через digit_counters)
    mov rdi, digit_counters
    mov rcx, 10
    xor rax, rax
    rep stosb
    mov rcx, ARRAY_SIZE
    mov rsi, array
  .l:
    mov rax, [rsi]
  .d:
    xor rdx, rdx
    mov rbx, 10
    div rbx
    inc byte [digit_counters + rdx]
    test rax, rax
    jnz .d
    add rsi, 8
    loop .l
    ; Поиск макс. цифры
    xor rbx, rbx
    xor rdx, rdx
    mov rcx, 10
  .m:
    mov al, [digit_counters + rcx - 1]
    cmp al, dl
    jbe .n 

    mov dl, al
    mov rbx, rcx
    dec rbx
  .n:
    loop .m
    mov rsi, msg1
    mov rdx, msg1_len
    mov rax, rbx
    call print_result
    ret


; 2. 5-ый элемент
task_fifth_min:
    mov rsi, msg2
    mov rdx, msg2_len
    mov rax, [array + 5*8]
    call print_result
    ret

; 3. 0.75 квантиль
task_quantile:
    mov rsi, msg3
    mov rdx, msg3_len
    mov rax, [array + (ARRAY_SIZE * 75 / 100) * 8]
    call print_result
    ret

; 4. подсчет количества простых чисел
task_primes:
    xor r12, r12
    mov rcx, ARRAY_SIZE
    mov rsi, array
  .p_l:
    mov rax, [rsi]
    cmp rax, 2
    jb .next
    mov rbx, 2
  .check:
    xor rdx, rdx
    mov rax, [rsi]
    div rbx
    test rdx, rdx
    jz .is_div
    inc rbx
    mov rax, rbx
    mul rbx
    cmp rax, [rsi]
    jbe .check
    inc r12
    jmp .next
  .is_div:
    mov rax, [rsi]
    cmp rax, rbx
    jne .next
    inc r12
  .next:
    add rsi, 8
    loop .p_l
    mov rsi, msg4
    mov rdx, msg4_len
    mov rax, r12
    call print_result
    ret

; --- Функции печати ---
; Печать всего массива
print_array:
    mov r13, ARRAY_SIZE     ; Используем r13, так как syscall портит rcx/r11
    mov r12, array          ; Используем r12, так как он сохраняется между вызовами
.loop:
    mov rax, [r12]
    call print_number       ; Выводим само число

    ; Вывод пробела
    mov rax, 1              ; sys_write
    mov rdi, 1              ; stdout
    mov rsi, space
    mov rdx, 1
    syscall

    add r12, 8
    dec r13
    jnz .loop

    ; Перевод строки в конце массива
    mov byte [buffer], 10
    mov rax, 1
    mov rdi, 1
    mov rsi, buffer
    mov rdx, 1
    syscall
    ret

; Универсальная функция вывода числа из RAX
print_number:
    mov rbx, 10
    mov rdi, buffer_end
    mov rcx, 0              ; Счетчик символов
    
.conv:
    dec rdi
    xor rdx, rdx
    div rbx
    add dl, '0'
    mov [rdi], dl
    inc rcx
    test rax, rax
    jnz .conv

    ; Системный вызов write
    mov rax, 1              ; sys_write
    mov rsi, rdi            ; адрес начала строки в буфере
    mov rdx, rcx            ; количество цифр
    mov rdi, 1              ; stdout
    syscall
    ret

print_result:
    push rax
    ; Вывод сообщения (msg1, msg2 и т.д.)
    mov rax, 1              ; sys_write
    mov rdi, 1              ; stdout
    ; rsi и rdx уже загружены перед вызовом print_result
    syscall
    
    pop rax
    call print_number
    
    ; Вывод перевода строки
    mov byte [buffer], 10
    mov rax, 1
    mov rdi, 1
    mov rsi, buffer
    mov rdx, 1
    syscall
    ret
