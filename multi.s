section .rodata
    format_hex_first: db "%hhx", 0     ; msb format
    format_hex_rest: db "%02hhx", 0    ; rest format
    format_newline: db 10, 0       

section .data
    ; lfsr seed
    STATE: dw 0xACE1        

    ; default structs
    x_struct: db 5
    x_num: db 0xaa, 1, 2, 0x44, 0x4f
    
    y_struct: db 6
    y_num: db 0xaa, 1, 2, 3, 0x44, 0x4f

section .bss
    ; 500b input buffer
    input_buffer: resb 500

section .text
    global main
    global print_multi
    global getmulti
    global get_max_min
    global add_multi
    global rand_num
    global PRmulti
    
    extern printf
    extern fgets
    extern stdin
    extern malloc

; print multi in hex
print_multi:
    push ebp
    mov ebp, esp
    push ebx          
    push esi          

    mov ebx, [ebp+8]      
    xor eax, eax          
    mov al, byte [ebx]    
    mov esi, eax          
    dec esi               ; size - 1

    cmp esi, 0
    jl .end_loop          ; exit if empty

    ; print msb
    xor eax, eax                    
    mov al, byte [ebx + 1 + esi]    
    push eax              
    push format_hex_first       
    call printf
    add esp, 8            
    dec esi               ; next byte

    ; print rest
.print_loop:
    cmp esi, 0
    jl .end_loop          

    xor eax, eax                    
    mov al, byte [ebx + 1 + esi]    
    push eax              
    push format_hex_rest       
    call printf
    add esp, 8            

    dec esi               
    jmp .print_loop

.end_loop:
    push format_newline
    call printf
    add esp, 4

    pop esi
    pop ebx
    mov esp, ebp
    pop ebp
    ret

; read hex to struct
getmulti:
    push ebp
    mov ebp, esp
    push ebx
    push esi
    push edi

    mov eax, [stdin]
    push eax                      
    push 490                      
    push input_buffer + 1         
    call fgets
    add esp, 12                   

    mov esi, input_buffer + 1
    xor ecx, ecx                  
.find_len:
    xor eax, eax
    mov al, byte [esi + ecx]
    cmp al, 10                    
    je .found_end
    cmp al, 0                     
    je .found_end
    inc ecx
    jmp .find_len

.found_end:
    mov ebx, input_buffer + 1     
    mov eax, ecx
    and eax, 1                    
    jz .is_even                   

.is_odd:
    mov byte [input_buffer], '0'  
    mov ebx, input_buffer         
    inc ecx                       

.is_even:
    mov eax, ecx
    shr eax, 1                    
    push eax                      
    inc eax                       
    
    push ecx                      
    push eax                      
    call malloc
    add esp, 4                    
    pop ecx                       

    pop edx                       
    mov edi, eax                  

    mov byte [edi], dl            

    dec edx                       
    mov esi, ebx                  

.parse_loop:
    cmp ecx, 0
    jle .done_parsing

    xor eax, eax
    mov al, byte [esi]
    call char_to_hex
    shl al, 4                     
    mov bl, al                    

    xor eax, eax
    mov al, byte [esi + 1]
    call char_to_hex
    or bl, al                     

    mov byte [edi + 1 + edx], bl

    add esi, 2                    
    dec edx                       
    sub ecx, 2                    
    jmp .parse_loop

.done_parsing:
    mov eax, edi                  

    pop edi
    pop esi
    pop ebx
    mov esp, ebp
    pop ebp
    ret

; char to hex
char_to_hex:
    cmp al, '9'
    jle .is_digit
    cmp al, 'F'
    jle .is_upper
.is_lower:
    sub al, 'a' - 10
    ret
.is_upper:
    sub al, 'A' - 10
    ret
.is_digit:
    sub al, '0'
    ret

; get max min structs
get_max_min:
    push ecx
    push edx

    xor ecx, ecx
    mov cl, byte [eax]
    xor edx, edx
    mov dl, byte [ebx]

    cmp cl, dl
    jge .done_max_min  
    xchg eax, ebx

.done_max_min:
    pop edx
    pop ecx
    ret

; add multi structs
add_multi:
    push ebp
    mov ebp, esp
    sub esp, 16            
    push ebx
    push esi
    push edi

    ; get args and max min
    mov eax, [ebp+8]       
    mov ebx, [ebp+12]      
    call get_max_min       

    mov [ebp-4], eax       
    mov [ebp-8], ebx       

    ; get sizes
    xor ecx, ecx
    mov cl, byte [eax]
    mov [ebp-12], ecx      

    xor edx, edx
    mov dl, byte [ebx]
    mov [ebp-16], edx      

    ; alloc result mem
    mov eax, [ebp-12]
    add eax, 2
    push eax
    call malloc
    add esp, 4
    mov edi, eax           

    ; set res size
    mov ecx, [ebp-12]
    mov byte [edi], cl     

    ; calc rem size
    sub ecx, [ebp-16]      
    mov [ebp-12], ecx      

    ; prep min loop
    mov ecx, [ebp-16]      
    xor esi, esi           
    clc                    

