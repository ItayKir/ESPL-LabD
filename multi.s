section .rodata
    format_hex_first: db "%hhx", 0     ; Format for the most significant byte (NO leading zero)
    format_hex_rest: db "%02hhx", 0    ; Format for the rest of the bytes (WITH leading zero)
    format_newline: db 10, 0       

section .data
    ; 16-bit state for LFSR initialized to a non-zero seed
    STATE: dw 0xACE1        

    ; Default structs for Part 4 testing
    x_struct: db 5
    x_num: db 0xaa, 1, 2, 0x44, 0x4f
    
    y_struct: db 6
    y_num: db 0xaa, 1, 2, 3, 0x44, 0x4f

section .bss
    ; Reserve 500 bytes for our input buffer
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

; ---------------------------------------------------------
; void print_multi(struct multi *p)
; Prints a multi-precision integer in hexadecimal.
; ---------------------------------------------------------
print_multi:
    push ebp
    mov ebp, esp
    push ebx          
    push esi          

    mov ebx, [ebp+8]      
    xor eax, eax          
    mov al, byte [ebx]    
    mov esi, eax          
    dec esi               ; esi = size - 1

    cmp esi, 0
    jl .end_loop          ; If struct is completely empty, exit

    ; --- 1. Print the Most Significant Byte (NO PADDING) ---
    xor eax, eax                    
    mov al, byte [ebx + 1 + esi]    
    push eax              
    push format_hex_first       
    call printf
    add esp, 8            
    dec esi               ; Move to the next byte down

    ; --- 2. Print all Remaining Bytes (ZERO PADDED) ---
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

; ---------------------------------------------------------
; struct multi* getmulti()
; Reads a line of hex digits from stdin and returns a struct. 
; ---------------------------------------------------------
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

; ---------------------------------------------------------
; Helper Subroutine: char_to_hex
; ---------------------------------------------------------
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

; ---------------------------------------------------------
; Part 2.A: get_max_min
; Input:  eax = struct 1, ebx = struct 2
; Output: eax = max struct, ebx = min struct
; ---------------------------------------------------------
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

; ---------------------------------------------------------
; Part 2.B: add_multi 
; struct multi *add_multi(struct multi *p, struct multi *q)
; ---------------------------------------------------------
add_multi:
    push ebp
    mov ebp, esp
    sub esp, 16            
    push ebx
    push esi
    push edi

    ; 1. Load arguments and find max/min
    mov eax, [ebp+8]       
    mov ebx, [ebp+12]      
    call get_max_min       

    mov [ebp-4], eax       
    mov [ebp-8], ebx       

    ; 2. Extract sizes
    xor ecx, ecx
    mov cl, byte [eax]
    mov [ebp-12], ecx      

    xor edx, edx
    mov dl, byte [ebx]
    mov [ebp-16], edx      

    ; 3. Allocate Memory for result (max_size + 2)
    mov eax, [ebp-12]
    add eax, 2
    push eax
    call malloc
    add esp, 4
    mov edi, eax           

    ; 4. Set initial result size
    mov ecx, [ebp-12]
    mov byte [edi], cl     

    ; 5. Calculate remaining size
    sub ecx, [ebp-16]      
    mov [ebp-12], ecx      

    ; 6. Prepare for Min Loop
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
    
    ; Handle final carry overflow
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

; ---------------------------------------------------------
; Part 3: rand_num
; uint16_t rand_num()
; Generates a pseudo-random number using a 16-bit LFSR.
; Taps: 16, 14, 13, 11 (0-indexed: 15, 13, 12, 10)
; ---------------------------------------------------------
rand_num:
    push ebp
    mov ebp, esp
    push ebx
    push ecx

    xor eax, eax
    mov ax, word [STATE]      ; Load current state

    ; Extract bit 15 (16th bit)
    mov ebx, eax
    shr ebx, 15
    and ebx, 1

    ; Extract bit 13 (14th bit)
    mov ecx, eax
    shr ecx, 13
    and ecx, 1
    xor ebx, ecx              ; XOR with previous

    ; Extract bit 12 (13th bit)
    mov ecx, eax
    shr ecx, 12
    and ecx, 1
    xor ebx, ecx              ; XOR with previous

    ; Extract bit 10 (11th bit)
    mov ecx, eax
    shr ecx, 10
    and ecx, 1
    xor ebx, ecx              ; XOR with previous

    ; ebx now holds the newly calculated input bit
    ; Shift state left by 1 to make room
    shl eax, 1

    ; Put the new input bit into the LSB (bit 0)
    or eax, ebx

    ; Update the global STATE
    mov word [STATE], ax
    
    ; Clear upper 16 bits of eax just to be clean
    and eax, 0xFFFF

    pop ecx
    pop ebx
    mov esp, ebp
    pop ebp
    ret

