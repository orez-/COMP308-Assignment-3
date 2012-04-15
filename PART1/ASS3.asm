.286
.model huge
.stack 100h
.data
    PENCOLOR db 1100b
    winA dw 0A000h
    xRes dw 0
    yRes dw 0
    bbp  dw 2
    gran dw 0
    fnptr dw 0
    
    xcords db 0, 0, -50, -50, -50, -25,   0,  25,  50, 50, 50, 25,  0, -25
    ycords db 0, 0,  25,   0, -25, -50, -50, -50, -25,  0, 25, 50, 50,  50
    ;xcords db 50,  50,  50,  50,  50,  50,  50,  50, 50, 50, 50, 50,  50
    ;ycords db 50,  50,  50,  50,  50,  50,  50,  50, 50, 50, 50, 50,  50
    ;xcords db 1,  2,  3,  4,  5,  6,  7,  8, 9, 10, 11, 12,  13
    ;ycords db 0,  0,  0,  0,  0,  0,  0,  0, 0, 0, 0, 0,  0

.data?
    buffer db 256 DUP(?)

.code
start:
    mov ax, @data
    mov ds, ax
    
    call GetInt ; x
    xor ah, ah
    push ax ; parameter to draw_flower
    
    call GetInt ; y
    xor ah, ah
    push ax ; parameter to draw_flower
    
    push 101h
    call setmode
    add sp, 2
    
    call draw_flower
    add sp, 4   ; sent in above
    
.end:
    mov ah, 4ch
    int 21h

draw_flower:
    push bp
    mov bp, sp
    
    push ax
    push bx
    push cx
    push dx
    
    
    
    mov ax, 1
    .flower:
        inc ax  ; ax++
        
        mov bx, ax
        push ax ; parameter
        call setpencolor
        add sp, 2   ; eat parameter
        mov ax, bx
        
        mov bx, OFFSET xcords   ; get the start of the list
        add bx, ax              ; xcords[ax]
        xor ch, ch
        mov cl, [bx]            ; cx = xcords[ax]
        add cx, [bp+6]          ; cx += x
        
        mov bx, OFFSET ycords
        add bx, ax
        xor dh, dh
        mov dl, [bx]
        add dx, [bp+4]
        
        
        push dx
        call PrintInt
        add sp, 2
        
        
        push [bp+6]
        push [bp+4]
        push cx
        push dx
        ;call drawline
        add sp, 8
        cmp ax, 0Dh ; done!
    jl .flower
    
    pop dx
    pop cx
    pop bx
    pop ax
    
    mov sp, bp
    pop bp
    ret

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
    
    mov sp, bp
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
    mov sp, bp
    pop bp
    ret

; START ASSIGNMENT 2 CODE

GetInt:
    push bp
    mov bp, sp
    push cx
    
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
    
    pop cx
    mov sp, bp
    pop bp
    ret

PrintInt:
    push bp
    mov bp, sp
    
    sub sp, 6 ; make room for your output string
    push di   ; remember the old di
    push ax
    push bx
    push cx
    push dx
    
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
    
    push 13     ; print a carriage return
    call putch
    add sp, 2
    push 10     ; print a newline
    call putch
    add sp, 2
    
    
    pop ds      ; set it back
    
    pop dx
    pop cx
    pop bx
    pop ax
    pop di      ; cleanup etc
    mov sp, bp
    
    pop bp
    ret

;;this is where the api goes

getmode:
    push bp
    mov bp, sp
    push ax
    push di
    push dx
    
    mov ax, ds
    mov es, ax  ; why!?!
    
    mov ax, 4F03h
    int 10h ; get bx????
    
    mov ax, 4F01h
    mov cx, bx ; 101h
    mov di, OFFSET buffer
    int 10h     ; get SVGA mode info
    
    mov ax, [di+8h ]
    mov winA, ax
    xor ax, ax  ; zero it
    mov al, [di+19h]  ; bits per pixel
    shr ax, 3   ; /8 for bytes
    
    mov bbp , ax
    mov ax, [di+12h]
    mov xRes, ax
    mov ax, [di+14h]
    mov yRes, ax
    mov ax, [di+4h ]  ; granularity(?)
    shl ax, 10        ; *1024
    mov gran, ax
    mov dx, [di+0Ch]
    mov ax, [di+0Eh]
    mov WORD PTR fnptr, dx
    mov WORD PTR fnptr+2, ax
    
    pop dx
    pop di
    pop ax
    mov sp, bp
    pop bp
    ret

;; bool AL SETMODE(int AH)
;; permits user to set to some mode; if not work, autoreset to standard text mode,
;; return false
setmode:
    push bp
    mov bp, sp
    push bx
    push ax
    
    mov ax, 4F02h
    mov bx, [bp+4]
    int 10h
    
    call getmode
    
    pop ax
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
    
    mov ax, [bp+4]      ; get int COLOR
    mov PENCOLOR, al    ; set PENCOLOR to that variable
    mov ax, 1           ; return true: no errors!
    
    mov sp, bp
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
    push si
    push cx
    push dx
    push bx
    
    mov ax, [bp+6]  ; ax = x
    mul bbp         ; ax *= bits/pixel
    mov si, ax      ; si = ax
    
    mov ax, xRes    ; ax = width
    mul bbp         ; ax *= bits/pixel  (guaranteed 16-bit)
    mov bx, [bp+4]
    mul bx          ; ax *= y
    add ax, si      ; ax += si
    adc dx, 0       ; result from previous mult: if overflow, put in dx
    
    mov cx, gran
    test cx, cx ; if it's zero (some modes don't set it)
    jz .dp_1    ; certainly don't divide by it!
        div cx
        xchg ax, dx ; remainder in ax, result in dx
    .dp_1:
    mov si, ax
    
    mov ax, 4F05h   ; window control
    xor bx, bx
    call [DWORD PTR fnptr] ; magic
    
    mov es, winA
    
    mov ah, 0
    mov al, PENCOLOR
    mov BYTE PTR es:[si], al    ; draw the pixel
    mov ax, 1
    
    pop bx
    pop dx
    pop cx
    pop si
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
        jne .dl_nope
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