include IO.asm

.286
.model huge
.stack 100h
.data
	PENCOLOR db 0

.code
start:
	mov ax, @data
	modv ds, ax
;;this is where the api goes

;; bool AL SETMODE(int AH)
;; permits user to set to some mode; if not work, autoreset to standard text mode,
;; return false

;; change screen mode 
	;; mov ah 0
;; this is the mode it will change to
setmode:	
	mov al [ah]
	mov ah 0
	int 10
	ret
;; bool AL SETPENCOLOR(int COLOR)
;; By providing the color number as a parameter the API will remember that you are
;; currently using that colored pencil. The function returns false if it encounters
;; a problem. You will need a variable in memory to store this information, call it
;; PENCOLOR.
setpencolor:
	push bp
	mov bp, sp

	call getInt 		;which stores stuff in al
	mov PENCOLOR al
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
	ret
;;bool AL DRAWLINE(int X, int Y, int X2, int Y2)
;; Using the pen color and the mode you already selected this function draws a
;; general line from the two coordinates in any direction. This is a general purpose
;; line drawing function. It returns false if there was a problem. Note that this
;; function uses DRAWPIXEL to actually write on the screen buffer.
drawline:	

	pop di 			; cleanup etc
	mov sp, bp

	pop bp
	ret
	
END start