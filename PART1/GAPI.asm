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

makesmile:
    push bp
    mov bp, sp
    
    mov cx, [bp+6]
    mov dx, [bp+4]
    
    add dx, 5
    push cx
    push dx
    call drawpixel
    
    add cx, 2
    push cx
    push dx
    call drawpixel
    
    add dx, 3
    push cx
    push dx
    call drawpixel
    
    dec cx
    push cx
    push dx
    call drawpixel
    
    dec cx
    push cx
    push dx
    call drawpixel
    
    dec cx
    dec dx
    push cx
    push dx
    call drawpixel
    
    add cx, 4
    push cx
    push dx
    call drawpixel
    
    mov sp, bp
    pop bp
    ret

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