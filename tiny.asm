org 100h

start:
    mov ax,0003h
    int 10h
    mov ax,0b800h
    mov es,ax

loop_turn:
    ; --- draw board: 64 cells -> video mem, 2 bytes/cell ---
    xor si,si
    xor di,di
    xor bx,bx
draw:
    mov al,[board+si]
    mov [es:di],al
    mov byte [es:di+1],07h
    add di,2
    inc bx
    cmp bx,8
    jne noskip
    xor bx,bx
    add di,144
noskip:
    inc si
    cmp si,64
    jne draw

    ; --- read move: 2 chars for src (file,rank), 2 for dst ---
    call getkey
    sub al,'a'
    mov bl,al        ; file src
    call getkey
    sub al,'1'
    mov ah,7
    sub ah,al        ; row src = 7-rank
    mov al,ah
    mov cl,3
    shl al,cl
    add al,bl
    xor ah,ah
    mov si,ax        ; si = src index

    call getkey
    sub al,'a'
    mov bl,al
    call getkey
    sub al,'1'
    mov ah,7
    sub ah,al
    mov al,ah
    shl al,cl
    add al,bl
    xor ah,ah
    mov di,ax        ; di = dst index

    mov al,[board+si]
    mov [board+di],al
    mov byte [board+si],'.'

    ; --- trivial AI reply: find first lowercase letter, push it down one row ---
    xor si,si
ai_scan:
    mov al,[board+si]
    cmp al,'a'
    jb ai_next
    cmp al,'z'
    ja ai_next
    mov di,si
    add di,8
    cmp di,64
    jae ai_next
    cmp byte [board+di],'.'
    jne ai_next
    mov [board+di],al
    mov byte [board+si],'.'
    jmp loop_turn
ai_next:
    inc si
    cmp si,64
    jne ai_scan
    jmp loop_turn

getkey:
    xor ah,ah
    int 16h
    ret

board: db "rnbqkbnrpppppppp................................PPPPPPPPRNBQKBNR"
