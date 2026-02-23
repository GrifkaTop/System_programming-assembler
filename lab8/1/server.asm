;SERVER IP: 0.0.0.0
format ELF64
public _start
; ------------------------------- ДАННЫЕ сообщения------------------ --------------
section '.data' writable
    msg_wait_1      db 0, "Первый игрок подключение (X)...", 10, 0
    msg_wait_2      db 0, "Второй игрок подключение (O)...", 10, 0
    msg_start       db 0, "Оба игрока подключены! Игра начинается!", 10, 0
    
    ;тип сообщения (0 - ожидание, 1 - ход, 2 - результат)
    net_msg_wait    db 0, "Ожидание противника...", 10, 0 
    net_msg_turn    db 1, "Ваш ход (0-8): ", 0        
    net_msg_win     db 2, "Вы выиграли!", 10, 0
    net_msg_lose    db 2, "Вы проиграли!", 10, 0
    net_msg_draw    db 2, "Ничья!", 10, 0
    
    newline db 10

    server_addr:
        dw 2 
        db 0x1F, 0x90  
        dd 0          
        dq 0
    
    

;-------------------------------- ДАННЫЕ ------------------ --------------
section '.bss' writable
    server_sock     rq 1
    sock_p1         rq 1
    sock_p2         rq 1
    board           rb 9
    buffer          rb 256
    current_turn    db 0
    moves_cnt       db 0    

;-------------------------------- КОД ------------------ --------------
section '.text' executable
_start:
    ; Инициализация сети 
    mov rax, 41         
    mov rdi, 2
    mov rsi, 1
    xor rdx, rdx
    syscall
    mov [server_sock], rax
    
    mov rax, 1          ;
    mov rdi, [server_sock] 
    mov rsi, 2          ; SOL_SOCKET - уровень сокета
    mov rdx, 2          ; SO_REUSEADDR - разрешить повторное использование адреса
    
    ; Установка опции сокета
    mov rax, 49         ; bind
    mov rdi, [server_sock]
    lea rsi, [server_addr]
    mov rdx, 16
    syscall
    
    ; Теперь слушаем и принимаем подключения
    mov rax, 50       
    mov rdi, [server_sock]
    mov rsi, 2
    syscall

    ; Подключение игроков 
    mov rdi, msg_wait_1
    inc rdi
    call std_print_string
    
    ; Принимаем первого игрока
    mov rax, 43        
    mov rdi, [server_sock]
    xor rsi, rsi
    xor rdx, rdx
    syscall
    mov [sock_p1], rax

    ; Сообщаем второму игроку, что первый подключился
    mov rdi, msg_wait_2
    inc rdi
    call std_print_string
    
    ; Принимаем второго игрока
    mov rax, 43         
    mov rdi, [server_sock]
    xor rsi, rsi
    xor rdx, rdx
    syscall
    mov [sock_p2], rax

    ; Сообщаем обоим игрокам, что игра начинается
    mov rdi, msg_start
    inc rdi
    call std_print_string

;------------------------------- ОСНОВНОЙ ЦИКЛ ИГРЫ ------------------ --------------
game_loop:
    ; 1. Рассылка карты
    call create_map   
    mov rdx, rax    

    ; Отправляем карту обоим игрокам
    mov rax, 1
    mov rdi, [sock_p1]
    mov rsi, buffer
    syscall
    
    mov rax, 1
    mov rdi, [sock_p2]
    mov rsi, buffer
    syscall

    call wait_ack_p1 
    call wait_ack_p2

    ; 2. Проверка итогов
    call check_win
    cmp rax, 1 ; Победа P1
    je win_p1
    cmp rax, 2 ; Победа P2
    je win_p2
    
    ; Проверяем ничью (если 9 ходов и нет победителя)
    cmp byte [moves_cnt], 9
    je draw_game

    ; 3. Смена хода
    cmp byte [current_turn], 0
    je turn_player_1
    jmp turn_player_2

