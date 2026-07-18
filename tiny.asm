org 100h

start:
    mov ax,0003h
    int 10h
    push 0b800h
    pop es

loop_turn:
    mov si,board
    xor di,di
    mov dl,8
rows:
    mov cx,8
cols:
    lodsb
    stosb
    mov byte [es:di],07h
    inc di
    loop cols
    add di,144
    dec dl
    jnz rows

    ; --- read move: 2 chars for src (file,rank), 2 for dst ---
    call read_sq
    mov si,ax        ; si = src index
    call read_sq
    mov di,ax        ; di = dst index

    mov al,[si]
    mov [di],al
    mov byte [si],'.'

    ; --- trivial AI reply: find first lowercase letter, push it down one row ---
    mov si,board
ai_scan:
    mov al,[si]
    cmp al,'a'
    jb ai_next
    mov di,si
    add di,8
    cmp di,board+64
    jae ai_next
    cmp byte [di],'.'
    jne ai_next
    mov [di],al
    mov byte [si],'.'
    jmp loop_turn
ai_next:
    inc si
    cmp si,board+64
    jne ai_scan
    jmp loop_turn

read_sq:
    xor ah,ah
    int 16h
    sub al,'a'
    mov bl,al        ; file
    xor ah,ah
    int 16h
    neg al
    add al,0x38       ; row = 7-(rank-'1') = 0x38-rank
    mov cl,3
    shl al,cl
    add al,bl
    xor ah,ah
    add ax,board
    ret

board: db "rnbqkbnrpppppppp................................PPPPPPPPRNBQKBNR"
