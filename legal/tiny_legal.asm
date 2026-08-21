; ============================================================================
; Tiny Dragon: Legal
;
; A derivative of Tiny Dragon that adds real piece-movement legality
; checking for the human (White) player: correct move shapes for
; P/N/B/R/Q/K, blocked-path detection for sliding pieces, and rejection of
; self-capture. An illegal move is simply ignored (board re-renders, the
; AI does not get a reply turn, you're prompted again).
;
; Deliberately NOT implemented (same honest scope as the original):
;   - check / checkmate / stalemate detection (no king-safety awareness)
;   - castling, en passant, pawn promotion
;   - the AI still uses the original's dumb "shove the first movable
;     black piece down a row" heuristic -- it is not legality-checked,
;     since it can only ever produce in-bounds, non-capturing moves anyway.
;
; Assemble:  nasm -f bin tiny_legal.asm -o tiny_legal.com
; ============================================================================
org 100h

start:
    mov ax, 0003h
    int 10h                 ; set 80x25 text mode (also clears screen)
    push 0b800h
    pop es                  ; es = video segment

loop_turn:
    mov si, board
    xor di, di
    mov dl, 8
rows:
    mov cx, 8
cols:
    lodsb
    stosb
    mov byte [es:di], 07h   ; attribute: light grey on black
    inc di
    loop cols
    add di, 144             ; skip to the next text-mode screen row
    dec dl
    jnz rows

    call read_sq
    mov si, ax              ; si = source square pointer
    call read_sq
    mov di, ax              ; di = destination square pointer

; ================= legality check =================
    mov al, [si]
    cmp al, 'A'
    jb  illegal              ; source must be occupied
    cmp al, 'Z'
    ja  illegal              ; ...by a White (uppercase) piece

    mov al, [di]
    cmp al, 'A'
    jb  dest_ok
    cmp al, 'Z'
    jbe illegal              ; destination can't hold another White piece
dest_ok:

    mov bx, si
    sub bx, board
    mov al, bl
    and al, 7
    mov [sf], al             ; source file  0-7
    mov al, bl
    mov cl, 3
    shr al, cl
    mov [sr], al             ; source row   0-7 (0 = rank 8)

    mov bx, di
    sub bx, board
    mov al, bl
    and al, 7
    mov [df], al             ; dest file
    mov al, bl
    mov cl, 3
    shr al, cl
    mov [dr], al             ; dest row

    mov al, [df]
    sub al, [sf]
    mov bl, al               ; bl = dx (signed)
    mov al, [dr]
    sub al, [sr]
    mov bh, al               ; bh = dy (signed)

    mov al, bl
    or  al, bh
    jz  illegal              ; must actually move somewhere

    mov al, bl
    call absval
    mov dl, al               ; dl = |dx|
    mov al, bh
    call absval
    mov dh, al               ; dh = |dy|

    mov al, [si]             ; reload the piece letter for dispatch
    cmp al, 'P'
    je  do_pawn
    cmp al, 'N'
    je  do_knight
    cmp al, 'B'
    je  do_bishop
    cmp al, 'R'
    je  do_rook
    cmp al, 'Q'
    je  do_queen
    cmp al, 'K'
    je  do_king
    jmp illegal

do_king:
    cmp dl, 1
    ja  illegal
    cmp dh, 1
    ja  illegal
    jmp move_apply

do_knight:
    cmp dl, 1
    jne kn2
    cmp dh, 2
    je  move_apply
    jmp illegal
kn2:
    cmp dl, 2
    jne illegal
    cmp dh, 1
    je  move_apply
    jmp illegal

do_bishop:
    cmp dl, dh
    jne illegal
    jmp slide_check

do_rook:
    cmp dl, 0
    je  slide_check
    cmp dh, 0
    je  slide_check
    jmp illegal

do_queen:
    cmp dl, dh
    je  slide_check
    cmp dl, 0
    je  slide_check
    cmp dh, 0
    je  slide_check
    jmp illegal

slide_check:
    mov al, bh
    call signval
    mov ch, al               ; ch = sign(dy)
    mov al, bl
    call signval             ; al = sign(dx)
    mov ah, ch
    shl ah, 1
    shl ah, 1
    shl ah, 1                ; ah = sign(dy)*8
    add al, ah               ; al = step = sign(dy)*8 + sign(dx)
    cbw                      ; sign-extend into ax
    mov bp, ax
    mov bx, si
    add bx, bp
walk:
    cmp bx, di
    je  walk_done
    cmp byte [bx], '.'
    jne illegal
    add bx, bp
    jmp walk
walk_done:
    jmp move_apply

do_pawn:
    cmp bh, -1
    je  p_fwd1
    cmp bh, -2
    je  p_fwd2
    jmp illegal

p_fwd1:
    cmp bl, 0
    je  p_straight
    cmp bl, 1
    je  p_capture
    cmp bl, -1
    je  p_capture
    jmp illegal

p_straight:
    cmp byte [di], '.'
    jne illegal
    jmp move_apply

p_capture:
    mov al, [di]
    cmp al, 'a'
    jb  illegal              ; must actually be capturing an enemy piece
    jmp move_apply

p_fwd2:
    cmp bl, 0
    jne illegal
    mov al, [sr]
    cmp al, 6
    jne illegal              ; double-move only from the starting rank
    cmp byte [di], '.'
    jne illegal
    cmp byte [si-8], '.'
    jne illegal              ; the square jumped over must be empty too
    jmp move_apply

absval:                      ; al = abs(al), signed byte
    cmp al, 0
    jns absdone
    neg al
absdone:
    ret

signval:                     ; al = sign(al): -1, 0 or 1
    cmp al, 0
    je  sv_zero
    jns sv_pos
    mov al, 0FFh
    ret
sv_pos:
    mov al, 1
    ret
sv_zero:
    mov al, 0
    ret

illegal:
    jmp loop_turn            ; ignore the move, re-render, ask again

; ================= apply the move + the AI's reply =================
move_apply:
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

sf: db 0
sr: db 0
df: db 0
dr: db 0
board: db "rnbqkbnr", "pppppppp", "................................", "PPPPPPPP", "RNBQKBNR"
