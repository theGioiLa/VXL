;Chu y khi thuc hien thuat toan:
;+ Khoi tao:
;    Block 512-bit co cau truc:
;        msg|_|_|...|_|_|_|_|_|_|_|_|
;       <----448----><------8------->
;       8-bit cuoi co dang low -> high:  chieu dai cua msg mod 2^64
;       k len khai bao nhu duoi
;          
data segment 
    ; constant  
    USART_CMD  Equ 2
    USART_DATA Equ 0
    
    s db 7, 12, 17, 22,  7, 12, 17, 22,  7, 12, 17, 22,  7, 12, 17, 22  ; round0
      db 5,  9, 14, 20,  5,  9, 14, 20,  5,  9, 14, 20,  5,  9, 14, 20  ; round1
      db 4, 11, 16, 23,  4, 11, 16, 23,  4, 11, 16, 23,  4, 11, 16, 23  ; round2
      db 6, 10, 15, 21,  6, 10, 15, 21,  6, 10, 15, 21,  6, 10, 15, 21  ; round3 
       
    K dd 0d76aa478h, 0e8c7b756h, 0242070dbh, 0c1bdceeeh    ; 0... 3
      dd 0f57c0fafh, 04787c62ah, 0a8304613h, 0fd469501h    ; 4... 7
      dd 0698098d8h, 08b44f7afh, 0ffff5bb1h, 0895cd7beh    ; 8... 11
      dd 06b901122h, 0fd987193h, 0a679438eh, 049b40821h    ; 12...15
      dd 0f61e2562h, 0c040b340h, 0265e5a51h, 0e9b6c7aah    ; 16...19
      dd 0d62f105dh, 002441453h, 0d8a1e681h, 0e7d3fbc8h    ; 20...23
      dd 021e1cde6h, 0c33707d6h, 0f4d50d87h, 0455a14edh    ; 24...27
      dd 0a9e3e905h, 0fcefa3f8h, 0676f02d9h, 08d2a4c8ah    ; 28...31
      dd 0fffa3942h, 08771f681h, 06d9d6122h, 0fde5380ch    ; 32...35
      dd 0a4beea44h, 04bdecfa9h, 0f6bb4b60h, 0bebfbc70h    ; 36...39
      dd 0289b7ec6h, 0eaa127fah, 0d4ef3085h, 004881d05h    ; 40...43
      dd 0d9d4d039h, 0e6db99e5h, 01fa27cf8h, 0c4ac5665h    ; 44...47
      dd 0f4292244h, 0432aff97h, 0ab9423a7h, 0fc93a039h    ; 48...51
      dd 0655b59c3h, 08f0ccc92h, 0ffeff47dh, 085845dd1h    ; 52...55
      dd 06fa87e4fh, 0fe2ce6e0h, 0a3014314h, 04e0811a1h    ; 56...59
      dd 0f7537e82h, 0bd3af235h, 02ad7d2bbh, 0eb86d391h    ; 60...63
    
    ; ======= I/O =========   
    welcome db ' ---Quang Quý - 20153108 ---', 13, 10, 0
    msgIn   db 'Input: ', 0
    msgOut  db '  MD5: ', 0    
    input   db 20 dup(?)
    output  dw 8 dup(1)
    block   db 64 dup(0)
    length  db ?                ; chieu dai chuoi nhap vao 
    
    ; Khoi tao a0, b0, c0, d0 (little-edian)
    a0 dw 02301h, 06745h
    b0 dw 0ab89h, 0efcdh 
    c0 dw 0dcfeh, 098bah
    d0 dw 05476h, 01032h
     
    ; buffer cua nguon 
    a dd ?  
    b dd ?
    c dd ?
    d dd ?
    
    F dd ?
    g dw ?       
    tempResult dd ?
    
    ; so bit quay
    nbit db ?       
    
ends

stack segment
    dw 128 dup(?) 
ends