; ---------------------------------------------------------
; Part 3: PRmulti
; struct multi* PRmulti()
; Generates a multi-precision integer of pseudo-random length 
; (1-16 bytes), filled completely with random bytes!
; ---------------------------------------------------------
PRmulti:
    push ebp
    mov ebp, esp
    push ebx
    push esi
    push edi

    ; 1. Generate random length (mask to 0-15, then +1 = 1 to 16 bytes)
    call rand_num
    and eax, 0x0F           
    inc eax                 
    mov ebx, eax            ; Save size in callee-saved register ebx

    ; 2. Allocate memory: size + 1 bytes
    mov eax, ebx
    inc eax                 
    push eax
    call malloc
    add esp, 4
    mov edi, eax            ; Save struct pointer in callee-saved register edi

    ; 3. Set the size byte
    mov byte [edi], bl

    ; 4. Fill the array with random bytes
    xor esi, esi            ; esi = loop index 
.pr_loop:
    cmp esi, ebx
    jge .pr_done

    call rand_num           ; eax = random 16-bit number
    ; We take the lowest 8 bits (al) to fill our struct byte
    mov byte [edi + 1 + esi], al

    inc esi
    jmp .pr_loop

.pr_done:
    mov eax, edi            ; Return the dynamically allocated pointer

    pop edi
    pop esi
    pop ebx
    mov esp, ebp
    pop ebp
    ret

; ---------------------------------------------------------
; Part 4: main
; Entry point orchestrating Part 4 command line switches.
; ---------------------------------------------------------
main:
    push ebp
    mov ebp, esp
    push ebx               
    push esi               
    push edi

    ; Get argc and argv passed to main
    mov ecx, [ebp+8]        ; ecx = argc
    mov edx, [ebp+12]       ; edx = argv

    ; Check if no arguments were provided (argc == 1)
    cmp ecx, 1
    jle .default_mode

    ; Load argv[1] pointer into eax
    mov eax, [edx+4]
    
    ; Check if argv[1] starts with '-'
    cmp byte [eax], '-'
    jne .default_mode
    
    ; Check the character following '-'
    cmp byte [eax+1], 'I'
    je .input_mode
    
    cmp byte [eax+1], 'R'
    je .random_mode
    
    ; If flag unrecognized, fall back to default
    jmp .default_mode

.default_mode:
    ; Use pre-initialized structs (x_struct, y_struct)
    mov esi, x_struct
    mov edi, y_struct
    jmp .do_add

.input_mode:
    ; Read first number from stdin
    call getmulti
    mov esi, eax            ; esi = struct 1
    
    ; Read second number from stdin
    call getmulti
    mov edi, eax            ; edi = struct 2
    jmp .do_add

.random_mode:
    ; Generate first random number
    call PRmulti
    mov esi, eax            ; esi = struct 1
    
    ; Generate second random number
    call PRmulti
    mov edi, eax            ; edi = struct 2
    jmp .do_add

.do_add:
    ; Print the first number
    push esi
    call print_multi
    add esp, 4

    ; Print the second number
    push edi
    call print_multi
    add esp, 4

    ; Add the numbers (pass q then p)
    push edi
    push esi
    call add_multi
    add esp, 8

    ; Print the addition result
    push eax
    call print_multi
    add esp, 4

    ; Return 0 and exit gracefully
    mov eax, 0

    pop edi
    pop esi
    pop ebx
    mov esp, ebp
    pop ebp
    ret