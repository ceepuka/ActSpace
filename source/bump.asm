public collision

code segment
assume cs:code
;参数：dx传递两物体的碰撞半径，[bp + 6]，[bp + 8]为物体1横、纵坐标，[bp + 10]，[bp + 12]为物体2横、纵坐标
;返回：ax,碰撞为1，未碰撞为0
collision proc far
	push bp
	mov bp,sp
	
	push bx
	push cx
	add dl,dh
	xor dh,dh	;dx为两物体不碰撞的最近距离
	
	mov ax,[bp + 10]
	cmp ax,[bp + 6]
	jl xlower
	sub ax,[bp + 6]
	jmp short xweight
xlower:	mov ax,[bp + 6]
	sub ax,[bp + 10]
xweight:	mov bx,ax
	
	cmp bx,dx
	jnb noCollision
	mov ax,[bp + 12]
	cmp ax,[bp + 8]
	jl ylower
	sub ax,[bp + 8]
	jmp short yweight
ylower:	mov ax,[bp + 8]
	sub ax,[bp + 12]
yweight:	mov cx,ax
	
	cmp cx,dx
	jnb noCollision
	mov ax,dx
	mul dl
	mov dx,ax
	
	mov ax,bx
	mul bl
	mov bx,ax
	
	mov ax,cx
	mul cl
	mov cx,ax
	add bx,cx
	cmp bx,dx
	jnb noCollision
	mov ax,1
	jmp short collisioned
	
noCollision:	xor ax,ax

collisioned:
	pop cx
	pop bx
	
	
	mov sp,bp
	pop bp
	ret 8
collision endp

code ends
end