code segment
start:

    ; add your code here
    mov ax, data
    mov ds, ax 
    mov es, ax   
    
    call USART_Init
    mov si, offset welcome
    call USART_Write_Str
    
    call nhapDuLieu 
    call taoBlock  
   
    ; Thuat toan
     
    ; Khoi tao a, b, c, d 
    mov ax, a0[0]
    mov a[0], ax
    mov ax, a0[2]
    mov a[2], ax 
    
    mov ax, b0[0]
    mov b[0], ax
    mov ax, b0[2]
    mov b[2], ax
    
    mov ax, c0[0]
    mov c[0], ax
    mov ax, c0[2]
    mov c[2], ax
    
    mov ax, d0[0]
    mov d[0], ax
    mov ax, d0[2]
    mov d[2], ax
    
    mov di, 0 
    
    lap:       
        mov si, di
        NhoHon16:  
            cmp di, 16
            jge NhoHon32
                 
            ; F_low
            mov ax, d[0]
            xor ax, c[0]
            and ax, b[0]
            xor ax, d[0]
 
            mov F[0], ax
            
            ; F_high
            mov ax, d[2]
            xor ax, c[2]
            and ax, b[2]
            xor ax, d[2]
            mov F[2], ax
            
            mov g, si
            
            jmp Done
  
        NhoHon32: 
            cmp di, 32
            jge NhoHon48 
            
            ; F_low
            mov ax, c[0]
            xor ax, b[0]
            and ax, d[0]
            xor ax, c[0]
 
            mov F[0], ax
            
            ; F_high
            mov ax, c[2]
            xor ax, b[2]
            and ax, d[2]
            xor ax, c[2]
 
            mov F[2], ax
            
            ; phep nhan
            mov ax, 5
            mul si   
            inc ax   
            mov dl, 16
            div dl
            mov al, ah
            mov ah, 0
            mov g, ax
      
            jmp Done
            
        NhoHon48:      
            cmp di, 48
            jge NhoHon63 
            
            ; F_low
            mov ax, b[0]
            xor ax, c[0]
            xor ax, d[0]
            
            mov F[0], ax
            
            ; F_high
            mov ax, b[2]
            xor ax, c[2]
            xor ax, d[2]
 
            mov F[2], ax
            
            ; phep nhan
            mov ax, 3
            mul si   
            add ax, 5   
            mov dl, 16
            div dl
            mov al, ah
            mov ah, 0
            mov g, ax  
            
            jmp Done 
            
        NhoHon63:  
            ; F_low
            mov ax, d[0]
            not ax
            or ax, b[0]
            xor ax, c[0]
            
            mov F[0], ax
            
            ; F_high
            mov ax, d[2]
            not ax
            or ax, b[2]
            xor ax, c[2]
            
            mov F[2], ax
            
            mov ax, 7
            mul si 
            mov dl, 16
            div dl
            mov al, ah
            mov ah, 0
            mov g, ax   
        
        ;========= F := F + A + K[i] + block[g] ==============
        
        ; tempResult = K[i] + block[g]   
        Done:
            mov si, g
            shl si, 2 
            mov bx, di
            shl bx, 2
                                    
            ; low 16-bit                                    
            mov ax, K[bx]            
            mov dl, block[si]
            mov dh, block[si + 1]                   
     
            add ax, dx
            mov tempResult[0], ax
            
            mov ax, K[bx + 2]    
            mov dl, block[si + 2]
            mov dh, block[si + 3] 
            
            adc ax, dx
            mov tempResult[2], ax
            
            ; tempResult + A
            mov ax, a[0]
            add ax, tempResult[0]
            mov tempResult[0], ax
            
            mov ax, a[2]
            adc ax, tempResult[2]
            mov tempResult[2], ax
            
            ; F = F + tempResult
            mov ax, F[0] 
            add ax, tempResult[0]
            mov F[0], ax
            
            mov ax, F[2]
            adc ax, tempResult[2]
            mov F[2], ax
            
            ;============= A := D == D := C == C := B ============
            mov ax, d[0]
            mov a[0], ax
            mov ax, d[2]
            mov a[2], ax
            
            mov ax, c[0]
            mov d[0], ax      
            mov ax, c[2]
            mov d[2], ax    
            
            mov ax, b[0]
            mov c[0], ax       
            mov ax, b[2]
            mov c[2], ax   
            
            ;============= B = B + leftRotate(F, s[i]) =============
            ; quay F di s[i] bit 
            mov al, s[di]
            mov nBit, al
            call quay_nBit 
            
            mov ax, b[0]
            add ax, F[0]
            mov b[0], ax
            
            mov ax, b[2]
            adc ax, F[2]
            mov b[2], ax
 
    inc di
    cmp di, 64
    jnz lap  
       
    ;======== Add this chunk's hash to result so far =========
    
    ;a0 = a0 + a
    mov ax, a[0]
    add ax, a0[0]
    mov a0[0], ax
    mov output[0], ax
    
    mov ax, a[2]
    adc ax, a0[2]
    mov a0[2], ax
    mov output[2], ax 
    
    ;b0 = b0 + b
    mov ax, b[0]
    add ax, b0[0]
    mov b0[0], ax
    mov output[4], ax
    
    mov ax, b[2]
    adc ax, b0[2]
    mov b0[2], ax
    mov output[6], ax  
    
    ;c0 = c0 + c
    mov ax, c[0]
    add ax, c0[0]
    mov c0[0], ax    
    mov output[8], ax
    
    mov ax, c[2]
    adc ax, c0[2]
    mov c0[2], ax  
    mov output[10], ax 
    
    ;d0 = d0 + d   
    mov ax, d[0]
    add ax, d0[0]
    mov d0[0], ax 
    mov output[12], ax
    
    mov ax, d[2]
    adc ax, d0[2]
    mov d0[2], ax 
    mov output[14], ax
        
    call xuatDuLieu   
   