; ------------------------------- ОБРАБОТЧИКИ ИГРЫ ------------------ --------------
; ход первого игрока
turn_player_1:
    ; P2 ждет
    mov rax, 1
    mov rdi, [sock_p2]
    lea rsi, [net_msg_wait]
    mov rdx, 128
    syscall

    ; P1 ходит
    mov rax, 1
    mov rdi, [sock_p1]
    lea rsi, [net_msg_turn]
    mov rdx, 128
    syscall

    call wait_ack_p1
    call wait_ack_p2
    
    ; Читаем ход P1
    mov rax, 0
    mov rdi, [sock_p1]
    lea rsi, [buffer]
    mov rdx, 1         
    syscall


    mov al, [buffer]
    sub al, '0'
    
    cmp al, 8
    ja turn_player_1   
    ; Проверяем, что выбранная клетка свободна
    movzx rbx, al
    cmp byte [board + rbx], 0
    jne turn_player_1  ; Если занято, просим выбрать снова

    mov byte [board + rbx], 1 ; ставим X
    inc byte [moves_cnt]       ; увеличиваем счетчик ходов
    mov byte [current_turn], 1 ; передаем ход второму игроку
    jmp game_loop

; ход второго игрока (логика аналогична, но с ролями поменяными местами)
turn_player_2:
    ; P1 ждет
    mov rax, 1
    mov rdi, [sock_p1]
    lea rsi, [net_msg_wait]
    mov rdx, 128
    syscall

    ; P2 ходит
    mov rax, 1
    mov rdi, [sock_p2]
    lea rsi, [net_msg_turn]
    mov rdx, 128
    syscall

    call wait_ack_p1
    call wait_ack_p2
    
    ; Читаем ход P2
    mov rax, 0
    mov rdi, [sock_p2]
    lea rsi, [buffer]
    mov rdx, 1         
    syscall
    
    mov al, [buffer]
    sub al, '0'
    
    cmp al, 8
    ja turn_player_2
    
    movzx rbx, al
    cmp byte [board + rbx], 0
    jne turn_player_2

    mov byte [board + rbx], 2 ; ставим 'O'
    inc byte [moves_cnt]       ; увеличиваем счетчик ходов
    mov byte [current_turn], 0 ; передаем ход первому игроку
    jmp game_loop

; Утилиты
wait_ack_p1: ; ждем подтверждения от P1
    mov rax, 0 
    mov rdi, [sock_p1]
    lea rsi, [buffer]
    mov rdx, 1 
    syscall
    ret

wait_ack_p2: ; ждем подтверждения от P2
    mov rax, 0 
    mov rdi, [sock_p2]
    lea rsi, [buffer]
    mov rdx, 1 
    syscall 
    ret

win_p1: ; обработчик победы P1
    mov rax, 1
    mov rdi, [sock_p1]
    lea rsi, [net_msg_win]
    mov rdx, 10 
    syscall
    
    mov rax, 1
    mov rdi, [sock_p2]
    lea rsi, [net_msg_lose]
    mov rdx, 11
    syscall
    jmp game_over       

win_p2: ; обработчик победы P2
    mov rax, 1
    mov rdi, [sock_p1]
    lea rsi, [net_msg_lose]
    mov rdx, 11
    syscall
    
    mov rax, 1
    mov rdi, [sock_p2]
    lea rsi, [net_msg_win]
    mov rdx, 10
    syscall
    jmp game_over

draw_game: ; обработчик ничьей
    mov rax, 1
    mov rdi, [sock_p1]
    lea rsi, [net_msg_draw]
    mov rdx, 8          
    syscall

    mov rax, 1
    mov rdi, [sock_p2]
    lea rsi, [net_msg_draw]
    mov rdx, 8
    syscall
    jmp game_over

; выход из игры
game_over:
    mov rax, 60
    xor rdi, rdi
    syscall

