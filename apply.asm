    enter 0, 0                        ; set up our frame

    ; --- (1) Load caller’s COUNT from [rbp+16] ---
    mov rax, qword [rbp + 2 * 8]           ; rax := arg count
    cmp rax, 2
    jb L_error_arg_count_2            ; error if arg < 2

    ; Compute n = arg - 2
    mov r8, rax                     ; r8 := args
    sub r8, 2                       ; r8 := n

    ; retrieve the closure
    mov rbx, qword [rbp + 3 * 8]           ; rbx := closure object

    ; k := expected user args.
    mov r13, 1                      ; r13 = k 
    mov r14, r13
    inc r14                         ; r14 = expected args in new frame

    ; compute the list address
    mov r10, rax                    ; r10 := caller args
    dec r10                         
    mov r9, qword [rbp + (3 * 8) + (r10 * 1 * 8)]     ; r9 := spliced list

    ; m := length of the spliced list
    xor r11, r11                    ; r11 := m = 0

apply_length_loop:
    cmp r9, sob_nil                 ; if spliced list equals nil, done
    je  apply_length_done
    cmp byte [r9], T_pair           ; check that cell is a pair
    jne L_error_improper_list
    inc r11                         ; m++
    mov r9, qword [r9 + 2 * 8]           ; r9 := the cdr of the list
    jmp apply_length_loop

apply_length_done:

    ; verifying the expected user args 
    mov r12, r8                     ; r12 := n
    add r12, r11                    ; r12 = n + m
    cmp r12, r13
    jne L_error_incorrect_arity     ; if not equal, signal arity error

    ; Allocate a new call frame.
    mov rax, r13                    ; rax = k
    imul rax, 8                     ; rax = k * 1 * 8
    add rax, 16                     ; total size = 2 * 8 + (k * 8)
    sub rsp, rax                    ; allocate new frame on stack

    ; New frame layout (relative to new RSP):
    ;   [rsp]       : saved RBP (we copy caller’s RBP)
    ;   [rsp + 1 * 8]     : dummy return address (0)
    ;   [rsp + 2 * 8]    : new args count (should be 2)
    ;   [rsp + 3 * 8]    : arg 0
    mov qword [rsp], rbp            ; copy caller’s RBP into header slot 0
    mov qword [rsp + 1 * 8], 0            ; dummy return address
    mov qword [rsp + 2 * 8], r14         ; store new frame COUNT = 2

    ; Copy explicit arguments from caller into new frame.
    xor rsi, rsi                    ; rsi := 0 (loop counter)

copy_explicit:
    cmp rsi, r8
    jge copy_explicit_done
    mov rdi, qword [rbp + (4 * 8) + rsi * 1 * 8]    ; load caller’s PARAM(rsi+1)
    mov qword [rsp + 3 * 8 + rsi * 1 *8], rdi    ; store into new frame slot (starting at offset 24)
    inc rsi
    jmp copy_explicit

copy_explicit_done:

    ; Flatten the spliced list into the new frame.
    mov r10, qword [rbp + 2 * 8]         ; r10 := caller args
    dec r10                         
    mov rdx, qword [rbp+24 + r10 * 1 * 8]    ; rdx := spliced list

flatten_loop:
    cmp rdx, sob_nil
    je flatten_done
    cmp byte [rdx], T_pair
    jne L_error_improper_list
    mov rdi, qword [rdx + 1 * 8]             ; car of current cell
    mov qword [rsp + 3 * 8 + rsi * 1* 8], rdi    ; store into next free slot
    inc rsi
    mov rdx, qword [rdx + 2 * 8]            ; advance to cdr
    jmp flatten_loop

flatten_done:

    ; tail call optimization
    mov rbp, rsp
    mov rax, qword [rbx + 2 * 8]            ; rax := closure’s code pointer
    jmp rax

L_error_incorrect_arity:
    mov rdi, qword [stderr]
    mov rsi, fmt_incorrect_arity_simple
    mov rdx, r12    
    mov rax, 0
    ENTER
    call fprintf
    LEAVE
    mov rax, -6
    call exit