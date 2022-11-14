public loadBMP,loadScene
extrn explodeBmp:byte,fighterBmp:byte,bulletBmp:byte,scoutFighterBmp:byte,fightFighterBmp:byte,eliteFighterBmp:byte,ebullet1Bmp:byte,ebullet2Bmp:byte,ebullet3Bmp:byte

data segment
bmpfile dw background, explode, fighter, bullet, scoutFighter, fightFighter, eliteFighter, ebullet1, ebullet2, ebullet3
fileComp equ $ - bmpfile
bmpbuffer dw bmpArray,seg bmpArray, explodeBmp,seg explodeBmp, fighterBmp,seg fighterBmp, bulletBmp,seg bulletBmp, scoutFighterBmp,seg scoutFighterBmp, fightFighterBmp,seg fightFighterBmp
		  dw eliteFighterBmp,seg eliteFighterBmp, ebullet1Bmp,seg ebullet1Bmp, ebullet2Bmp,seg ebullet2Bmp, ebullet3Bmp,seg ebullet3Bmp
;背景缓冲区
bgSize dw 0, 0		;背景宽和高
head db 54 dup(0) ;文件头和信息头
palette db 1024 dup(0) ;调色板颜色索引表，必须紧接文件头部（head）之下
bmpArray db 64000 dup(0) ;位图阵列，最多显示320*200（即64000）像素

background db 'BG.bmp',0
explode db 'explode.bmp',0
fighter db 'fighter.bmp',0
bullet db 'bullet.bmp',0
scoutFighter db 'scout.bmp',0
fightFighter db 'eFighter.bmp',0
eliteFighter db 'elite.bmp',0
ebullet1 db 'bullet1.bmp',0
ebullet2 db 'bullet2.bmp',0
ebullet3 db 'bullet3.bmp',0


errorOpen db 'File open failed!',0AH,'$'
errorRead db 'File read failed!',0AH,'$'
errorOver db 'Image size too large!',0AH,'$'
data ends

code segment
assume cs:code,ds:data

;图片加载程序，返回si，成功其值为0，否则为非0
loadBMP proc far
	push ax
	push bx
	push cx
	push dx
	push di
	push ds
	push es
	mov ax,data
	mov ds,ax
	
	xor si,si
	xor di,di
	jmp short FileInterface
	
loaded:	sub si,fileComp
	pop es
	pop ds
	pop di
	pop dx
	pop cx
	pop bx
	pop ax
	ret
	
FileInterface:
	mov ax,3d00h
	cmp si,fileComp
	je loaded
	mov dx,bmpfile[si]
	int 21h
	jc openFailed
	jmp short readfile
openFailed:
	lea dx,errorOpen
	mov ah,9
	int 21h
	jmp loaded
readFailed:
	lea dx,errorRead
	jmp short tips
sizeOver:
	lea dx,errorOver
tips:
	mov ah,9
	int 21h
	mov ah,3eh
	int 21h
	jmp loaded

;将文件读入内存缓冲区
readfile:	mov bx,ax
	mov ah,3fh
	mov cx,54		;文件头部
	cmp si,0		;背景最前，据此设置调色板
	jne buffer
	add cx,1024	;位图调色板
	
buffer:
	lea dx,head
	int 21h
	jc readFailed
	
	mov ax,4200h	;移动文件指针，从文件头开始绝对偏移量
	xor cx,cx
	mov dx,1078
	int 21h
	
	mov cx,head[16H];位图高度
	cmp cx,200
	ja sizeOver
	mov ax,head[12H];位图宽度
	cmp ax,320
	ja sizeOver
	mov dx,bmpbuffer[di]		;缓冲区偏移地址
readPixel:
	push ax
	push cx
	mov cx,ax
	
	mov ah,3fh
	push ds
	mov ds,bmpbuffer[di+2]	;缓冲区段地址
	int 21h
	pop ds
	add dx,cx
	
	and cx,3		;位图宽（4的整数倍存储）取余，非4倍数剔除补足字节
	jz fp_notMove
	push dx
	mov dx,4
	sub dx,cx
	xor cx,cx
	mov ax,4201h
	int 21h
	pop dx
fp_notMove:
	pop cx
	pop ax
	loop readPixel
	
	
	mov ah,3eh	;关闭文件
	int 21h
	
	mov ax,head[12H]
	mov bx,head[16H]
	cmp si,0
	jne transpose
	mov bgSize[0],ax
	mov bgSize[2],bx
	jmp short next
	
transpose:
	mov cx,ax
	mul bl
	sub ax,cx
	shr bl,1
	push si
	push di
	mov si,bmpbuffer[di]
	mov es,bmpbuffer[di+2]
	mov di,si
	add di,ax
	
setup:	push cx
replace:	mov al,es:[si]
	mov ah,es:[di]
	mov es:[si],ah
	mov es:[di],al
	inc si
	inc di
	loop replace
	pop cx
	sub di,cx
	sub di,cx
	dec bl
	cmp bl,0
	jne setup
	pop di
	pop si

next:	
	inc si
	inc si
	add di,4
	jmp FileInterface


loadBMP endp

;加载场景，设置调色板，需要先设置好显示方式13H
loadScene proc far
	push ax
	push bx
	push cx
	push dx
	push si
	push di
	push ds
	push es
	mov ax,data
	mov ds,ax
	
	mov cx,256
	mov bl,0
	xor di,di
setColor:
	mov al,bl
	mov dx,03c8h
	out dx,al
	mov dx,03c9h
	mov al,palette[di+2]
	shr al,1
	shr al,1
	out dx,al 
	mov al,palette[di+1]
	shr al,1
	shr al,1
	out dx,al
	mov al,palette[di]
	shr al,1
	shr al,1
	out dx,al
	add di,4
	inc bl
	loop setColor
	
;向显存地址写入数据
	mov ax,0a000h
	mov es,ax
;位图中图像由底向上自左向右存储
	lea si,bmpArray
	mov ax,320
	mov cx,bgSize[2];位图高度
	dec cx
	mul cx
	mov di,ax
	inc cx
	display:
	push cx
	push di
	mov cx,bgSize[0];位图宽度
	cld
	rep movsb
	pop di
	pop cx
	sub di,320
	loop display

	pop es
	pop ds
	pop di
	pop si
	pop dx
	pop cx
	pop bx
	pop ax
	ret
loadScene endp

code ends
end