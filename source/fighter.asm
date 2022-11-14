public showFighter,clearFighter,actionFighter,efighterCollisionResponse,fighterRecovery,fighterBmp,bulletBmp
public fighterHealth,fighterX,fighterY,fighterShiftFactor,bulletFactor,bulletPointer,bulletFireFactor	;初值由初始化过程决定
public fighterCoreX,fighterCoreY,fighterRc
public bulletCoreX,bulletCoreY
;extrn foesfileHandle:word, enemyFuncTestFile:byte, letterSequence:byte	;测试用
extrn outputPicture:far, clear:far, collision:far, clearEnemy:far, fighterCollisionResponse:far, showHP:far, message:far, detonate:far,explosion:far
extrn enemyCoreX:word, enemyCoreY:word, enemyRc:byte, enemy:word, foep:word
extrn ebulletCoreX:word, ebulletCoreY:word
include gamePara

;++++++++++++++++++++++++++++++++++++++++++++++++++++
data segment
;定义战机，底部居中，可控制移动
;**********************************************************
fighterHealth dw 10		;为0时战机销毁，游戏结束
;位置（左上角）
fighterX dw (RIGHT_BORDER - FIGHTER_WIDTH) / 2	;111，横坐标
fighterY dw BORDER_BOTTOM - FIGHTER_HEIGHT + 1	;181，纵坐标
;中心坐标
fighterCoreX dw (RIGHT_BORDER - FIGHTER_WIDTH) / 2 + FIGHTER_WIDTH / 2
fighterCoreY dw BORDER_BOTTOM - FIGHTER_HEIGHT + 1 + FIGHTER_HEIGHT / 2
fighterRc db (FIGHTER_WIDTH / 2 + FIGHTER_HEIGHT / 2 + 1) / 2	;碰撞半径
db 0
motion dw upper,left,down,right
;战机图像
fighterBmp db 0,0,0, 0,0,0, 0,0,9, 0,0,0, 0,0,0, 0,0
		   db 0,0,0, 0,0,0, 0,9,42, 9,0,0, 0,0,0, 0,0
		   db 0,0,0, 0,0,0, 0,9,42, 9,0,0, 0,0,0, 0,0
		   db 0,0,0, 0,0,0, 0,9,42, 9,0,0, 0,0,0, 0,0
		   db 0,0,0, 0,0,0, 0,9,13, 9,0,0, 0,0,0, 0,0
		   db 0,0,0, 0,0,0, 9,9,13, 9,9,0, 0,0,0, 0,0
		   db 0,0,0, 0,0,0, 9,13,15, 13,9,0, 0,0,0, 0,0
		   db 0,0,0, 0,0,0, 9,13,15, 13,9,0, 0,0,0, 0,0
		   db 0,0,0, 0,0,9, 9,13,13, 13,9,9, 0,0,0, 0,0
		   db 0,0,0, 0,9,9, 13,13,13, 13,13,9, 9,0,0, 0,0
		   db 0,0,0, 9,9,13, 13,42,15, 42,13,13, 9,9,0, 0,0
		   db 0,0,9, 9,13,13, 42,15,15, 15,42,13, 13,9,9, 0,0
		   db 0,9,9, 13,13,42, 42,15,15, 15,42,42, 13,13,9, 9,0
		   db 9,9,15, 13,42,42, 42,42,15, 42,42,42, 42,13,15, 9,9
		   db 9,15,15, 13,13,13, 13,42,15, 42,13,13, 13,13,15, 15,9
		   db 9,9,9, 9,9,9, 13,42,15, 42,13,9, 9,9,9, 9,9
		   db 0,0,0, 0,0,9, 13,13,13, 13,13,9, 0,0,0, 0,0
		   db 0,0,0, 0,9,9, 42,9,9, 9,42,9, 9,0,0, 0,0
		   db 0,0,0, 9,9,0, 42,0,0, 0,42,0, 9,9,0, 0,0
