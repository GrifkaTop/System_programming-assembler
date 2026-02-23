;;My library of useful functions named lib.asm

;Function exit
exit:
     mov rax, 60
     mov rdi, 0
     syscall


;Function error_exit 
error_exit:
    mov rax, 60
    mov rdi, 1
    syscall


;Function printing of string
;input rsi - place of memory of begin string
print_str:
    push rax
    push rdi
    push rdx
    push rcx
    mov rax, rsi
    call len_str
    mov rdx, rax
    mov rax, 1
    mov rdi, 1
    syscall
    pop rcx
    pop rdx
    pop rdi
    pop rax
    ret

;The function makes new line
new_line:
   push rax
   push rdi
   push rsi
   push rdx
   push rcx
   mov rax, 0xA
   push rax
   mov rdi, 1
   mov rsi, rsp
   mov rdx, 1
   mov rax, 1
   syscall
   pop rax
   pop rcx
   pop rdx
   pop rsi
   pop rdi
   pop rax
   ret


;The function finds the length of a string
;input rax - place of memory of begin string
;output rax - length of the string
len_str:
  push rdx
  mov rdx, rax
  .iter:
      cmp byte [rax], 0
      je .next
      inc rax
      jmp .iter
  .next:
     sub rax, rdx
     pop rdx
     ret


;The function converts the nubmer to string
;input rax - number
;rsi -address of begin of string
number_str:
    push rbx
    push rcx
    push rdx
    push rdi
  
    mov rdi, rsi 
    xor rcx, rcx
    mov rbx, 10

    test rax, rax
    jns .positive
    neg rax 
    mov byte [rdi], '-'
    inc rdi

    .positive:
    .loop_1:
        xor rdx, rdx
        div rbx
        add rdx, 48
        push rdx
        inc rcx
        cmp rax, 0
        jne .loop_1


    .loop_2:
        pop rax
        mov byte [rdi], al
        inc rdi
        loop .loop_2

    mov byte [rdi], 0
    
    pop rdi
    pop rdx
    pop rcx
    pop rbx
    ret


;The function realizates user input from the keyboard
;input: rsi - place of memory saved input string 
input_keyboard:
  push rax
  push rdi
  push rdx

  mov rax, 0
  mov rdi, 0
  mov rdx, 255
  syscall

  xor rcx, rcx
  .loop:
     mov al, [rsi+rcx]
     inc rcx
     cmp rax, 0x0A
     jne .loop
  dec rcx
  mov byte [rsi+rcx], 0
  
  pop rdx
  pop rdi
  pop rax
  ret


section '.data' writable
place db 0 
overflow_error db "error: overflow", 0

;Function converting the string to the number
;input rsi - place of memory of begin string
;output rax - the number from the string
str_number:
    push rbx
    push rcx
    push rdx
    
    xor rax, rax
    xor rbx, rbx
    xor rcx, rcx

    cmp byte [rsi], '-'
    jne .convert_loop
    mov rcx, 1
    inc rsi
    
    .convert_loop:
        mov bl, [rsi]
        test bl, bl
        jz .apply_sign
        
        cmp bl, '0'
        jb .done
        cmp bl, '9'
        ja .done
        
        sub bl, '0'

        push rbx
        mov rbx, rax
        mov rax, rbx
        mov rdx, 10
        imul rdx
        jo .overflow_pop

        test rdx, rdx
        jnz .overflow_pop

        pop rbx
        add rax, rbx
        jo .overflow
        
        inc rsi
        jmp .convert_loop

    .apply_sign:
        test rcx, rcx
        jz .done
        neg rax
        jo .overflow
        
    .done:
        pop rdx
        pop rcx
        pop rbx
        ret

    .overflow_pop:
        pop rbx
    .overflow:
        mov rsi, overflow_error
        call print_str
        call new_line
        call error_exit


;Function cheks if the string can be interpreted as a number
;input rsi - place of memory of begin string
;output rax = 1 (valid number), 0 (invalid number)
validate_number:
    push rsi
    push rbx

    xor rbx, rbx

    cmp byte [rsi], 0
    je .invalid

    cmp byte [rsi], '-' 
    jne .check_loop
    inc rsi
    cmp byte [rsi], 0
    je .invalid    
    
    .check_loop:
        mov al, [rsi]
        test al, al
        jz .check_done

        cmp al, '0'
        jb .invalid
        cmp al, '9'
        ja .invalid
        
        inc rbx
        inc rsi
        jmp .check_loop

    .check_done:
        test rbx, rbx
        jz .invalid
        
        mov rax, 1
        jmp .done

    .invalid:
        xor rax, rax

    .done:
        pop rbx
        pop rsi
        ret

; --- print_int ---
print_int:
    push rax
    push rsi
    push rcx
    push rdx
    mov rsi, .int_buffer ; или ваш place
    call number_str
    call print_str
    pop rdx
    pop rcx
    pop rsi
    pop rax
    ret

;  буффер
section '.data' writeable
    .int_buffer rb 32     ; Буфер для хранения строкового представления числа