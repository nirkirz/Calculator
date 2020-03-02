sizeOfStack		EQU 5
sizeOfLink		EQU 5
max_input	EQU 82 ;80 as defined +2 for \n
myStackSize EQU (sizeOfStack+1)*4                   ;size of stack +1 for the 'n' action, and *4 because its addresses



 
section .bss    ; Unitialized
    myStack: resb myStackSize
    buffer: resb max_input

section .data	; Initialized
    stack_index: dd 0
    nextLink: dd 0
    number_of_operations: dd 0
    temp: dd 0
    temp1byte: db 0
    sum_starting_address: dd 0
    sum_curr_address: dd 0
    operand1: dd 0
    operand2: dd 0
    First_link_start_address: dd 0
    Second_link_start_address: dd 0
    First_link_end_address: dd 0
    Second_link_end_address: dd 0
    carry_flag: db 0
    continue_address: db 0
    ended_together: db 0
    curr_newLink: dd 0
    toduplicate: dd 0
    var_x: dd 0
    var_y: dd 0
    value_of_y: db 0
    flag_pp: db 0
    flag_np: db 0
    flag_1s: db 0
    count_num_of_1s: db 0
    starting_1s: dd 0
    curr_1s: dd 0
    prev_np: dd 0
    curr_np: dd 0
    flag_debug: dd 0
    address_to_delete: dd 0


section .rodata
    format_hexa: db "%02X", 0 ;format string for hexadecimal
    format_hexa_first: db "%X", 0 ;format string for the first hexadecimal digit
    format_string: db "%s", 0	;format string
    insufficient_error: db "Error: Insufficient Number of Arguments on Stack",10 ,0
    overflow_error: db "Error: Operand Stack Overflow",10 ,0
    Y_value_error: db "wrong Y value",10 ,0
    return_value_is: db "return value is : ", 0
    calc_print: db "calc: ",0
    println: db 10,0


section .text
  align 16
     global main 
     extern printf 
     extern fflush
     extern malloc 
     extern calloc 
     extern free 
     extern gets 
     extern fgets
     extern stdin 

;Macro:
; 1: 1st arg, 2: 2nd arg, 3: jmp condition, 4: label to jump to
%macro cmp_jmp 4 
	cmp		%1, %2
	%3		%4
%endmacro

; 1: flag 0 = even, 1 = odd
%macro change_even_flag 1
	cmp	%1, 0
    je %%end
    mov %1, -1
    %%end:
    add %1, 1
%endmacro

; 1: first digit (ahadot), 2: second digit (asarot)
%macro create_link 2
	pushad
    mov cl, %1
    mov bl, %2
    pushad
    push sizeOfLink
    call malloc     ;allocate memory for new link
    add esp,4
    mov [temp], eax
    popad
    mov edx, [nextLink]
    mov eax, [temp]
    mov [edx], eax  ;eax contains the pointer to the new memory alocation, [edx] is the address of nextLink
    cmp bl, 64
    jb %%digit
    sub bl, 55
    jmp %%finish    
    %%digit:
        sub bl, 48
    %%finish:
        shl bl, 4

    cmp cl, 64
    jb %%digit_2
    sub cl, 55
    jmp %%finish_2    
    %%digit_2:
        sub cl, 48
    %%finish_2:
    add bl, cl
    mov eax, [temp]
    mov byte[eax], bl
    inc eax             ;eax now holds the last 4 byts of the new link
    mov dword [nextLink], eax   ;nextLink now holds the next link
    mov dword [eax], 0
	popad
%endmacro