;战机图像替补块
fighterReplaceBlock db FIGHTER_WIDTH * FIGHTER_HEIGHT dup (?)
fighterShiftFactor db 0	;战机移动因子，每FIGHTER_INTERVALS移动一像素


;定义战机子弹，可批量生成和销毁 bullet
;**********************************************************
;战机子弹图像
bulletBmp db 0,43,0
		  db 43,15,43
		  db 0,43,0
;战机子弹图像替补块
bulletReplaceBlock db BULLET_MAX_NUM * BULLET_WIDTH * BULLET_HEIGHT dup (?)
bulletReplaceUnit label word
x = offset bulletReplaceBlock
	rept BULLET_MAX_NUM
	dw x
x = x + BULLET_WIDTH * BULLET_HEIGHT
endm
;战机子弹数组
bulletX dw BULLET_MAX_NUM dup (?)
bulletY dw BULLET_MAX_NUM dup (?)
;中心坐标
bulletCoreX dw BULLET_MAX_NUM dup (?)
bulletCoreY dw BULLET_MAX_NUM dup (?)
bulletFactor dw BULLET_MAX_NUM dup (0)		;低字节：子弹飞行因子，每BULLET_FLIGHT_INTERVAL前进一像素。高字节：子弹存在状态，1存在，0空
bulletPointer dw 0	;子弹数组指针, 发射时指向。
bulletFireFactor db 0			;子弹发射因子，每BULLET_FIRE_INTERVAL发射一颗


data ends
;++++++++++++++++++++++++++++++++++++++++++++++++++++

;++++++++++++++++++++++++++++++++++++++++++++++++++++
code segment
assume cs:code,ds:data

;战机动作过程
;-------------------------------------------------------
actionFighter proc far
	push ds
	push ax
	mov ax,data
	mov ds,ax
	pop ax
	inc fighterShiftFactor
	cmp fighterShiftFactor,FIGHTER_INTERVALS
	jne actionEnd	;一定时间移动一像素
	mov fighterShiftFactor,0

	cmp ah,1
	jne actionEnd	;移动按键下进行相应移动
	push ax
	push bx
	mov al,FIGHTER_WIDTH
	mov ah,FIGHTER_HEIGHT
	push si
	push di
	lea si,fighterReplaceBlock
	mov di,fighterX
	clearPicture fighterY,ax
	
	call word ptr motion[bx]	;bx参数对应移动方向
	
	;取中心坐标
	mov ax,fighterX
	add ax,FIGHTER_WIDTH / 2
	mov fighterCoreX,ax
	mov dx,fighterY
	add dx,FIGHTER_HEIGHT / 2
	mov fighterCoreY,dx
	
	mov bl,(FIGHTER_WIDTH / 2 + FIGHTER_HEIGHT / 2 + 1) / 2
	mov bh,1				;1表示战机
	mov di,fighterHealth
	call fighterCollisionResponse	;战机碰撞响应
	mov fighterHealth,di
	call showHP
	cmp di,0
	je skip
	
	mov al,FIGHTER_WIDTH
	mov ah,FIGHTER_HEIGHT
	lea bx,fighterReplaceBlock
	lea si,fighterBmp
	mov di,fighterX
	displayIMG fighterY,ax
	
skip:	pop di
	pop si
	pop bx
	pop ax
	cmp fighterHealth,0
	je gameOver
actionEnd: call actionBullet
gameOver:	pop ds
	ret
	
actionFighter endp
;-------------------------------------------------------

;敌机碰撞响应过程,由敌机调用
;参数ax,dx传递中心坐标，bl碰撞半径，di存在参数,返回di
;-------------------------------------------------------
efighterCollisionResponse proc far
	push cx
	push si
	push ds
	
	push bx
	mov bx,data
	mov ds,bx			;置战机段
	pop bx
	
	;传递中心坐标
	push dx
	push ax
	push fighterCoreY
	push fighterCoreX
	;传递碰撞半径
	mov dl,bl
	mov dh,(FIGHTER_WIDTH / 2 + FIGHTER_HEIGHT / 2 + 1) / 2
	call collision
	
	cmp ax,1
	jne enemyNext
	dec di
	dec fighterHealth
	call showHP
	
