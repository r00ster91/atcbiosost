[bits 16] ; Real mode
[org 0x7c00] ; Load address

%define acc dl
%define ptr bl

xor acc, acc
; BH must stay zero.
xor bx, bx
loop:
    call read_and_print_al
    cmp al, '0'
    je reset_acc
    cmp al, '+'
    je add_or_sub_acc
    cmp al, '-'
    je add_or_sub_acc
    cmp al, 'p'
    je print_acc
    cmp al, 's'
    je store_acc
    cmp al, 'l'
    je load_acc
    cmp al, 't'
    je transfer
    cmp al, '?'
    je help
    call error
    jmp finish

reset_acc:
    xor acc, acc
    jmp finish
add_or_sub_acc:
    push ax

    ; CX = result
    xor cx, cx 

    call read_decimal
    add cl, al
    imul cx, cx, 10
    call read_decimal
    add cl, al
    
    pop ax
    cmp al, '-'
    je .sub 
.add:
    add dl, cl
    jmp finish
.sub:
    sub dl, cl
    jmp finish
print_acc:
    call advance_line
    mov al, acc
    int 0x10
    jmp finish
store_acc:
    mov [memory + bx], acc
    jmp finish
load_acc:
    mov acc, [memory + bx]
    jmp finish
transfer:
    call read_and_print_al
    cmp al, 'a'
    je .transfer_acc_to_ptr
    cmp al, 'p'
    je .transfer_ptr_to_acc
    call error
    jmp finish
.transfer_acc_to_ptr:
    mov ptr, acc
    jmp finish
.transfer_ptr_to_acc:
    mov acc, ptr
    jmp finish
block_start:
    jmp finish
block_end:
help:
    mov si, .text
.loop:
    lodsb
    int 0x10
    cmp si, .text_end
    jne .loop
    jmp finish
.text:
    db `\r\n`
    db `0: acc = 0\r\n`
    db `+: acc += x\r\n`
    db `-: acc -= x\r\n`
    db `p: print acc\r\n`
    db `s: (ptr) = acc\r\n`
    db `l: acc = (ptr)\r\n`
    db `ta: ptr = acc\r\n`
    db `tp: acc = ptr\r\n`
    db `?: help`
.text_end:

finish:
    call advance_line
    jmp loop
advance_line:
    mov ah, 0x0e
    mov al, 0x0a
    int 0x10
    mov al, 0x0d
    int 0x10
    ret

error:
    call advance_line
    mov al, 'X'
    mov ah, 0x0e
    int 0x10
    ret

read_and_print_al:
    ; Read char into AL.
    xor ah, ah
    int 0x16
    ; Print char in AL.
    mov ah, 0x0e
    int 0x10
    ret

read_decimal:
    call read_and_print_al
    sub al, '0' ; Convert to decimal.
    ; Check range.
    jc .error
    cmp al, 9
    jg .error
    ret
.error:
    call error
    ret

section .bss
memory: resb 256
section .text

times 0x200 - 2 - ($ - $$) db 0
dw 0xaa55