%macro loop_print_link 0
    pushad
    mov edx, myStack
    mov esi, [stack_index]
    dec esi
    shl esi, 2
    add edx, esi
    mov eax, [edx]                                  ;edx = myStack + stack_index
    push dword -1                                   ;pushing -1 as indicator 
    %%loop_push:                                    ;push to stack the addresses of links
    mov ecx, eax
    mov eax, 0
    mov al, byte[ecx]
    push eax
    inc ecx                                         ;inc to the address of the next link

    cmp_jmp dword [ecx], 0, je, %%free_last_link        ;if the adress of the next link equal 0 -> finish

    mov eax, [ecx]
    dec ecx                                         ;dec to point the start of the link (the 1 byte = data)
    pushad
    push ecx
    call free
    add esp, 4                                ;move to next link
    popad
    ;mov ecx,
    jmp %%loop_push
    
    %%free_last_link:
    dec ecx
    pushad
    push ecx
    call free
    add esp, 4                                
    popad

    %%check_leading_zeros_print:
    pop ebx
    cmp_jmp dword ebx, 0, je, %%check_leading_zeros_print
    cmp ebx, -1
    je %%the_number_is_zero

    push ebx
    push format_hexa_first          ;print the first number with %X to dispatch leading zero
    call printf
    add esp, 8

    %%loop_pop:
    pop eax             ;eax= new address of link
    cmp eax, -1
    je %%end
    push eax
    push format_hexa
    call printf
    add esp, 8
    jmp %%loop_pop

    %%the_number_is_zero:
    push dword 0
    push format_hexa_first
    call printf
    add esp, 8

    %%end:
    push println
    push format_string
    call printf
    add esp, 8
    popad
%endmacro

%macro before 0
    push ebp
    mov ebp,esp
%endmacro

%macro after 0
    mov esp,ebp
    pop ebp
%endmacro

%macro print_calc 0
    before
    push calc_print
    push format_string
    call printf
    add esp,8
    after
%endmacro

%macro sums_up 0
    %%start:
    mov eax, 0
    mov ebx, 0
    mov ecx, 0
    mov edx, 0
    mov eax, [operand1]
    mov bl, byte[eax]
    mov ecx, [operand2]
    mov dl, byte[ecx]
    add bl, [carry_flag]
    jc %%carry_check1           ; add carry fleg from prev addition between links and check if we got new one
    mov byte [carry_flag], 0
    add bl, dl
    jc %%carry_check2
    mov byte [carry_flag], 0
    mov eax, [sum_curr_address]
    mov byte [eax], bl
    mov esi, eax
    inc esi
    mov dword [esi], 0
    jmp %%end_of_sum

    %%carry_check1:
    mov byte [carry_flag], 1
    add bl, dl
    mov eax, [sum_curr_address]
    mov byte [eax], bl
    jmp %%end_of_sum

    %%carry_check2:
    mov byte [carry_flag], 1
    mov eax, [sum_curr_address]
    mov byte [eax], bl
    ;jmp %%end_of_sum

    %%end_of_sum:
    mov eax, [operand1]
    mov ebx, [operand2]
    inc eax
    inc ebx
    cmp_jmp dword [eax], 0, je, %%first_link_is_over
    cmp_jmp dword [ebx], 0, je, %%second_link_is_over
    ;both are not over
    mov eax, [eax]
    mov [operand1], eax             ;update operand 1 and 2 as their next address links
    mov ebx, [ebx]
    mov [operand2], ebx
    ;pushad
    push sizeOfLink
    call malloc                     ;allocate memory for new link
    add esp,4
    ;popad
    mov ebx, [sum_curr_address]     ;saving the last link that was modified
    inc ebx                         ;going to his nextLink section
    mov [ebx], eax                  ;inserting this curr link, the next address with the new allocated memory
    mov [sum_curr_address], eax
    jmp %%start

    %%first_link_is_over:
    mov esi, eax
    dec esi
    mov [First_link_end_address], esi           ;setting the end address of the first list to delete
    cmp_jmp dword [ebx], 0, je, %%both_are_over_and_same_lenght
    mov esi, ebx                                ; saves the adress of the next pointer
    dec esi                                     ;saves the address of the current link to be deleted
    mov [Second_link_end_address], esi          ;the stopping address of the second list
    mov ebx,[ebx]                               ;eax is the next link address of the second link (the longer one)
    mov dword [continue_address],ebx
    jmp %%copy_rest

    %%second_link_is_over:                      ; the first is not over 
    mov esi, ebx
    dec esi
    mov [Second_link_end_address], esi          ;setting the end address of the second list to delete

    mov esi, eax                                ; saves the adress of the next pointer
    dec esi                                     ;saves the address of the current link to be deleted
    mov [First_link_end_address], esi           ;the stopping address of the first list

    mov eax,[eax]                               ;eax is the next link address of the first link (the longer one)
    mov [continue_address],eax
    jmp %%copy_rest
    debug_label_102:
    %%copy_rest:
    mov eax, [continue_address]
    mov ebx, [sum_curr_address]                 ;saving the last link that was modified
    inc ebx                                     ;going to his nextLink section
    mov [ebx], eax                              ;inserting this curr link, the next address with the new allocated memory
    mov [sum_curr_address], eax
    cmp byte [carry_flag], 0                    ;no carry flag, just coping the continue of the new link from the longer one
    je %%finitoLacomedia
    
    %%loop_copy_rest:                           ;there is carryFlag
    mov byte [carry_flag], 1
    inc eax                                     ;go to address the nextLink section
    cmp_jmp dword [eax], 0, je, %%both_are_over ;the carryFlag is 1, so we need to add link
    mov ebx, 0
    mov edx, 0
    dec eax                                     ;move back to the data
    mov bl, byte[eax]               
    mov dl, 1
    add bl, dl
    mov byte [eax], bl                          ;update the data
    inc eax                                     ;move to the address
    mov eax, [eax]                              ;move to the next address
    mov [sum_curr_address], eax                 ;update the current address
    jc %%loop_copy_rest
    jmp %%finitoLacomedia


    %%both_are_over_and_same_lenght:            ;setting the address of the second list to be delete
    mov esi, ebx
    dec esi
    mov [Second_link_end_address], esi          ;setting the end address of the second list to delete
    mov byte [ended_together], 1

    %%both_are_over:
    cmp byte [carry_flag], 0
    je %%finitoLacomedia
    cmp_jmp byte [ended_together], 1 , je , %%after_adding
    mov ebx, 0
    mov edx, 0
    dec eax                                     ;move back to the data
    mov bl, byte[eax]               
    mov dl, 1
    add bl, dl
    mov byte [eax], bl                          ;update the data
    jnc %%finitoLacomedia

    %%after_adding:
    ;pushad
    push sizeOfLink
    call malloc                     ;allocate memory for new link
    add esp,4
    ;popad
    mov byte [eax], 1               ;data of the next link is 1
    mov ebx, [sum_curr_address]     ;saving the last link that was modified
    inc ebx                         ;going to his nextLink section
    mov [ebx], eax                  ;inserting this curr link, the next address with the new allocated memory
    mov [sum_curr_address], eax     ;eax is the adress of the next link
    inc eax
    mov dword [eax], 0              ;next address is 0= last link
    %%finitoLacomedia:
%endmacro    

%macro delete_lists 2
    pushad
    mov eax, %1
    mov ebx, %2
    %%delete_address_loop:
    cmp_jmp eax, ebx, je, %%end_of_deletion
    mov ecx, eax                    ;saves the address to be delete
    inc eax
    mov eax, [eax]
    pushad
    push ecx
    call free
    add esp, 4                                ;move to next link
    popad
    jmp %%delete_address_loop
    %%end_of_deletion:
    mov ecx, eax                   ;delete the last address
    pushad
    push ecx
    call free
    add esp, 4                                ;move to next link
    popad
    popad
%endmacro 

%macro delete_lists_till_0 0
    pushad
    mov eax, [address_to_delete]
                            
    %%delete_address_loop:
    mov ebx, eax
    inc ebx                         ;move to the nextLink address
    cmp_jmp dword [ebx], 0, je, %%end_of_deletion
    mov ecx, eax                    ;saves the address to be delete
    inc eax
    mov eax, [eax]
        pushad
        push ecx
        call free
        add esp, 4                                ;move to next link
        popad
    jmp %%delete_address_loop
    %%end_of_deletion:
    mov ecx, eax                   ;delete the last address
        pushad
        push ecx
        call free
        add esp, 4                                ;move to next link
        popad
    popad
%endmacro  

%macro duplicateList 0
    
    pushad
    %%dup_loop:
    push sizeOfLink
    call malloc                             ;allocate memory for new link
    add esp,4
    mov ebx, [curr_newLink]
    mov [ebx], eax                          ;put in the curr address the next

    mov ecx, [toduplicate]
    mov ecx, [ecx]                          ;go to the link in th address to dup
    mov edx, 0                              ;copy the data to the new link
    mov dl, byte [ecx]
    mov byte [eax], dl
    inc eax
    mov dword [eax], 0                            ; update the next address to be 0
    dec eax
    inc ecx
    ;mov ecx, [ecx]
    mov [toduplicate], ecx
    inc eax
    mov [curr_newLink], eax
    cmp_jmp dword [ecx], 0 , jne, %%dup_loop
    popad

%endmacro

