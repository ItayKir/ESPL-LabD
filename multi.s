section .rodata
    format_hex: db "%02hhx", 0     
    format_newline: db 10, 0       
    prompt1: db "Enter first hex string: ", 0
    prompt2: db "Enter second hex string: ", 0
    result_msg: db "Result: ", 0

section .bss
    ; Reserve 500 bytes for our input buffer
    input_buffer: resb 500

section .text
    global main
    global print_multi
    global getmulti
    global get_max_min
    global add_multi
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
; Standard CDECL function to add two multi-precision integers.
; ---------------------------------------------------------
add_multi:
    push ebp
    mov ebp, esp
    sub esp, 16            ; Allocate local variables
    push ebx
    push esi
    push edi

    ; 1. Load arguments and find max/min
    mov eax, [ebp+8]       ; p
    mov ebx, [ebp+12]      ; q
    call get_max_min       ; eax = max_ptr, ebx = min_ptr

    mov [ebp-4], eax       ; Save max_ptr
    mov [ebp-8], ebx       ; Save min_ptr

    ; 2. Extract sizes
    xor ecx, ecx
    mov cl, byte [eax]
    mov [ebp-12], ecx      ; max_size

    xor edx, edx
    mov dl, byte [ebx]
    mov [ebp-16], edx      ; min_size

    ; 3. Allocate Memory for result (max_size + 1 for the size byte)
    mov eax, [ebp-12]
    inc eax
    push eax
    call malloc
    add esp, 4
    mov edi, eax           ; edi = result_ptr

    ; 4. Set result size
    mov ecx, [ebp-12]
    mov byte [edi], cl     ; result->size = max_size

    ; 5. Calculate iterations for the max loop (remaining_size)
    sub ecx, [ebp-16]      ; max_size - min_size
    mov [ebp-12], ecx      ; Save remaining_size

    ; 6. Prepare for Min Loop
    mov ecx, [ebp-16]      ; ecx = min_size counter
    xor esi, esi           ; esi = index 0
    clc                    ; Clear Carry Flag

.min_loop:
    jecxz .max_loop_prep   ; Jump if ecx == 0 (preserves flags)

    mov eax, [ebp-4]       ; max_ptr
    mov ebx, [ebp-8]       ; min_ptr

    mov al, byte [eax + 1 + esi]
    mov bl, byte [ebx + 1 + esi]

    adc al, bl             ; Add with carry
    mov byte [edi + 1 + esi], al

    inc esi                ; Advance index (preserves Carry Flag)
    dec ecx                ; Decrement loop counter (preserves Carry Flag)
    jmp .min_loop

.max_loop_prep:
    mov ecx, [ebp-12]      ; ecx = remaining_size counter
.max_loop:
    jecxz .done            ; Jump if ecx == 0 (preserves flags)

    mov eax, [ebp-4]       ; max_ptr
    mov al, byte [eax + 1 + esi]

    adc al, 0              ; Add remaining carry
    mov byte [edi + 1 + esi], al

    inc esi
    dec ecx
    jmp .max_loop

.done:
    mov eax, edi           ; Return result pointer in eax

    pop edi
    pop esi
    pop ebx
    mov esp, ebp
    pop ebp
    ret

; ---------------------------------------------------------
; main
; Entry point to test reading and adding two multis
; ---------------------------------------------------------
main:
    push ebp
    mov ebp, esp
    push ebx               ; Callee-saved register for p
    push esi               ; Callee-saved register for q

    ; 1. Read first number
    push prompt1
    call printf
    add esp, 4
    call getmulti
    mov ebx, eax           ; Save 'p' in ebx

    ; 2. Read second number
    push prompt2
    call printf
    add esp, 4
    call getmulti
    mov esi, eax           ; Save 'q' in esi

    ; 3. Add them (CDECL: push arguments backwards)
    push esi               ; Arg 2: q
    push ebx               ; Arg 1: p
    call add_multi
    add esp, 8             ; Clean up stack

    mov ebx, eax           ; Save result pointer in ebx

    ; 4. Print result
    push result_msg
    call printf
    add esp, 4

    push ebx
    call print_multi
    add esp, 4

    ; Return 0
    mov eax, 0
    pop esi
    pop ebx
    mov esp, ebp
    pop ebp
    ret