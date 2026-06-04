section .rodata
    format_hex: db "%02hhx", 0     
    format_newline: db 10, 0       

section .data
    x_struct: db 5
    x_num: db 0xaa, 0x01, 0x02, 0x44, 0x4f

section .bss
    ; Reserve 500 bytes for our input buffer
    input_buffer: resb 500

section .text
    global main
    global print_multi
    global getmulti
    extern printf
    extern fgets
    extern stdin
    extern malloc

; ---------------------------------------------------------
; void print_multi(struct multi *p)
; (Same as Part 1.A, included here for completeness)
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
    ; fgets(input_buffer + 1, 490, stdin)
    mov eax, [stdin]
    push eax                      ; arg 3: FILE *stream
    push 490                      ; arg 2: int size
    push input_buffer + 1         ; arg 1: char *str
    call fgets
    add esp, 12                   ; Clean up 3 args

    ; 2. Calculate the length of the inputted string 
    mov esi, input_buffer + 1
    xor ecx, ecx                  ; ecx will act as our length counter
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
    mov ebx, input_buffer + 1     ; Default start pointer
    mov eax, ecx
    and eax, 1                    ; Bitwise AND with 1 (checks if odd)
    jz .is_even                   ; If zero, it's even

.is_odd:
    mov byte [input_buffer], '0'  ; Prepend a '0' to the buffer
    mov ebx, input_buffer         ; Update start pointer to include the '0'
    inc ecx                       ; Increase length by 1 (it is now even)

.is_even:
    ; 4. Allocate memory for struct multi
    mov eax, ecx
    shr eax, 1                    ; eax = ecx / 2 (number of data bytes)
    push eax                      ; Save the data size for later (to be popped into edx)
    inc eax                       ; Add 1 for the struct's size byte
    
    ; --- THE FIX: PRESERVE ECX ---
    push ecx                      ; malloc clobbers ecx, so we must save it!
    push eax                      ; Push total allocation size
    call malloc
    add esp, 4                    ; Clean up malloc arg
    pop ecx                       ; Restore our string length back into ecx!
    ; -----------------------------

    pop edx                       ; edx = number of data bytes (struct size)
    mov edi, eax                  ; edi = pointer to newly allocated struct

    ; 5. Set the size byte in the struct
    mov byte [edi], dl            ; p->size = edx

.parse_loop:
    cmp ecx, 0
    jle .done_parsing

    ; Read first hex character (Upper nibble)
    xor eax, eax
    mov al, byte [esi]
    call char_to_hex
    shl al, 4                     ; Shift to the upper 4 bits
    mov bl, al                    ; Temporarily store in bl

    ; Read second hex character (Lower nibble)
    xor eax, eax
    mov al, byte [esi + 1]
    call char_to_hex
    or bl, al                     ; Combine with upper nibble

    ; Write the fully constructed byte to the struct
    mov byte [edi + 1 + edx], bl

    ; Update pointers and counters
    add esi, 2                    ; Advance read pointer by 2 characters
    dec edx                       ; Decrement write index
    sub ecx, 2                    ; We processed 2 characters
    jmp .parse_loop

.done_parsing:
    mov eax, edi                  ; Return the struct pointer in eax

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
; main
; Entry point to test getmulti and print_multi
; ---------------------------------------------------------
main:
    push ebp
    mov ebp, esp

    ; Call getmulti to read from stdin
    call getmulti
    
    ; getmulti returns the struct pointer in eax. 
    ; Pass it directly to print_multi to verify the input!
    push eax
    call print_multi
    add esp, 4            

    mov eax, 0
    mov esp, ebp
    pop ebp
    ret