enemyNext:	
	pop ds
	pop si
	pop cx
	ret
efighterCollisionResponse endp
;-------------------------------------------------------

;显示战机
;-------------------------------------------------------
showFighter proc far
	push ax
	push ds
	mov ax,data
	mov ds,ax
	mov al,FIGHTER_WIDTH
	mov ah,FIGHTER_HEIGHT
	push bx
	push si
	push di
	lea bx,fighterReplaceBlock
	lea si,fighterBmp
	mov di,fighterX
	displayIMG fighterY,ax
	pop di
	pop si
	pop bx
	pop ds
	pop ax
	ret
showFighter endp
;-------------------------------------------------------

;擦除战机
;-------------------------------------------------------
clearFighter proc
	push ax
	push ds
	mov ax,data
	mov ds,ax
	mov al,FIGHTER_WIDTH
	mov ah,FIGHTER_HEIGHT
	push si
	push di
	lea si,fighterReplaceBlock
	mov di,fighterX
	clearPicture fighterY,ax
	pop di
	pop si
	pop ds
	pop ax
	ret
clearFighter endp
;-------------------------------------------------------

;参数：bx
;-------------------------------------------------------
clearBullet proc
	push ax
	mov al,BULLET_WIDTH
	mov ah,BULLET_HEIGHT
	push si
	push di
	mov si,bulletReplaceUnit[bx]
	mov di,bulletX[bx]
	clearPicture bulletY[bx],ax
	pop di
	pop si
	pop ax
	ret
clearBullet endp
;-------------------------------------------------------

;战机上移
;-------------------------------------------------------
upper proc
	cmp fighterY,BORDER_TOP
	je upwardBoundary
	dec fighterY
upwardBoundary: ret
upper endp
;-------------------------------------------------------
;战机左移
;-------------------------------------------------------
left proc
	cmp fighterX,LEFT_BORDER
	je leftBoundary
	dec fighterX
leftBoundary: ret
left endp
;-------------------------------------------------------
;战机下移
;-------------------------------------------------------
down proc
	cmp fighterY,BORDER_BOTTOM - FIGHTER_HEIGHT + 1
	je downBoundary
	inc fighterY
downBoundary: ret
down endp
;-------------------------------------------------------
;战机右移
;-------------------------------------------------------
right proc
	cmp fighterX,RIGHT_BORDER - FIGHTER_WIDTH + 1
	je rightBoundary
	inc fighterX
rightBoundary: ret
right endp
;-------------------------------------------------------

;子弹动态过程
;-------------------------------------------------------
actionBullet proc
	push bx
	push dx
	inc bulletFireFactor
	cmp bulletFireFactor,BULLET_FIRE_INTERVAL		;bulletFireFactor为BULLET_FIRE_INTERVAL时战机发射子弹
	jne ergodic					;否则跳转到子弹遍历中
	mov bulletFireFactor,0
	call fire

ergodic:	xor bx,bx
	
bulletQueue:	
	call bulletFlight			;子弹飞行处理
	
	
bulletNext:	add bx,2
	cmp bx,BULLET_MAX_NUM * 2
	je ergodicEnd
	jmp short bulletQueue
ergodicEnd:
	pop dx
	pop bx
	ret