.min_loop:
    jecxz .max_loop_prep   

    mov eax, [ebp-4]       
    mov ebx, [ebp-8]       

    mov al, byte [eax + 1 + esi]
    mov bl, byte [ebx + 1 + esi]

    adc al, bl             
    mov byte [edi + 1 + esi], al

    inc esi                
    dec ecx                
    jmp .min_loop

.max_loop_prep:
    mov ecx, [ebp-12]      
.max_loop:
    jecxz .check_carry     

    mov eax, [ebp-4]       
    mov al, byte [eax + 1 + esi]

    adc al, 0              
    mov byte [edi + 1 + esi], al

    inc esi
    dec ecx
    jmp .max_loop

.check_carry:
    jnc .done              
    
    ; handle carry
    mov byte [edi + 1 + esi], 1   
    inc byte [edi]                

.done:
    mov eax, edi           

    pop edi
    pop esi
    pop ebx
    mov esp, ebp
    pop ebp
    ret

; 16-bit lfsr rand
rand_num:
    push ebp
    mov ebp, esp
    push ebx
    push ecx

    xor eax, eax
    mov ax, word [STATE]      ; load state

    ; get bit 15
    mov ebx, eax
    shr ebx, 15
    and ebx, 1

    ; get bit 13
    mov ecx, eax
    shr ecx, 13
    and ecx, 1
    xor ebx, ecx              ; xor prev

    ; get bit 12
    mov ecx, eax
    shr ecx, 12
    and ecx, 1
    xor ebx, ecx              ; xor prev

    ; get bit 10
    mov ecx, eax
    shr ecx, 10
    and ecx, 1
    xor ebx, ecx              ; xor prev

    ; new bit in ebx
    ; shift state left
    shl eax, 1

    ; bit 0 to lsb
    or eax, ebx

    ; update state
    mov word [STATE], ax
    
    ; clear upper eax
    and eax, 0xFFFF

    pop ecx
    pop ebx
    mov esp, ebp
    pop ebp
    ret

; gen rand multi
PRmulti:
    push ebp
    mov ebp, esp
    push ebx
    push esi
    push edi

    ; gen rand len
    call rand_num
    and eax, 0x0F           
    inc eax                 
    mov ebx, eax            ; save size in ebx

    ; alloc mem
    mov eax, ebx
    inc eax                 
    push eax
    call malloc
    add esp, 4
    mov edi, eax            ; save ptr in edi

    ; set size byte
    mov byte [edi], bl

    ; fill rand bytes
    xor esi, esi            ; loop idx
.pr_loop:
    cmp esi, ebx
    jge .pr_done

    call rand_num           ; rand 16 bit
    ; fill with al
    mov byte [edi + 1 + esi], al

    inc esi
    jmp .pr_loop

.pr_done:
    mov eax, edi            ; ret ptr

    pop edi
    pop esi
    pop ebx
    mov esp, ebp
    pop ebp
    ret

; main entry
main:
    push ebp
    mov ebp, esp
    push ebx               
    push esi               
    push edi

    ; get argc argv
    mov ecx, [ebp+8]        ; argc
    mov edx, [ebp+12]       ; argv

    ; check no args
    cmp ecx, 1
    jle .default_mode

    ; argv[1] to eax
    mov eax, [edx+4]
    
    ; check flag dash
    cmp byte [eax], '-'
    jne .default_mode
    
    ; check flag char
    cmp byte [eax+1], 'I'
    je .input_mode
    
    cmp byte [eax+1], 'R'
    je .random_mode
    
    ; fallback to default
    jmp .default_mode

.default_mode:
    ; use default structs
    mov esi, x_struct
    mov edi, y_struct
    jmp .do_add

.input_mode:
    ; read first stdin
    call getmulti
    mov esi, eax            ; struct 1
    
    ; read second stdin
    call getmulti
    mov edi, eax            ; struct 2
    jmp .do_add

.random_mode:
    ; gen first rand
    call PRmulti
    mov esi, eax            ; struct 1
    
    ; gen sec rand
    call PRmulti
    mov edi, eax            ; struct 2
    jmp .do_add

.do_add:
    ; print first
    push esi
    call print_multi
    add esp, 4

    ; print second
    push edi
    call print_multi
    add esp, 4

    ; add nums
    push edi
    push esi
    call add_multi
    add esp, 8

    ; print result
    push eax
    call print_multi
    add esp, 4

    ; exit 0
    mov eax, 0

    pop edi
    pop esi
    pop ebx
    mov esp, ebp
    pop ebp
    ret