;------------------------------- ВСПОМОГАТЕЛЬНЫЕ ФУНКЦИИ ------------------ --------------
section '.text' executable
    map_template:
        db "-------------", 10
        db "|   |   |   |", 10
        db "-------------", 10
        db "|   |   |   |", 10
        db "-------------", 10
        db "|   |   |   |", 10
        db "-------------", 10, 0
    map_len equ $ - map_template

    ; Смещение символов внутри шаблона относительно начала
    cell_offsets: db 16, 20, 24, 30, 34, 38, 44, 48, 52

create_map:
    push rbp
    mov rbp, rsp

    ; 1. Копируем шаблон целиком в буфер
    lea rsi, [map_template]
    lea rdi, [buffer]
    mov rcx, map_len
    rep movsb        

    ; 2. Заполняем только те клетки, где стоят X или O
    xor rcx, rcx            ; rcx = индекс клетки (0-8)
    .fill_loop: ; цикл по 9 клеткам
        cmp rcx, 9
        je .done

        movzx rax, byte [board + rcx] ; Значение в клетке
        test rax, rax
        jz .next_cell                 ; Если 0 (пусто), ничего не меняем 

        ; Определяем символ: 1 -> 'X', 2 -> 'O'
        mov dl, 'X'
        cmp rax, 1
        je .place_char

        mov dl, 'O'

    ; Размещаем символ в шаблоне
    .place_char:
        movzx r8, byte [cell_offsets + rcx] ; Берем позицию в строке шаблона
        mov [buffer + r8], dl               ; Записываем символ в буфер

    .next_cell:
        inc rcx
        jmp .fill_loop

    .done:
        mov rax, map_len        ; Возвращаем длину строки
        pop rbp
        ret

; Функция для проверки победы
check_win:
    push rbp
    mov rbp, rsp
    mov al, [board + 0]
    cmp al, 0
    je .check_row2
    cmp al, [board + 1]
    jne .check_row2
    cmp al, [board + 2]
    je .win_found
.check_row2:
    mov al, [board + 3]
    cmp al, 0
    je .check_row3
    cmp al, [board + 4]
    jne .check_row3
    cmp al, [board + 5]
    je .win_found
.check_row3:
    mov al, [board + 6]
    cmp al, 0
    je .check_cols
    cmp al, [board + 7]
    jne .check_cols
    cmp al, [board + 8]
    je .win_found
.check_cols:
    mov al, [board + 0]
    cmp al, 0
    je .check_col2
    cmp al, [board + 3]
    jne .check_col2
    cmp al, [board + 6]
    je .win_found
.check_col2:
    mov al, [board + 1]
    cmp al, 0
    je .check_col3
    cmp al, [board + 4]
    jne .check_col3
    cmp al, [board + 7]
    je .win_found
.check_col3:
    mov al, [board + 2]
    cmp al, 0
    je .check_diagonals
    cmp al, [board + 5]
    jne .check_diagonals
    cmp al, [board + 8]
    je .win_found
.check_diagonals:
    mov al, [board + 0]
    cmp al, 0
    je .check_diag2
    cmp al, [board + 4]
    jne .check_diag2
    cmp al, [board + 8]
    je .win_found
.check_diag2:
    mov al, [board + 2]
    cmp al, 0
    je .no_win
    cmp al, [board + 4]
    jne .no_win
    cmp al, [board + 6]
    je .win_found
.no_win:
    xor rax, rax
    mov rsp, rbp
    pop rbp
    ret
.win_found:
    movzx rax, al
    mov rsp, rbp
    pop rbp
    ret

std_print_string:
    push rdi
    xor rdx, rdx
  .loop:
    cmp byte [rdi + rdx], 0
    je .print
    inc rdx
    jmp .loop
  .print:
    mov rax, 1
    mov rsi, rdi
    mov rdi, 1
    syscall
    pop rdi
    ret