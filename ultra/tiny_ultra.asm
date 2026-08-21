; ============================================================================
; Tiny Dragon: Ultra
;
; A further byte-golfed derivative of the original 185-byte Tiny Dragon.
; Same behaviour, same bugs-already-fixed, same no-legality-checking scope
; -- just smaller.
;
; The one golf trick applied: BIOS's INT 10h AH=0 (set video mode) clears
; the *entire* screen to blanks with attribute 07h as a side effect. The
; original wrote that attribute byte itself for all 64 cells (4 bytes of
; code, but exercised on every render). Since the attribute is already
; 07h immediately after the mode-set and this program never changes video
; modes again, that explicit write is redundant -- we can just skip past
; the attribute byte instead of writing it, dropping 4 bytes of code.
;
;   Original : 185 bytes
;   Ultra    : 181 bytes
;
; Caveat: this relies on the standard BIOS/DOSBox behavior of clearing the
; screen to attribute 07h on a mode-set. That's a very standard, well
; established behavior, but it's still an environment assumption rather
; than something the program guarantees itself -- verify colors look
; right in your actual target (DOSBox/js-dos) after assembling.
;
; Assemble:  nasm -f bin tiny_ultra.asm -o tiny_ultra.com
; ============================================================================
org 100h

start:
    mov ax, 0003h
    int 10h                 ; sets 80x25 text mode AND clears the screen
                             ; to blanks with attribute 07h -- we rely on
                             ; that below instead of writing attributes
    push 0b800h
    pop es

loop_turn:
    mov si, board
    xor di, di
    mov dl, 8
rows:
    mov cx, 8
cols:
    lodsb
    stosb                    ; write the char byte
    inc di                   ; skip the attribute byte (already 07h)
    loop cols
    add di, 144              ; skip to the next text-mode screen row
    dec dl
    jnz rows

    call read_sq
    mov si, ax
    call read_sq
    mov di, ax

    mov al, '.'
    xchg al, [si]
    xchg al, [di]

    mov si, board
ai_scan:
    mov al, [si]
    cmp al, 'a'
    jb  ai_next
    mov di, si
    add di, 8
    cmp di, board+64
    jae ai_next
    cmp byte [di], '.'
    jne ai_next
    mov [di], al
    mov byte [si], '.'
    jmp loop_turn
ai_next:
    inc si
    cmp si, board+64
    jne ai_scan
    jmp loop_turn

read_sq:
    xor ah, ah
    int 16h
    sub al, 'a'
    mov bl, al
    xor ah, ah
    int 16h
    neg al
    add al, 038h
    mov cl, 3
    shl al, cl
    add al, bl
    xor ah, ah
    add ax, board
    ret

board: db "rnbqkbnr", "pppppppp", "................................", "PPPPPPPP", "RNBQKBNR"
