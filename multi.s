section .rodata
    format_hex: db "%02hhx", 0     ; Format string for printing a single hex byte
    format_newline: db 10, 0       ; Newline character 

section .data
    ; Test struct initialized as per the assignment instructions
    x_struct: db 5
    x_num: db 0xaa, 0x01, 0x02, 0x44, 0x4f

section .text
    global main
    global print_multi
    extern printf

; ---------------------------------------------------------
; void print_multi(struct multi *p)
; Prints a multi-precision integer in hexadecimal.
; ---------------------------------------------------------
print_multi:
    ; Function Prologue
    push ebp
    mov ebp, esp
    push ebx          ; Callee-saved: we will use this for the struct pointer
    push esi          ; Callee-saved: we will use this for the loop index

    mov ebx, [ebp+8]      ; ebx = pointer to struct multi p
    
    ; Read the size byte (without movzx)
    xor eax, eax          ; Clear eax (eax = 0) so the upper 24 bits are clean
    mov al, byte [ebx]    ; Move the 8-bit size into the lowest 8 bits of eax
    mov esi, eax          ; Transfer the clean 32-bit value into esi

    ; Because the number is little-endian, we print from the most significant byte 
    ; to the least significant byte. We start at index (size - 1).
    dec esi               ; esi = size - 1

.print_loop:
    cmp esi, 0
    jl .end_loop          ; If index < 0, we have printed all bytes

    ; Calculate address of p->num[esi] and load it (without movzx):
    xor eax, eax                    ; Clear eax completely
    mov al, byte [ebx + 1 + esi]    ; Load the current data byte into al

    ; Call printf("%02hhx", value)
    push eax              ; Push the zero-extended byte value
    push format_hex       ; Push the format string
    call printf
    add esp, 8            ; Clean up stack (2 args * 4 bytes)

    dec esi               ; Decrement index
    jmp .print_loop

.end_loop:
    ; Print a linefeed at the end
    push format_newline
    call printf
    add esp, 4

    ; Function Epilogue
    pop esi
    pop ebx
    mov esp, ebp
    pop ebp
    ret

; ---------------------------------------------------------
; main
; Entry point to test print_multi
; ---------------------------------------------------------
main:
    push ebp
    mov ebp, esp

    ; Call print_multi passing the address of x_struct
    push x_struct
    call print_multi
    add esp, 4            ; Clean up stack

    ; Return 0
    mov eax, 0
    mov esp, ebp
    pop ebp
    ret