format ELF64
public _start

; l - клавиша выхода
; p - клавиша изменения скорости

; ------------------------------ ПОДКЛЮЧЕНИЕ NCURSES ------------------ --------------
extrn initscr
extrn start_color
extrn init_pair
extrn getmaxx
extrn getmaxy
extrn raw
extrn noecho
extrn stdscr
extrn move
extrn getch
extrn addch 
extrn refresh
extrn endwin
extrn exit
extrn timeout
extrn curs_set
extrn usleep 
extrn attrset ; ИСПОЛЬЗУЕМ ATTRSET ДЛЯ СМЕНЫ ЦВЕТА

; ------------------------------- КОНСТАНТЫ ------------------ ---------
section '.data'
    delay_change dq 99500
    delay_slow   dq 100500
    delay_fast   dq 499
    my_symbol    dq 'X' 

    ; Константы цветов (0-7: Black, Red, Green, Yellow, Blue, Magenta, Cyan, White)
    pair1_fg     dq 0   ; Текст 1 пары 
    pair1_bg     dq 255     ; Фон 1 пары 
    
    pair2_fg     dq 255     ; Текст 2 пары 
    pair2_bg     dq 0      ; Фон 2 пары 

; ------------------------------ ДАННЫЕ ------------------ --------------
section '.bss' writable
    max_x dq 1
    max_y dq 1
    current_char dq 1
    delay dq 1
    current_color_pair dq 1
    
    ; Границы для спирали
    top    dq 0
    bottom dq 0
    left   dq 0
    right  dq 0

    ; Временные переменные для координат
    temp_x dq 0
    temp_y dq 0

; ------------------------------ КОД ПРОГРАММЫ ------------------ --------------
section '.text' executable 
_start:
    ; 1. Инициализация ncurses
    call initscr
    
    ; 2. Настройка цветов (обязательно ПОСЛЕ initscr)
    call start_color
    
    ; Пара 1
    mov rdi, 1              ; Номер пары
    mov rsi, [pair1_fg]     ; Цвет текста
    mov rdx, [pair1_bg]     ; Цвет фона
    call init_pair
    
    ; Пара 2
    mov rdi, 2              ; Номер пары
    mov rsi, [pair2_fg]     ; Цвет текста
    mov rdx, [pair2_bg]     ; Цвет фона
    call init_pair

    ; 3. Получение размеров
    mov rdi, [stdscr]
    call getmaxx
    mov [max_x], rax
    call getmaxy
    mov [max_y], rax

    ; 4. Настройка режима
    mov rdi, 0
    call curs_set    
    call noecho      
    call raw         
    call refresh

    mov rax, [my_symbol]
    mov [current_char], rax
    
    mov qword [current_color_pair], 1
    mov rax, [delay_slow]
    mov [delay], rax

spiral_init:
    mov [top], 0
    mov rax, [max_y]
    dec rax
    mov [bottom], rax
    mov [left], 0
    mov rax, [max_x]
    dec rax
    mov [right], rax

mloop:
    ; === 1. ВПРАВО ===
    mov rax, [top]
    mov [temp_y], rax
    mov rax, [left]
    mov [temp_x], rax
.right_loop:
    call draw_point
    inc qword [temp_x]
    mov rax, [temp_x]
    cmp rax, [right]
    jle .right_loop
    
    inc qword [top]
    mov rax, [top]
    cmp rax, [bottom]
    jg reset_spiral

    ; === 2. ВНИЗ ===
    mov rax, [right]
    mov [temp_x], rax
    mov rax, [top]
    mov [temp_y], rax
.down_loop:
    call draw_point
    inc qword [temp_y]
    mov rax, [temp_y]
    cmp rax, [bottom]
    jle .down_loop

    dec qword [right]
    mov rax, [right]
    cmp rax, [left]
    jl reset_spiral

    ; === 3. ВЛЕВО ==
    mov rax, [bottom]
    mov [temp_y], rax
    mov rax, [right]
    mov [temp_x], rax

.left_loop: 
    call draw_point
    dec qword [temp_x]
    mov rax, [temp_x]
    cmp rax, [left]
    jge .left_loop

    dec qword [bottom]
    mov rax, [bottom]
    cmp rax, [top]
    jl reset_spiral

    ; === 4. ВВЕРХ ===
    mov rax, [left]
    mov [temp_x], rax
    mov rax, [bottom]
    mov [temp_y], rax
.up_loop: 
    call draw_point
    dec qword [temp_y]
    mov rax, [temp_y]
    cmp rax, [top]
    jge .up_loop

    inc qword [left]
    mov rax, [left]
    cmp rax, [right]
    jg reset_spiral
    
    jmp mloop

; ---------------------------------- ФУНКЦИИ ------------------ --------------
draw_point: ; Рисует символ в (temp_x, temp_y) с текущим цветом и обрабатывает ввод
    sub rsp, 8

    ; Установка курсора
    mov rdi, [temp_y] 
    mov rsi, [temp_x] 
    call move
    
    ; Установка цвета: (pair << 8)
    mov rdi, [current_color_pair]
    shl rdi, 8          
    call attrset ; ИСПОЛЬЗУЕМ ATTRSET ВМЕСТО ATTRON ДЛЯ ЧИСТОЙ СМЕНЫ
    
    ; Вывод символа
    mov rdi, [current_char]
    call addch
    call refresh
    
    mov rdi, [delay]
    call usleep
    
    mov rdi, 0
    call timeout
    call getch
    
    ; Обработка нажатых клавиш
    cmp rax, 'l'        
    je exit_prog
    cmp rax, 'p'        
    jne .skip_speed 
    call do_speed_change

.skip_speed: ; Проверка на клавишу 'l' и 'p' --- IGNORE ---

    add rsp, 8
    ret

do_speed_change: ; Меняет скорость между медленной и быстрой
    mov rax, [delay]
    sub rax, [delay_change]
    cmp rax, [delay_fast]
    jge .set
    mov rax, [delay_slow]
.set:
    mov [delay], rax
    ret

reset_spiral: ; Сброс спирали и смена цвета
    mov rax, [current_color_pair]
    xor rax, 3          ; 1 -> 2, 2 -> 1
    mov [current_color_pair], rax
    jmp spiral_init

exit_prog: ; Выход из программы
    call endwin
    mov rax, 60         
    xor rdi, rdi
    syscall