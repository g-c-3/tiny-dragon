; ============================================================================
; Tiny Dragon: Hyper
;
; The most aggressively golfed derivative. Builds on Ultra's attribute-skip
; trick and adds two more cuts:
;
;   1. Drops the video mode-set (`mov ax,3 / int 10h`) entirely, on the
;      assumption that DOS has already left the screen in 80x25 16-color
;      text mode (mode 3) -- the standard default. This is where Ultra's
;      "rely on BIOS's clear-to-07h" assumption becomes a bigger one: we're
;      now also trusting that *some* previous program didn't leave the
;      screen in a different mode, resolution, or attribute state. If that
;      assumption is wrong, the board will render incorrectly (wrong size,
;      wrong colors, or garbage from whatever was on screen before).
;      In DOSBox/js-dos starting fresh, this is very likely fine. On real
;      hardware after other programs have run, it's much less of a sure
;      thing.  -5 bytes.
;
;   2. Replaces the AI scan's bounds check (`cmp si,board+64 / jne ai_scan`,
;      6 bytes) with a CX-driven `loop` (`mov cx,64` once up front, then
;      `loop ai_scan`, 2 bytes at the branch point). This one has no extra
;      risk versus Ultra -- it's a pure instruction-count trick, verified
;      behaviorally identical.  -1 byte net.
;
;   3. Reuses that same CX counter for the *other* bounds check inside the
;      scan: whether the square 8 below the current one is still on the
;      board. CX decrements once per square scanned, so "this is one of
;      the bottom 8 squares" is exactly "CX <= 8" at that point, with no
;      separate address math needed. Swaps `cmp di,board+64 / jae ai_next`
;      (6 bytes) for `cmp cx,8 / jbe ai_next` (5 bytes). Also no extra
;      risk -- verified against all 8 bottom-row squares directly.
;
;   Original : 185 bytes
;   Ultra    : 181 bytes  (safe: BIOS clears attrs on mode-set, still sets mode)
;   Hyper    : 174 bytes  (assumes mode is already correct; skips setting it)
;
; If you want the mode-set back (recommended unless you specifically know
; your launch environment is already in mode 3), just add back:
;     mov ax, 0003h
;     int 10h
; right after `org 100h` -- that reproduces Ultra's 181-byte behavior with
; Hyper's two loop/CX tricks, i.e. 179 bytes, the best of both.
;
; Assemble:  nasm -f bin tiny_hyper.asm -o tiny_hyper.com
; ============================================================================
org 100h

start:
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
    stosb
    inc di                   ; skip the attribute byte (already 07h --
                              ; see the risk note above about *why* it's 07h)
    loop cols
    add di, 144
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
    mov cx, 64                ; scan counter for the loop below, also
                               ; reused for the bounds check just below
ai_scan:
    mov al, [si]
    cmp al, 'a'
    jb  ai_next
    mov di, si
    add di, 8
    cmp cx, 8                  ; CX counts iterations remaining; CX<=8
    jbe ai_next                ; means this square is in the bottom row,
                                ; so si+8 would be off the board
    cmp byte [di], '.'
    jne ai_next
    mov [di], al
    mov byte [si], '.'
    jmp loop_turn
ai_next:
    inc si
    loop ai_scan
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
