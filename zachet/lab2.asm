format ELF64
public _start

; данные
section '.data' writeable
    board    dq 0            ; Число на доске P
    mutex    dd 0            ; Семафор (0 - свободно, 1 - занято)
    
    msg_l1   db "A1: увидел вспышку L1", 10, 0
    msg_l1_len = $ - msg_l1
    msg_l2   db "A2: увидел вспышку L2", 10, 0
    msg_l2_len = $ - msg_l2
    
    msg_ret  db " -> вернулся и записал: ", 0
    msg_ret_len = $ - msg_ret

    buffer   rb 32
    buffer_end = $ - 1

    stack1 rb 4096
    stack1_end:
    stack2 rb 4096
    stack2_end:

section '.text' executable

_start:
    ; Запуск потоков (Человек A1 и A2)
    mov rdx, person_A1
    mov rsi, stack1_end
    call spawn_thread

    mov rdx, person_A2
    mov rsi, stack2_end
    call spawn_thread

    ; Главный процесс спит
    mov rax, 34 ; sys_pause
    syscall

; --- Логика Человека A1 ---
person_A1:
    mov r14, msg_l1
    mov r15, msg_l1_len
    jmp person_logic

; --- Логика Человека A2 ---
person_A2:
    mov r14, msg_l2
    mov r15, msg_l2_len
    jmp person_logic

person_logic:
    ; 1. Ждем случайную вспышку лампочки
    rdrand rax
    and rax, 0x0FFFFFFF ; случайная пауза
  .wait_flash: 
    dec rax
    jnz .wait_flash

    ; Увидел вспышку
    mov rsi, r14
    mov rdx, r15
    call print_string

    ; 2. пошел к доске
  .lock:
    mov eax, 1
    xchg eax, [mutex]  ; меняем на 1 
    test eax, eax
    jnz .lock

    ; 3. ЗАПОМИНАЕМ число с доски
    mov r12, [board] ;

    ; 4. ИДЕМ ВЫКЛЮЧАТЬ лампочку
    mov rcx, 0x0FFFFFFF
  .walking: 
    loop .walking

    ; 5. ВОЗВРАЩАЕМСЯ и записываем (число + 1)
    inc r12
    mov [board], r12

    ; ВЫВОД: Результат
    mov rsi, msg_ret
    mov rdx, msg_ret_len
    call print_string
    mov rax, r12
    call print_number
    call print_newline

    ; 6. отошел от доски
    mov dword [mutex], 0
    jmp person_logic




; --- Вспомогательные функции ---

spawn_thread:
    mov rdi, 0x0f00 ; CLONE_VM|FS|FILES|SIGHAND
    mov rax, 56     ; sys_clone
    syscall
    test rax, rax
    jz .child
    ret
.child:
    call rdx
    mov rax, 60
    xor rdi, rdi
    syscall

print_string:
    mov rax, 1      ; sys_write
    mov rdi, 1      ; stdout
    syscall
    ret

print_number:
    mov rbx, 10
    mov rdi, buffer_end
    mov rcx, 0
.conv:
    dec rdi
    xor rdx, rdx
    div rbx
    add dl, '0'
    mov [rdi], dl
    inc rcx
    test rax, rax
    jnz .conv
    mov rax, 1
    mov rsi, rdi
    mov rdx, rcx
    mov rdi, 1
    syscall
    ret

print_newline:
    mov byte [buffer], 10
    mov rax, 1
    mov rdi, 1
    mov rsi, buffer
    mov rdx, 1
    syscall
    ret