%macro check_if_y_over200 0
    mov dword eax, [var_y]
    mov bl, byte [eax]
    cmp_jmp bl, 200, ja, print_error_Y_value
    inc eax
    cmp_jmp dword [eax], 0, jne, print_error_Y_value
    mov byte [value_of_y], bl
%endmacro

%macro count_1s 0
    mov eax, [curr_1s]
    mov dword ebx, 0
    mov bl, byte [eax]      ;bl holds the data of the link
    %%loop_1s:
    cmp_jmp byte bl, 0, je, %%end_of_count_1s
    shr ebx, 1
    jc %%add_1
    jmp %%loop_1s

    %%add_1:
    inc byte [count_num_of_1s]
    jmp %%loop_1s

    %%end_of_count_1s:
%endmacro

%macro print_debug 0
    pushad
    push return_value_is            ;print return_value_is
    push format_string
    call printf
    add esp, 8

    mov edx, myStack
    mov esi, [stack_index]
    dec esi
    shl esi, 2
    add edx, esi
    mov eax, [edx]                                  ;edx = myStack + stack_index
    push dword -1                                   ;pushing -1 as indicator 
    %%loop_push:                                    ;push to stack the addresses of links
    mov ecx, eax
    mov eax, 0
    mov al, byte[ecx]
    push eax
    inc ecx                                         ;inc to the address of the next link

    cmp_jmp dword [ecx], 0, je, %%check_leading_zeros_print        ;if the adress of the next link equal 0 -> finish

    mov eax, [ecx]
    dec ecx                                         ;dec to point the start of the link (the 1 byte = data)
    jmp %%loop_push
    
    %%check_leading_zeros_print:
    pop ebx
    cmp_jmp dword ebx, 0, je, %%check_leading_zeros_print
    cmp ebx, -1
    je %%the_number_is_zero

    push ebx
    push format_hexa_first          ;print the first number with %X to dispatch leading zero
    call printf
    add esp, 8

    %%loop_pop:
    pop eax             ;eax= new address of link
    cmp eax, -1
    je %%end
    push eax
    push format_hexa
    call printf
    add esp, 8
    jmp %%loop_pop

    %%the_number_is_zero:
    push dword 0
    push format_hexa_first
    call printf
    add esp, 8

    %%end:
    push println            ;print \n
    push format_string
    call printf
    add esp, 8
    popad
     
%endmacro