mov ax, 4c00h
int 21h      

; ========== Nhap DL =========
nhapDuLieu Proc
   ; lea dx, msgIn
;    mov ah, 09h
;    int 21h
    mov si, offset msgIn
    call USART_Write_Str
      
    mov si, 0
    
    Nhap:
       ; mov ah, 01h
;        int 21h     
        call USART_Read
        mov input[si], al
        mov bl, al  
        call USART_Write
        mov al, bl
        cmp al, 13
        jz  Thoat
        
        inc si
        cmp si, 20
    jnz Nhap
 
    Thoat:   
    
    ret
nhapDuLieu EndP 

; ========= Xuat DL ==========
xuatDuLieu Proc
   ; lea dx, msgOut
;    mov ah, 09h
;    int 21h 
    mov si, offset msgOut
    call USART_Write_Str 
    
    mov si, 0
    mov di, 0
    inByte: 
        mov bl, byte ptr output[di]
        mov cx, 2              
        
        hexLoop:
            rol bl, 4
            mov dl, bl
            and dl, 0fh
            cmp dl, 9
            jg kyTu ; dl <= 9
            add dl, '0'   
            jmp inHex
            
        kyTu:
            sub dl, 10
            add dl, 'a' 
        inHex:
           ; mov ah, 0x2h
;            int 21h  
           mov al, dl
           call USART_Write
      
        loop hexLoop 
       
        inc si
        inc di
        cmp si, 16 
  
    jnz inByte  

    ret
xuatDuLieu EndP 

;========= Tao Block =========
taoBlock Proc
    
    ; Dem chieu dai cua input
    mov si, 0
    dem:
        mov al, input[si]
        
        cmp al, 13
        jz dung
        
        mov block[si], al
        
        inc si
        cmp si, 20
        jnz dem
    
    dung:  
        mov block[si], 80h
        mov ax, si
        shl al, 3
        
        mov block[56], al
    
    ret
taoBlock EndP

; ======== Quay bit ========== 

quay_nBit Proc   
     mov cx, 0
     mov cl, nBit    
                     
            ; low bit: AX, high bit: DX
            mov ax, F[0]
            mov dx, F[2]
                                             
                                                     
     quay:  
            ; dich trai dx va luu bit dich vao bl
            shl dx, 1
            mov bl, 0
            adc bl, 0
             
            ; dich trai ax va luu bit dich vao bh
            shl ax, 1
            mov bh, 0
            adc bh, 0                        
            
            add dl, bh
            add al, bl
            
     loop quay
     
     mov F[0], ax
     mov F[2], dx       
            
     ret
quay_nBit EndP 

; =============== USART Function ==========
USART_Init Proc
    ;Set up UART
    mov al, 7Dh
    out USART_CMD, al
    mov al, 7h
    out USART_CMD, al 
    
    ret
USART_Init EndP    

; Read a byte form USART to AL
USART_Read Proc
RL1:  
    in al, USART_CMD
    test al, 2
    JE RL1
    in al, USART_DATA
    shr al, 1 
    
    ret
USART_Read EndP
    
; Write a byte from al to USART
USART_Write Proc
    push bx     
    mov bl, al
WL1:
    in al, USART_CMD
    test al, 1
    JE WL1
    mov al, bl
    out USART_DATA, al
    pop bx
    
    ret        
USART_Write EndP

; Write a Sring to USART
USART_Write_Str Proc
swloop:
    lodsb
    or al, al
    je swdone
    call USART_Write
    jmp swloop
swdone:
    ret

USART_Write_Str EndP

;========================     
;countLength Proc
;    push si
;    
;    mov si, 0
;    count:
;        mov al, input[si] 
;        cmp al, 13
;        jz xong
;        inc si
;    
;    cmp si, 20
;    jnz count  
;   
;    xong: 
;    xor ax, ax
;    mov ax, si
;    mov length, al
;
;    pop si  
;    ret
;countLength EndP   
;
;hexL Proc             
;    push cx
;    
;    mov bl, length
;        mov cx, 2  
;        
;        l: 
;            rol bl, 4
;            mov dl, bl
;            and dl, 0fh
;            cmp dl, 9
;            jg character ; dl <= 9
;            add dl, '0'   
;            jmp x
;            
;        character:
;            sub dl, 10
;            add dl, 'a' 
;        x:
;            mov al, dl
;            call USART_Write
;      
;        loop l        
;        mov al, ' '
;        call USART_Write   
;        pop cx
;        ret
;hexL EndP
; ================END PROG=================
ends 
end start