actionBullet endp
;-------------------------------------------------------
;发射子弹
;-------------------------------------------------------
fire proc
	mov bx,bulletPointer
	shl bx,1
	mov ax,fighterY
	cmp ax,BULLET_HEIGHT	;坐标不能超出范围
	jb fireEnd
	sub ax,BULLET_HEIGHT
	mov bulletY[bx],ax
	mov ax,fighterX
	add ax,(FIGHTER_WIDTH - BULLET_WIDTH) / 2
	mov bulletX[bx],ax
	
	;取中心坐标
	add ax,BULLET_WIDTH / 2
	mov bulletCoreX[bx],ax
	mov dx,bulletY[bx]
	add dx,BULLET_HEIGHT / 2
	mov bulletCoreY[bx],dx
	
	push bx
	mov di,1
	mov bl,0
	mov bh,2	;2表示子弹
	call fighterCollisionResponse		;战机子弹碰撞响应
	pop bx
	cmp di,0
	je hit1
	mov bulletFactor[bx],100H	;置子弹状态为存在，重置子弹飞行因子
	
	mov al,BULLET_WIDTH
	mov ah,BULLET_HEIGHT
	push bx
	push si
	lea si,bulletBmp
	mov di,bulletX[bx]
	push ax
	push bulletY[bx]
	mov bx,bulletReplaceUnit[bx]
	call outputPicture
	pop si
	pop bx
	
	inc bulletPointer					;控制发射的子弹元素
	cmp bulletPointer,BULLET_MAX_NUM
	jne fireEnd
	mov bulletPointer,0
	jmp short fireEnd
hit1:	call message
	
fireEnd:
	ret
fire endp
;-------------------------------------------------------



;子弹飞行，参数bx
;-------------------------------------------------------
bulletFlight proc
	mov ax,bulletFactor[bx]
	cmp ah,1					;子弹是否存在
	jne bflightd
	cmp al,BULLET_FLIGHT_INTERVAL
	jne flightNext

	mov dl,BULLET_WIDTH
	mov dh,BULLET_HEIGHT
	push si
	mov si,bulletReplaceUnit[bx]
	mov di,bulletX[bx]
	clearPicture bulletY[bx],dx
	pop si
	
	xor al,al		;重置子弹飞行因子
	cmp bulletY[bx],BORDER_TOP
	je BFlimit
	dec bulletY[bx]
	
	;取中心坐标
	push ax
	mov ax,bulletX[bx]
	add ax,BULLET_WIDTH / 2
	mov bulletCoreX[bx],ax
	mov dx,bulletY[bx]
	add dx,BULLET_HEIGHT / 2
	mov bulletCoreY[bx],dx
	
	push bx
	mov di,1
	mov bl,0
	mov bh,2	;2表示子弹
	call fighterCollisionResponse		;战机子弹碰撞响应
	pop bx
	pop ax
	cmp di,0
	je hit2
	
	mov dl,BULLET_WIDTH
	mov dh,BULLET_HEIGHT
	push bx
	push si
	lea si,bulletBmp
	mov di,bulletX[bx]
	push dx
	push bulletY[bx]
	mov bx,bulletReplaceUnit[bx]
	call outputPicture
	pop si
	pop bx
	
	jmp short flightNext
hit2: call message	
BFlimit:	xor ah,ah	;销毁子弹
	jmp short bflightd
flightNext:	inc al
bflightd:	mov bulletFactor[bx],ax
	ret
bulletFlight endp
;-------------------------------------------------------

;战机恢复程序
;-------------------------------------------------------
fighterRecovery proc far
	push ax
	push bx
	push cx
	push dx
	push si
	push di
	push ds
	
	mov ax,data
	mov ds,ax
	
	xor bx,bx
	mov dl,BULLET_WIDTH
	mov dh,BULLET_HEIGHT
	mov cx,BULLET_MAX_NUM
	lea si,bulletBmp
recovery:	mov ax,bulletFactor[bx]
	cmp ah,0
	je	recoveryNext
	push bx
	mov di,bulletX[bx]
	push dx
	push bulletY[bx]
	mov bx,bulletReplaceUnit[bx]
	call outputPicture
	pop bx
	
recoveryNext:	add bx,2
	loop recovery
	
	pop ds
	pop di
	pop si
	pop dx
	pop cx
	pop bx
	pop ax
	ret
fighterRecovery endp
;-------------------------------------------------------


code ends
;++++++++++++++++++++++++++++++++++++++++++++++++++++
end