main:
        cmp_jmp  dword [esp+4], 1, je, Debug_off     ;just the name of main(function)
        ;mov edx, [esp+8]                            ; get argv array
        ;add dword edx, 4
        ;mov edx, [edx]                              ; get argv[1]
        ;cmp_jmp byte [edx], '-', je, Debug_off      ; check if '-d' argument
        ;cmp_jmp byte [edx+1], 'd', je, Debug_off
        mov dword [flag_debug],1

        Debug_off:
        before  ;1
        pushad  ;1
        call my_calc

        ;popad
        ;after

        mov dword [flag_debug],0
        mov dword eax, [number_of_operations]
        push eax
        push format_hexa_first 
        call printf ;print the number of operations
        add esp,8

        push println
        push format_string
        call printf
        add esp, 8
        
        ;mov eax, 1              ; SYS_exit
        ;mov ebx, 0
        ;int     0x80 
        
    popad   ;1
    after   ;1
    ;pop ebp
    ret

    my_calc:
        ;before  ;2
        ;pushad  ;2
        print_calc
        push dword[stdin]       ;fgets need 3 param
        push dword max_input    ;max len
        push dword buffer       ;input buffer
        call fgets
        add esp, 12             ;remove 3 push from stack
        
        cmp_jmp byte[buffer], 'q', je, quit
        cmp_jmp byte[buffer], '+', je, plus
        cmp_jmp byte[buffer], 'p', je, pop_and_print
        cmp_jmp byte[buffer], 'd', je, duplicate
        cmp_jmp byte[buffer], '^', je, positive_power
        cmp_jmp byte[buffer], 'v', je, negative_power
        cmp_jmp byte[buffer], 'n', je, number_of_1s
        ;cmp_jmp byte[buffer], 'sr', je, square_root
        jmp number

    number_of_1s:
        inc dword [number_of_operations]
        cmp_jmp dword [stack_index], 0, je, print_insufficient_error
        
        mov byte [flag_1s], 1
        ; initialize starting_1s and curr_1s
        mov edx, myStack        ;initialize the starting point of the current linklist
        mov esi, [stack_index]  ;esi now holds the num of operands
        dec esi
        shl esi, 2              ;multiply by 4
        add edx, esi            ;holds the current position of the checked number
        mov [temp], edx         ;saving in temp the address of top of the stack
        mov edx, [edx]          ;first link of top of the stack
        mov [starting_1s], edx
        mov [curr_1s], edx

        ;creating the new sum link, link of 0
        ;pushad               
        push sizeOfLink
        call malloc             ;allocate memory for new link
        add esp,4
        mov esi, [temp]
        mov [esi], eax          ;putting the new malloc in the top of the stack
        mov byte[eax], 0        ;setting the sum data as 0
        inc eax
        mov dword [eax], 0      ;setting his nextLink as 0
        loop_operation_1s:
        mov byte [count_num_of_1s], 0
        count_1s                ;the data is 8 at most
        ;pushad                 ;creating the new sum link
        push sizeOfLink
        call malloc             ;allocate memory for new link
        add esp,4
        mov dword ebx, 0
        mov bl,[count_num_of_1s]    
        mov byte [eax], bl      ;saves the num of 1s in the data of the new link
        inc eax
        mov dword [eax], 0      ;setting his nextLink as 0
        inc dword [stack_index] ;adding 1 list to the stack

        mov edx, myStack        ;initialize the starting point of the current linklist
        mov esi, [stack_index]  ;esi now holds the num of operands
        dec esi
        shl esi, 2              ;multiply by 4
        add edx, esi            ;holds the current position of the checked number
        dec eax
        mov [edx], eax          ;putting the new malloc in top of the stack

        jmp operation_1s_plus
        operation_1s_after_plus:
        mov eax, [curr_1s]
        inc eax
        cmp_jmp dword [eax], 0 , je, end_operation_1s
        mov eax, [eax]          ;there is nextLink, so eax now holds his address
        mov [curr_1s], eax
        jmp loop_operation_1s

        end_operation_1s:
        mov byte [count_num_of_1s], 0
        mov byte [flag_1s], 0
        delete_lists [starting_1s], [curr_1s]
        cmp_jmp dword [flag_debug], 0, je, my_calc
        print_debug
        jmp my_calc

    negative_power:
        inc dword [number_of_operations]
        cmp_jmp dword [stack_index], 0, je, print_insufficient_error
        cmp_jmp dword [stack_index], 1, je, print_insufficient_error
        mov byte [flag_np], 1
        jmp power_init
        
    positive_power:
        inc dword [number_of_operations]
        cmp_jmp dword [stack_index], 0, je, print_insufficient_error
        cmp_jmp dword [stack_index], 1, je, print_insufficient_error
        mov byte [flag_pp], 1
        jmp power_init
    
    power_init:
        mov edx, myStack
        mov esi, [stack_index]
        dec esi
        shl esi, 2
        add edx, esi 
        mov ecx, [edx]
        mov dword [var_x], ecx              ;var_x holds the address of the first link of the list in the top of the stack
        sub dword edx, 4
        mov ecx, [edx]
        mov dword [var_y], ecx              ;var_y holds the address of the first link of the second list from the top of the stack
        check_if_y_over200
        mov ecx, [var_x]
        mov dword [edx], ecx                ;clear the address of y in the stack and put x in it
        add dword edx, 4
        mov dword [edx], 0                  ;clear the address of x in the stack (top of the stack)
        sub dword [stack_index], 1

        cmp_jmp dword [flag_np], 1, je, continue_negative_power

    continue_positive_power:

        loop_pp:
        cmp_jmp byte [value_of_y], 0, je, end_pp
        jmp duplicate
        pp_after_duplicate:
        dec dword [number_of_operations]
        jmp plus
        pp_after_plus:
        dec dword [number_of_operations]
        sub byte [value_of_y], 1
        jmp loop_pp

        end_pp:
        delete_lists [var_y], [var_y]
        mov byte [flag_pp], 0
        cmp_jmp dword [flag_debug], 0, je, my_calc
        print_debug
        jmp my_calc


    continue_negative_power:
        
        loop_np:                     ;outer loop - on the value of y - number of times to divide x and go over the list
        ;mov dword [prev_np], 0
        mov eax, [var_x]
        mov dword [curr_np], eax
        ;mov dword [prev_np], [eax]
        cmp_jmp byte [value_of_y], 0, je, end_np
        sub byte [value_of_y], 1

        mov dword ebx, 0
        mov bl, byte [eax]          ;bl holds the data of the first link
        shr bl, 1
        mov byte [eax], bl          ;update the value after the division
        inc eax

        inner_loop:
        cmp_jmp dword [eax], 0, je, loop_np         ;finish to go over x 
        mov edx, [eax]
        mov dword [curr_np], edx
        mov ecx, eax
        dec ecx
        mov dword [prev_np], ecx
        mov eax, [eax]              ;eax now is the curr data
        mov dword ebx, 0
        mov bl, byte [eax]          ;bl holds the data of the first link
        shr bl, 1
        mov byte [eax], bl          ;update the value after the division
        inc eax
        jnc inner_loop
        ;carry_flag = 1
        mov dword ecx, [prev_np]
        add byte [ecx], 128
        jmp inner_loop
        
        end_np:
        delete_lists [var_y], [var_y]
        mov byte [flag_np], 0
        mov byte [value_of_y], 0
        mov dword [prev_np], 0
        mov dword [curr_np], 0
        cmp_jmp dword [flag_debug], 0, je, my_calc
        print_debug
        jmp my_calc

    duplicate:
        inc dword [number_of_operations]
        cmp_jmp dword [stack_index], sizeOfStack, je, print_overflow_error  ; check if index 5 on stack
        cmp_jmp dword [stack_index], 0, je, print_insufficient_error
        mov edx, myStack
        mov esi, [stack_index]
        shl esi, 2
        add edx, esi                                                        ;edx now holds the first empty place in the stack
        mov dword [curr_newLink], edx
        sub dword edx, 4
        mov dword [toduplicate], edx
        duplicateList
        inc dword [stack_index]
        cmp_jmp byte [flag_pp], 1, je, pp_after_duplicate
        cmp_jmp dword [flag_debug], 0, je, my_calc
        print_debug
        jmp my_calc

    quit:
        ;delete the rest of the stack
        loop_delete:
        cmp_jmp dword [stack_index], 0, je, end_delete
        mov edx, myStack
        mov esi, [stack_index]
        dec esi
        shl esi, 2
        add edx, esi                                                        ;edx now holds the first empty place in the stack
        mov ecx, edx                    ;saves the address of the stack to clear
        mov edx, [edx]  
        mov dword [ecx], 0              ;clears the stack
        mov dword [address_to_delete], edx
        delete_lists_till_0
        dec dword [stack_index]
        jmp loop_delete

        end_delete:
        ;popad   ;2
        ;after   ;2
        ret


    pop_and_print:
        inc dword [number_of_operations]
        cmp_jmp dword [stack_index], 0, je, print_insufficient_error
        loop_print_link 
        mov edx, myStack
        mov esi, [stack_index]
        shl esi, 2
        add edx, esi
        mov dword [edx], 0          ;pop, clean the address from the stack
        dec dword [stack_index]     ;dec the stack index
        jmp my_calc


    number:
        cmp_jmp dword [stack_index], sizeOfStack, je, print_overflow_error; check if index 5 on stack
        mov edx, myStack        ;initialize the starting point of the current linklist
        mov esi, [stack_index]  ;esi now holds the num of operands
        shl esi, 2              ;multiply by 4
        add edx, esi            ;add the identation to the address
        mov [nextLink], edx     ;update nextLink address
    createLink:
        mov ebx, 0   ;index on the input buffer
        mov ecx, 0   ;flag for (odd = 1) or (even = 0)
        mov edx, 0

        cmp_jmp byte[buffer], '0', je, check_leading_zeros
        jmp count_digits

    check_leading_zeros:
        inc ebx
        cmp_jmp byte[buffer + ebx], 10, je, input_is_zero          ;check if '/n'
        cmp_jmp byte[buffer + ebx], '0', je, check_leading_zeros
        mov edx, ebx    ;save num of zeros
        jmp count_digits

    count_digits:
        change_even_flag ecx
        inc ebx
        cmp_jmp byte[buffer + ebx], 10, je, end_of_input          ;check if '/n'
        jmp count_digits

    end_of_input:
        mov eax, ebx            ;save total digits
        dec ebx                 ;dec the num of digit for move the index from the /n
        sub eax, edx            ;the substraction goes into eax

        cmp_jmp ecx, 0, je, create_links_loop
        inc eax         ;now eax is even

    create_links_loop:
    
        cmp_jmp eax, 2, je, final_link
        
        ;mov edx, ebx
        ;dec edx
        ;create_link [buffer + ebx], [buffer + edx]  ; create new link
        mov edx, buffer    ;puts in edx the buffer index
        add edx, ebx            ;adds ebx to edx - the index identation
        mov esi, ebx            ;saving ebx(the indentation) in esi
        mov edi, edx

        mov bl, byte[edx]

        dec edi                 ;takes the next char
        mov dl, byte[edi]

        create_link bl, dl

        mov ebx, esi            ;returns the esi value to ebx

        dec eax     ; dec the digits counter
        dec eax     ; dec the digits counter
        dec ebx     ; dec the index buffer
        dec ebx     ; dec the index buffer
        jmp create_links_loop

    input_is_zero:
        create_link '0', '0'
        jmp end_final_link

    final_link:
        cmp ecx, 1      ;odd
        je label

        ;mov edx, ebx    ;num of digit in ebx
        ;dec edx
        mov edx, buffer    ;puts in edx the buffer index
        add edx, ebx            ;adds ebx to edx - the index identation
        mov ebx, edx            ;copy to ebx
        dec edx                 ;takes the next char
        mov dl, byte[edx]
        mov bl, byte[ebx]

        ;create_link [buffer + ebx], [buffer + edx]
        create_link bl, dl
        ;create_link '1', '2'
        jmp end_final_link
        
        label:
        ;create_link byte[buffer + ebx], '0'  
        create_link [buffer + ebx], '0'  

    end_final_link:
        inc dword [stack_index]
        cmp_jmp dword [flag_debug], 0, je, my_calc
        print_debug
        jmp my_calc

    plus:
        inc dword [number_of_operations]
        cmp_jmp dword [stack_index], 0, je, print_insufficient_error
        cmp_jmp dword [stack_index], 1, je, print_insufficient_error

        operation_1s_plus:
        pushad
        push sizeOfLink
        call malloc     ;allocate memory for new link
        add esp,4
        mov [sum_curr_address], eax
        mov [sum_starting_address], eax
        popad
        
        mov edx, myStack        ;initialize the starting point of the current linklist
        mov esi, [stack_index]  ;esi now holds the num of operands
        dec esi
        shl esi, 2              ;multiply by 4
        add edx, esi            ;top of the stack = edx
        mov esi, edx            ;top of the stack = esi
        mov edx, [edx]  
        mov [operand1], edx     ;operand1 is holding the address of the last list that was pushed (the first link of it) top of the stack
        mov [First_link_start_address], edx
        sub esi, 4
        mov edx, [esi]
        mov [operand2], edx     ;operand1 is holding the address of the 1 before the last link
        mov [Second_link_start_address], edx
        
        sum_loop:
        pushad
        sums_up 
        popad 
        mov byte [carry_flag], 0
        delete_lists [First_link_start_address], [First_link_end_address]
        delete_lists [Second_link_start_address], [Second_link_end_address]
        mov eax, [sum_starting_address]
        mov [esi], eax  ;update the address of the new link in the stack
        add esi, 4
        mov dword [esi], 0
        dec dword [stack_index]
        mov dword [First_link_start_address], 0
        mov dword [Second_link_start_address], 0
        mov dword [First_link_end_address], 0
        mov dword [Second_link_end_address], 0
        mov byte [ended_together],0
        cmp_jmp byte [flag_pp], 1, je, pp_after_plus
        cmp_jmp byte [flag_1s], 1, je, operation_1s_after_plus
        cmp_jmp dword [flag_debug], 0, je, my_calc
        print_debug
        jmp my_calc

    print_insufficient_error:
        push insufficient_error
        push format_string 
        call printf         ;prints error
        add esp,8
        jmp my_calc

    print_overflow_error:
        push overflow_error
        push format_string 
        call printf         ;prints error
        add esp,8
        jmp my_calc    

    print_error_Y_value:
        push Y_value_error
        push format_string 
        call printf         ;prints error
        add esp,8
        mov byte [flag_pp], 0
        mov byte [flag_np], 0
        jmp my_calc


    


 




