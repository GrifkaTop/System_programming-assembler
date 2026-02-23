format ELF64
public _start

include 'lib.asm' ; Должны быть функции print_str, input_keyboard, print_int

; ----------------------------------Данные и константы-------------------------------
section '.data' writeable
    ask_text    db 10, "Введите команду: ", 0
    fail_text   db "Ошибка", 10, 0
    cmd_line    rb 256
    cmd_args    dq 0, 0 ; Массив аргументов для execve
    env         dq 0    ; Переменные окружения

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

    cmp byte [cmd_line], 0 ; Если пользователь просто нажал Enter, то повторяем запрос
    je main_loop ; Если команда не пустая, то пытаемся выполнить ее

    ; Подготовка аргументов (argv[0] = путь к файлу, argv[1] = NULL)
    mov [cmd_args], cmd_line

    mov rax, 57         ; sys_fork - создает новый процесс, который является копией текущего процесса. Возвращает 0 в дочернем процессе, PID ребенка в родительском процессе, и -1 при ошибке
    syscall 

    test rax, rax
    js  main_loop       ; Ошибка fork - просто повторяем запрос
    jz  do_exec         ; Дочерний процесс
    
    ; Родительский процесс: ждем завершения
    mov rdi, rax        ; PID ребенка, PID - это возвращаемое значение fork
    mov rax, 61         ; sys_wait4 - ждем завершения дочернего процесса
    xor rsi, rsi
    xor rdx, rdx
    xor r10, r10
    syscall
    jmp main_loop

; Выполнение команды в дочернем процессе
do_exec:
    mov rax, 59         ; sys_execve
    mov rdi, cmd_line ; Путь к исполняемому файлу
    lea rsi, [cmd_args] ; argv
    mov rdx, [env]   ; Передаем окружение
    syscall

    mov rsi, fail_text ; Если execve возвращает, значит произошла ошибка
    call print_str ; Печатаем сообщение об ошибке
    mov rax, 60         ; exit
    mov rdi, 1 ; код ошибки
    syscall