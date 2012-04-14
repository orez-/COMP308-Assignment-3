.286
.model huge
.stack 100h
.data
	PENCOLOR db 1100b

.data?
    buffer db 100 DUP(?)

.code
start:
	mov ax, @data
	mov ds, ax
	
	push 101h
	call setmode
	add sp, 2
	;mov ah, 10
	;push 1
	;push 0
	;call drawpixel
	;push 2
	;push 0
	;call drawpixel
	;push 4
	;push 0
	;call drawpixel
	;push 8
	;push 0
	;call drawpixel
	;push 16
	;push 0
	;call drawpixel
	;push 32
	;push 0
	;call drawpixel
	;push 64
	;push 0
	;call drawpixel
	;push 128
	;push 0
	;call drawpixel
	;push 256
	;push 0
	;call drawpixel
	
	mov al, 1110b
    call setpencolor
	
    push 10
	push 30
	push 40
	push 35
	call drawline
	add sp, 8
	
	mov al, 1100b
	call setpencolor
	
	push 50
	push 100
	push 30
	push 200
	call drawline
	add sp, 8
	
	;mov al, 1100b
	;call setpencolor
	;push 10
	;push 30
	;call drawpixel
	;push 40
	;push 35
	;call drawpixel
	;add bp, 4
	
.end:
    mov ah, 4ch
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



;;this is where the api goes

;; bool AL SETMODE(int AH)
;; permits user to set to some mode; if not work, autoreset to standard text mode,
;; return false
setmode:
    push bp
    mov bp, sp
    push bx
    
	mov ax, 4F02h
	mov bx, [bp+4]
	int 10h
	
	pop bx
	mov sp, bp
	pop bp
	ret
;; bool AL SETPENCOLOR(int COLOR)
;; By providing the color number as a parameter the API will remember that you are
;; currently using that colored pencil. The function returns false if it encounters
;; a problem. You will need a variable in memory to store this information, call it
;; PENCOLOR.
setpencolor:
	push bp
	mov bp, sp
	
	;call getInt 		;which stores stuff in al
	mov PENCOLOR, al
	;; cmp blah
	;jne blah
	;mov al 0
	;ret
	
	pop bp
	ret
;;bool AL DRAWPIXEL(int X, int Y)
;; Using the pen color and mode you already selected set pixel at X, Y to color and
;; returns false if there was a problem. Important: this function does not use the
;; BIOS but accesses the memory directly.
drawpixel:
    push bp
    mov bp, sp
    push di
    push ax
    push cx
    push dx
    
    mov bh, 0
    mov al, PENCOLOR
    mov cx, [bp+6]
    mov dx, [bp+4]
    mov ah, 0Ch  ; draw pixel
    int 10h
    
    pop dx
    pop cx
    pop ax
    pop di
    mov sp, bp
    pop bp
	ret
;;bool AL DRAWLINE(int X, int Y, int X2, int Y2)
;; Using the pen color and the mode you already selected this function draws a
;; general line from the two coordinates in any direction. This is a general purpose
;; line drawing function. It returns false if there was a problem. Note that this
;; function uses DRAWPIXEL to actually write on the screen buffer.
drawline:
    push bp
    mov bp, sp
    
    sub sp, 6   ; make space
    
    push ax
    push bx
    push cx
    push dx
    
    mov ax, [bp+6]  ; x1
    mov bx, [bp+10] ; x0
    sub ax, bx      ; delta x
    mov [bp], ax    ; delta x: [bp]
    
    mov ax, [bp+4]  ; y1
    mov bx, [bp+8]  ; y0
    sub ax, bx      ; delta y
    mov [bp-2], ax   ; delta y: [bp-2]
    
    mov ax, [bp]    ; ax = delta x
    cmp ax, 0
    jle .dl_xpos    ; if x0 < x1
        mov cx, 1   ;   sx =  1
        jmp .dl_y   ; else
    .dl_xpos:
    mov cx, -1      ;   sx = -1
    neg ax
    mov [bp], ax
    
    .dl_y:
    mov ax, [bp-2]
    cmp ax, 0
    jle .dl_ypos    ; if y0 < y1
        mov dx, 1   ;   sy =  1
        neg ax      ;   negate and rewrite
        mov [bp-2], ax
        jmp .dl_next; else
    .dl_ypos:
    mov dx, -1      ;   sy = -1
    
    .dl_next:
    mov ax, [ bp ]  ; ax = delta x
    add ax, [bp-2]  ; ax -= delta y
    mov [bp-4], ax  ; error: [bp-4]
    
    .dl_loop:
        push [bp+10]
        push [bp+8]
        call drawpixel
        add sp, 4    ; pop dem two (cleanup)
        
        mov ax, [bp+10] ; x0
        cmp [bp+6], ax  ; x1 == x0
        je .dl_break
        jmp .dl_nope    ; jne
            mov ax, [bp+8]  ; y0
            cmp [bp+4], ax  ; y1 == y0
            je .dl_break
        .dl_nope:
        
        mov ax, [bp-4]  ; e2 = err
        shl ax, 1       ; e2 = err*2
        mov bx, [bp-2]  ; dy
        cmp ax, bx      ; if e2 > -dy
        jle dl_skipy
            add [bp-4], bx  ; err -= dy
            add [bp+10], cx ; x0 += sx
        dl_skipy:
        mov bx, [ bp ]  ; dx
        cmp ax, bx      ; if e2 < dx
        jge dl_skipx
            add [bp-4], bx  ; err += dx
            add [bp+8], dx  ; y0 += sy
        dl_skipx:
    jmp .dl_loop
    .dl_break:
    
	
    pop dx
    pop cx
    pop bx
    pop ax
	mov sp, bp
	pop bp
	ret
	
END start