public sceneLoading,outputPicture,clear,cutPicture
extrn fighterRecovery:far, enemyRecovery:far, information:far, loadScene:far
include gamePara

VERTICAL_BOUNDARY equ 240	;战斗界面竖直分界线

;++++++++++++++++++++++++++++++++++++++++++++++++++++
sceneCode segment
assume cs:sceneCode

sceneLoading proc far	;加载场景
	mov ax,13H	;设置图形显示方式
	int 10H
	call loadScene
	push bx
	
	mov bx,0A000H
	mov es,bx
	mov di,VERTICAL_BOUNDARY
	mov al,2		;分界线颜色，绿色
	mov cx,200
	;测试
	;mov si,160 * 320
lineation:	mov es:[di],al
	;测试
	;mov es:[si],al
	;inc si
	add di,320
	loop lineation
	
	pop bx
	cmp bx,0
	jne loadend
	call fighterRecovery	;恢复战机模块显示
	call enemyRecovery	;恢复敌机模块显示
	
loadend:	call information
	ret
sceneLoading endp
	
;输出图片
;将ds:si的图片数据传送到显存，在屏幕相应位置显示图像
;参数：ds:bx暂存图像替补区, ds:si，输出位置，di为列（横坐标），[bp + 6]为行（纵坐标），输出尺寸，[bp + 8]为宽，[bp + 9]为高
;-------------------------------------------------------
outputPicture proc far
	push bp
	mov bp,sp
	
	push ax
	push cx
	push es
	mov ax,0A000H
	mov es,ax
	mov ax,320
	push dx
	mul word ptr [bp + 6]
	pop dx
	
	add di,ax
	xor ch,ch
	mov cl,[bp + 9]
outIMG:	push cx

	push di
	mov cl,[bp + 8]
Imaging: 
	mov al,[si]
	cmp al,0
	je transparent	;透明部分不需要传送处理
	mov ah,es:[di]
	mov [bx],ah	;暂存图像位置原来的像素
	mov es:[di],al;写像素显像
	xor al,[bx]		;利用异或可以方便的实现背景还原
	
transparent:	mov [bx], al	;背景还原缓存,透明部分置为0
	inc bx
	inc si
	inc di
	loop Imaging
	pop di
	
	add di,320
	pop cx
	loop outIMG
	pop es
	pop cx
	pop ax
	
	mov sp,bp
	pop bp
	ret 4
outputPicture endp
;-------------------------------------------------------

;清除图片
;替换的像素还原
;参数：还原区ds:si，输出位置，di为列（横坐标），[bp + 6]为行（纵坐标），输出尺寸，[bp + 8]为宽，[bp + 9]为高
;-------------------------------------------------------
clear proc far
	push bp
	mov bp,sp
	
	push ax
	push cx
	push es
	mov ax,0A000H
	mov es,ax
	mov ax,320
	push dx
	mul word ptr [bp + 6]
	pop dx
	
	add di,ax
	xor ch,ch
	mov cl,[bp + 9]
clearImg:	push cx

	push di
	mov cl,[bp + 8]
clearPix:	mov al,[si]
	xor es:[di],al	;还原区透明部分置零，异或不会改变其值
	inc si
	inc di
	loop clearPix
	pop di
	
	add di,320
	pop cx
	loop clearImg
	pop es
	pop cx
	pop ax
	
	mov sp,bp
	pop bp
	ret 4
clear endp
;-------------------------------------------------------

;裁剪图片
;返回：di为列（横坐标），dx为行（纵坐标），输出尺寸，al为宽，ah为高
;参数：ds:bx裁剪图像替补区, ds:si图片数据，输出位置，[bp + 6]为列（横坐标），[bp + 8]为行（纵坐标），输出尺寸，[bp + 10]为宽，[bp + 11]为高
;-------------------------------------------------------
cutPicture proc far
	push bp
	mov bp,sp
	
	push bx
	push cx
	push si
	
	mov di,[bp + 6]
	mov dx,[bp + 8]
	mov cx,[bp + 10]
	push cx
	cmp di,LEFT_BORDER
	jnl getwid
	mov di,LEFT_BORDER
getwid:	xor ch,ch
	add cx,[bp + 6]
	cmp cx,RIGHT_BORDER + 1
	jb gotwid
	mov cx,RIGHT_BORDER + 1
gotwid:	sub cx,di
	mov al,cl
	pop cx
	
	cmp dx,BORDER_TOP
	jnl gethei
	mov dx,BORDER_TOP
gethei:	mov cl,ch
	xor ch,ch
	add cx,[bp + 8]
	cmp cx,BORDER_BOTTOM + 1
	jb gothei
	mov cx,BORDER_BOTTOM + 1
gothei:	sub cx,dx
	mov ah,cl
	
	push di
	push dx
	
	sub di,[bp + 6]
	sub dx,[bp + 8]	;取相对裁剪位置
	push ax
	xor ax,ax
	mov al,[bp + 10]
	push dx
	mul dx
	pop dx
	add si,ax
	add si,di
	pop ax
	
	xor ch,ch
	mov cl,ah
cutIMG:	push cx
	push ax
	push si
	
	mov cl,al
trim:	mov al,[si]
	mov [bx],al
	inc bx
	inc si
	loop trim
	
	pop si
	mov ax,[bp + 10]
	xor ah,ah
	add si,ax
	pop ax
	pop cx
	loop cutIMG
	
	pop dx
	pop di
	
	pop si
	pop cx
	pop bx
	
	mov sp,bp
	pop bp
	ret 6
cutPicture endp
;-------------------------------------------------------



sceneCode ends
;++++++++++++++++++++++++++++++++++++++++++++++++++++
end