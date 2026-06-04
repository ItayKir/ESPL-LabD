section .rodata
    format_hex: db "%02hhx", 0     
    format_newline: db 10, 0       

section .data
    ; First struct (size 5)
    x_struct: db 5
    x_num: db 0xaa, 0x01, 0x02, 0x44, 0x4f

    ; Second struct (size 6)
    y_struct: db 6
    y_num: db 0xaa, 0x01, 0x02, 0x03, 0x44, 0x4f

section .bss
    ; Reserve 500 bytes for our input buffer
    input_buffer: resb 500

section .text
    global main
    global print_multi
    global getmulti
    global get_max_min
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
    dec esi               

.print_loop:
    cmp esi, 0
    jl .end_loop          

    xor eax, eax                    
    mov al, byte [ebx + 1 + esi]    

    push eax              
    push format_hex       
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
; Reads a line of hex digits from stdin and returns a dynamically
; allocated struct multi. 
; ---------------------------------------------------------
getmulti:
    push ebp
    mov ebp, esp
    push ebx
    push esi
    push edi

    ; 1. Read from stdin into input_buffer + 1
    mov eax, [stdin]
    push eax                      
    push 490                      
    push input_buffer + 1         
    call fgets
    add esp, 12                   

    ; 2. Calculate the length of the inputted string 
    mov esi, input_buffer + 1
    xor ecx, ecx                  
.find_len:
    xor eax, eax
    mov al, byte [esi + ecx]
    cmp al, 10                    ; Check for newline '\n'
    je .found_end
    cmp al, 0                     ; Check for null terminator '\0'
    je .found_end
    inc ecx
    jmp .find_len

.found_end:
    ; 3. Handle Odd vs Even length
    mov ebx, input_buffer + 1     
    mov eax, ecx
    and eax, 1                    
    jz .is_even                   

.is_odd:
    mov byte [input_buffer], '0'  
    mov ebx, input_buffer         
    inc ecx                       

.is_even:
    ; 4. Allocate memory for struct multi
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

    ; 5. Set the size byte in the struct
    mov byte [edi], dl            

    ; 6. Parse pairs of hex characters and write them backwards
    dec edx                       
    mov esi, ebx                  

.parse_loop:
    cmp ecx, 0
    jle .done_parsing

    ; Read first hex character (Upper nibble)
    xor eax, eax
    mov al, byte [esi]
    call char_to_hex
    shl al, 4                     
    mov bl, al                    

    ; Read second hex character (Lower nibble)
    xor eax, eax
    mov al, byte [esi + 1]
    call char_to_hex
    or bl, al                     

    ; Write the fully constructed byte to the struct
    mov byte [edi + 1 + edx], bl

    ; Update pointers and counters
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
; Converts an ASCII character in AL to its integer hex value in AL.
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
; Input:  eax = pointer to struct multi 1
;         ebx = pointer to struct multi 2
; Output: eax = pointer to struct with the larger size
;         ebx = pointer to struct with the smaller size
; Note:   Does NOT use the standard CDECL calling convention.
; ---------------------------------------------------------
get_max_min:
    ; Save registers we will use for comparison
    push ecx
    push edx

    ; Read the size byte from the first struct (pointed to by eax)
    xor ecx, ecx
    mov cl, byte [eax]
    
    ; Read the size byte from the second struct (pointed to by ebx)
    xor edx, edx
    mov dl, byte [ebx]

    ; Compare sizes
    cmp cl, dl
    jge .done_max_min  ; If eax's struct size >= ebx's struct size, do nothing

    ; If we drop down to here, the struct in ebx is larger.
    ; Swap the pointers so eax holds the maximum!
    xchg eax, ebx

.done_max_min:
    ; Restore used registers
    pop edx
    pop ecx
    ret

; ---------------------------------------------------------
; main
; Entry point to test the functions
; ---------------------------------------------------------
main:
    push ebp
    mov ebp, esp

    ; Setup inputs for get_max_min
    mov eax, x_struct       ; size 5
    mov ebx, y_struct       ; size 6

    ; Call get_max_min (Custom Calling Convention)
    call get_max_min
    
    ; After this call, eax will strictly point to y_struct 
    ; because 6 > 5. Let's verify by printing eax!
    push eax
    call print_multi
    add esp, 4            

    mov eax, 0
    mov esp, ebp
    pop ebp
    ret