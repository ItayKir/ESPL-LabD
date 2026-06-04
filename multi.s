section .rodata
    ; Format string for printing argc as a decimal integer with a newline
    format_argc: db "%d", 10, 0 

section .text
    global main       ; Global label for the entry point 
    extern printf     ; External reference to stdlib printf 
    extern puts       ; External reference to stdlib puts 

main:
    ; Function Prologue: Setup stack frame and preserve registers
    push ebp
    mov ebp, esp
    push ebx          
    push esi          
    push edi          

    ; In CDECL, arguments are passed on the stack above the return address
    ; [ebp+8]  = argc
    ; [ebp+12] = argv (pointer to an array of string pointers)
    
    mov esi, [ebp+8]  ; Store argc in esi for safe-keeping
    mov ebx, [ebp+12] ; Store argv in ebx for safe-keeping

    ; Print argc using printf 
    push esi          ; Push argc (second argument to printf)
    push format_argc  ; Push format string (first argument to printf)
    call printf
    add esp, 8        ; CDECL requires the caller to clean up the stack (2 args * 4 bytes)

    ; Setup loop to print argv[i] from 0 to argc-1
    xor edi, edi      ; Initialize loop counter i = 0 (stored in edi)

.print_loop:
    cmp edi, esi      ; Compare i (edi) with argc (esi)
    jge .end_loop     ; If i >= argc, jump to the end of the loop

    ; Calculate the address of argv[i] -> argv base address + (i * 4 bytes)
    mov eax, [ebx + edi*4] 
    
    ; Print argv[i] using puts 
    push eax          ; Push the string pointer
    call puts
    add esp, 4        ; Clean up stack (1 arg * 4 bytes)

    inc edi           ; i++
    jmp .print_loop   ; Jump back to the start of the loop

.end_loop:
    ; Function Epilogue: Restore preserved registers and stack frame
    pop edi
    pop esi
    pop ebx
    mov esp, ebp
    pop ebp
    
    ; Return 0 to indicate successful execution
    mov eax, 0
    ret