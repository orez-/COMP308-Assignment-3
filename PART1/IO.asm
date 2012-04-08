.286
.model huge
.stack 100h
.data
    sprompt db "Enter a positive integer: ",0
    
.data?
    buffer db 100 DUP(?)
.code
start:
    mov ax, @data
    mov ds, ax
    
    mov ax, OFFSET sprompt  ; prepare to write the string
    push ax                 ; ax is the argument
    call puts               ; to puts
    add sp, 2               ; pop without putting it anywhere
    
    mov ax, OFFSET buffer
    push ax
    call GetInt ; get your integer number
    add sp, 2
    
    xor ah, ah  ; set ah to 0 (quickly, apparently)
    push ax     ; add ah (0) : al (our int) to the stack to be read by PrintInt later
    mov cl, al  ; set cl as our counter
    
    .loop_as:
        cmp cl, 0   ; if you have counted down to 0
        je .end_as  ; end
        push 'A'    ; print an A
        call putch
        add sp, 2
        dec cl      ; countdown
        jmp .loop_as
    .end_as:
    
    push 13     ; print a carriage return
    call putch
    add sp, 2
    push 10     ; print a newline
    call putch
    add sp, 2
    
    call PrintInt   ; print the number (which we loaded onto the stack a while ago)
    add sp, 2
    
.end:
    mov ah, 4ch     ; exit program
    int 21h

getche:
    mov ah, 1       ; move 'read char from stdin' to ah
    int 21h         ; do ah, result in al
    ret

putch:
    push bp         ; put bp on the stack
    mov bp, sp      ; put stackpointer on base pointer
    
    mov dx, [bp+4]  ; put the item two-up on the stack in dx, for use in the interupt
    ; in 32bit it's 2 to look up one, so +4 is two up
    mov ah, 6       ; 6 = console output
    int 21h
    
    pop bp          ; put bp back in place
    ret

gets:
    push bp         ; store the base pointer
    mov bp, sp      ; put stackpointer on base pointer
    
    mov bx, [bp+4]  ; store the item two-up on the stack in bx
    mov cx, 0       ; length of the string
    .gets_char:     ; label
        call getche     ; get a character
        cmp al, 13      ; if that character is enter
        je .gets_end    ; jump to the end
        mov [bx], al    ; otherwise add that character to the stack
        inc bx          ; enlarge the stack
        inc cx          ; string is one longer
    jmp .gets_char      ; loop
    
    .gets_end:
    mov BYTE PTR [bx], 13   ; newline
    mov BYTE PTR [bx+1], 10 ; carriage return
    mov BYTE PTR [bx+2], 0  ; null-terminator
    add bx, 2               ; note the two new characters
    add cx, 2               ; length of the string up, since \r\n
    mov ax, cx              ; return ax as the length of the string
    
    pop bp
    ret

puts:
    push bp
    mov bp, sp
    
    mov bx, [bp+4]      ; get input from stack
    
    .puts_char:
        mov al, [bx]        ; get the character at bx
        cmp al, 0           ; if you found a null character
            je .puts_end    ; you have exhausted the string
        mov ah, 0           ; truncate the word
        push ax             ; push the byte to be read by putch
        call putch          ; put the character
        add sp, 2           ; advance the stack pointer
        inc bx              ; next character
    jmp .puts_char      ; loop
    
    .puts_end:
    pop bp
    ret

; START ASSIGNMENT 2 CODE

GetInt:
    push bp
    mov bp, sp
    
    xor cx, cx  ; Where we're going to be keeping our integer until the very end
    mov bl, 10  ; humans tend to count in base 10
    .gint_loop: ; pull in all the numbers
        call getche ; get the next character on the terminal
        cmp al, 13  ; read the last character (carriage return)
            je .gint_brk    ; end read
        xor ah,ah   ; clear the top bits
        sub al,'0'  ; bottom bits are a digit
        mov dx,ax   ; hold the read character in dx for a second
        mov ax,cx   ; allow cx (our sum) to have math done to it
        mul bl      ; multiply our sum by 10, put the result in ax
        add ax,dx   ; take your summed value and add it to your digit
        mov cx,ax   ; but ax is getting written to next pass so get him out of the way
    jmp .gint_loop  ; loop
    
    .gint_brk:
    mov al, cl  ; except don't leave him as the last character read
    
    mov sp, bp
    pop bp
    ret

PrintInt:
    push bp
    mov bp, sp
    
    sub sp, 6 ; make room for your output string
    push di   ; remember the old di
    
    mov ax, [bp+4]
    lea di, [bp-1]    ; offset to end of buffer
    mov bx, 10        ; divide by 10 for human-readable integers
    
    mov BYTE PTR ss:[di], 0 ; null character at end
    
    .pr_int:      ; essentially this loop adds characters to the string backwards
                  ; until there are no more integers to add
        xor dx, dx    ; ensure dx will not mess up the division (clear it)
        div bx        ; divide dx:ax by ten, quotient in ax, remainder in dx
        dec di        ; move back a character
        add dl, '0'   ; make it the correct character (not int)
        mov BYTE PTR ss:[di], dl  ; add to string
        cmp ax, 0     ; if we have not reached the end
    jne .pr_int   ; go again
    
    push ds     ; store the data segment
    mov ax, ss
    mov ds, ax
    push di
    call puts   ; print the string
    add sp, 2
    pop ds      ; set it back
    
    pop di      ; cleanup etc
    mov sp, bp
    
    pop bp
    ret

END start
