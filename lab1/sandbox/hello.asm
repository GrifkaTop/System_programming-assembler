format ELF
public _start

section '.data' writeable
    fio db 'Toporets', 0xA, 'Grigory', 0xA, 'Aleksandrovish', 10
    fio_len = $ - fio

section '.text' executable
_start:
    ; Системный вызов write (EAX = 4)
    mov eax, 4          
    mov ebx, 1          ;  stdout (1 - стандартный вывод) 
    mov ecx, fio        
    mov edx, fio_len    
    int 0x80            ;  

    ; Системный вызов exit (EAX = 1)
    mov eax, 1          ; sys_exit
    xor ebx, ebx        ; 
    int 0x80            ; Вызов ядра для завершения программы