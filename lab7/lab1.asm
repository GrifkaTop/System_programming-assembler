format ELF64
public _start

include 'lib.asm' 

; ----------------------------------Данные и константы-------------------------------
section '.data' writeable
    ask_text    db 10, "Введите команду: ", 0
    fail_text   db "Ошибка", 10, 0
    cmd_line    rb 256 ; буфер команлы
    
    ; Массив аргументов для execve: [адрс_cmd, адр_арг1, ..., 0]
    align 8
    cmd_args    dq 0, 0, 0, 0, 0, 0, 0, 0 ; Резервируем место под 8 аргументов
    
    env         dq 0    ; указатель на окружение

; ----------------------------------Код-------------------------------
section '.text' executable
_start:
    ; Получаем окружение из стека
    pop rcx 
    lea rdi, [rsp + rcx*8 + 8] 
    mov [env], rdi

main_loop:
    mov rsi, ask_text
    call print_str

    mov rsi, cmd_line
    call input_keyboard ; Считали команду в cmd_line 

    cmp byte [cmd_line], 0  ; Enter ?
    je main_loop 

; --- РАЗБОР СТРОКИ НА АРГУМЕНТЫ ---
    lea rsi, [cmd_line] ; Указатель на начало строки
    lea rdi, [cmd_args] ; Указатель на массив аргументов
    mov qword [rdi], rsi    ; имя файла
    add rdi, 8 ;

parse_loop:
    mov al, [rsi] 
    cmp al, 0               ; Конец строки?
    je finish_parse
    cmp al, ' '             ; Пробел?
    jne next_char

    ; Если нашли пробел:
    mov byte [rsi], 0       ; Заменяем пробел на конец строки для предыдущего аргумента
    inc rsi
    ; Пропускаем лишние пробелы, если они есть
skip_spaces:
    cmp byte [rsi], ' '
    jne check_end
    inc rsi
    jmp skip_spaces
check_end:
    cmp byte [rsi], 0 ; Конец строки после пробелов ?
    je finish_parse     
    
    mov [rdi], rsi          ; Сохраняем адрес начала следующего аргумента
    add rdi, 8 
    jmp parse_loop

next_char:
    inc rsi
    jmp parse_loop

finish_parse:
    mov qword [rdi], 0      ; Последний элемент массива ДОЛЖЕН быть NULL

; --------- Конец разбора строки на аргументы ---------

; -------------- ФОРК И ВЫПОЛНЕНИЕ --------------
    mov rax, 57         ; sys_fork
    syscall 

    test rax, rax
    js  main_loop       
    jz  do_exec         
    
    ; Родительский процесс: ждем завершения
    mov rdi, rax        
    mov rax, 61         ; sys_wait4
    xor rsi, rsi
    xor rdx, rdx
    xor r10, r10
    syscall
    
    ; Очистка массива аргументов перед следующим вводом
    lea rdi, [cmd_args]
    mov rcx, 8
    xor rax, rax
    rep stosq
    
    jmp main_loop

; Выполнение команды в дочернем процессе
do_exec:
    mov rax, 59         ; sys_execve
    mov rdi, [cmd_args] ; Путь к исполняемому файлу (первый токен)
    mov rsi, cmd_args   ; Массив всех аргументов
    mov rdx, [env]      ; Окружение
    syscall

    mov rsi, fail_text 
    call print_str 
    mov rax, 60         
    mov rdi, 1 
    syscall