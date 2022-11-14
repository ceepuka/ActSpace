public actionFoes,clearEnemy,fighterCollisionResponse,enemyRecovery,scoutFighterBmp,fightFighterBmp,eliteFighterBmp,ebullet1Bmp,ebullet2Bmp,ebullet3Bmp
public enemy,foep,ebullet,enemyFactor,loadOrder,tempTimes				;初值由初始化过程决定
;public foesfileHandle, enemyFuncTestFile, letterSequence	;测试用
public enemyCoreX,enemyCoreY,enemyRc,enemy,foep
public ebulletCoreX,ebulletCoreY
extrn outputPicture:far, clear:far, cutPicture:far, collision:far, efighterCollisionResponse:far, detonate:far,explosion:far
extrn fighterCoreX:word, fighterCoreY:word, fighterRc:byte, fighterHealth:word
extrn bulletCoreX:word, bulletCoreY:word
include gamePara

Axis_Of_Symmetry equ (RIGHT_BORDER + 1) / 2	;并列出敌对称轴
;以下是有关敌人的参数定义
;所有敌机参数必须在255以内

;敌机类别
SCOUTF equ 0		;侦察机
EFIGHTER equ 1		;战斗机
EliteFIG equ 2		;精英战机

;侦察机参数
SCOUTF_WIDTH equ 9
SCOUTF_HEIGHT equ 10
SCOUTF_FLIGHT_INTERVAL equ 8	;侦察机飞行间隔，8个延时单元
SCOUTF_CREATE_INTERVAL equ 160	;侦察机生成间隔

;战斗机参数
EFIGHTER_WIDTH equ 9
EFIGHTER_HEIGHT equ 10
EFIGHTER_FLIGHT_INTERVAL equ 8		;战斗机飞行间隔，8个延时单元
EFIGHTER_CREATE_INTERVAL equ 160	;战斗机生成间隔

;精英战机参数
EliteFIG_WIDTH equ 21
EliteFIG_HEIGHT equ 18
EliteFIG_FLIGHT_INTERVAL equ 10		;飞行移动间隔
EliteFIG_CREATE_INTERVAL equ 200	;生成间隔

;以下是敌机子弹的参数定义


;敌机子弹类别,用0表示不攻击
BULLET1 equ 1
BULLET2 equ 2
BULLET3 equ 3

;子弹1，普通
BULLET1_WIDTH equ 3
BULLET1_HEIGHT equ 3
BULLET1_FLIGHT_INTERVAL equ 4		;飞行间隔
BULLET1_CREATE_INTERVAL equ 600	;生成间隔
;子弹2，速度极快
BULLET2_WIDTH equ 3
BULLET2_HEIGHT equ 6
BULLET2_FLIGHT_INTERVAL equ 2		;飞行间隔
BULLET2_CREATE_INTERVAL equ 400		;生成间隔
;子弹3，追踪
BULLET3_WIDTH equ 5
BULLET3_HEIGHT equ 5
BULLET3_FLIGHT_INTERVAL equ 6		;飞行间隔
BULLET3_CREATE_INTERVAL equ 800	;生成间隔



;++++++++++++++++++++++++++++++++++++++++++++++++++++
data segment
;定义敌机，侦察机与战斗机共用数组
;**********************************************************

;敌机数组
enemyX dw FOES dup (?)
enemyY dw FOES dup (?)
;
enemyCoreX dw FOES dup (?)
enemyCoreY dw FOES dup (?)
enemyRc	db FOES dup (0)		;碰撞半径
enemy dw FOES dup (0)				;低字节：敌机类别；高字节：敌机存在状态，0空,1存在并隐藏,2存在并显示,3显示裁剪的图像
foep dw 0							;记录当前存在敌机数
foeFlightFactor dw FOES dup (0)		;敌机飞行因子,高字节：敌机的飞行间隔
;xyMove dw FOES dup (?)				;敌机飞行增量，低字节：X，高字节：Y
xMove dw FOES dup (?)			;敌机飞行X增量
yMove dw FOES dup (?)			;敌机飞行Y增量
ebulletFactor dw FOES dup (0)		;敌机子弹发射因子
ebulletp dw FOES dup (?)			;攻击方式传递敌机子弹类别
;裁剪的图像参数
etrimX dw FOES dup (?)				;横坐标
etrimY dw FOES dup (?)				;纵坐标
etrimWH dw FOES dup (?)				;宽度高度

enemyImage dw offset scoutFighterBmp, offset fightFighterBmp, offset eliteFighterBmp	;相应类别敌机图像
;敌机图像替补块
enemyReplaceUnit label word
x = offset enemyReplaceBlock
	rept FOES
	dw x
x = x + EliteFIG_WIDTH * EliteFIG_HEIGHT
endm
enemyReplaceBlock db FOES * EliteFIG_WIDTH * EliteFIG_HEIGHT dup (?)	;这里宽度×高度必须是敌机中最大的

;敌机子弹
;**********************************************************
ebulletX dw EBULLETS dup (?)
ebulletY dw EBULLETS dup (?)
;
ebulletCoreX dw EBULLETS dup (?)
ebulletCoreY dw EBULLETS dup (?)
ebullet dw EBULLETS dup (0)		;低字节：子弹类别；高字节：存在状态，存在为1，空为0
;ebulletNum dw 0					;记录当前存在敌机子弹数
ebulletFlightFactor dw EBULLETS dup (0) ;敌机子弹飞行因子,高字节：敌机子弹的飞行间隔

ebulletImage dw 0, offset ebullet1Bmp, offset ebullet2Bmp, offset ebullet3Bmp	;敌机子弹图像
;敌机子弹图像替补块
ebulletReplaceUnit label word
x = offset ebulletReplaceBlock
	rept EBULLETS
	dw x
x = x + BULLET3_WIDTH * BULLET3_HEIGHT
endm
ebulletReplaceBlock db EBULLETS * BULLET3_WIDTH * BULLET3_HEIGHT dup (?)	;这里宽度×高度必须是敌机子弹中最大的



;第一个元素保留不用，第二个元素开始有效
ebulletCycle dw 0,BULLET1_CREATE_INTERVAL,BULLET2_CREATE_INTERVAL,BULLET3_CREATE_INTERVAL


;出敌规律测试
;,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,
;foesfileHandle dw ?	;暂存文件句柄
;enemyFuncTestFile db 'C:\ActSpace\foestest.txt',0
;db 'C:\ActSpace\foestest.txt',0
;letterSequence db ? ;字母记录序列
;db 0
;aRound db 'ok'		;完成一轮出敌
;,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,

;以敌机类别为索引
enemyCycle db SCOUTF_CREATE_INTERVAL, EFIGHTER_CREATE_INTERVAL, EliteFIG_CREATE_INTERVAL	;敌机生成周期，用于生成相应类别的敌机
foeCycle db SCOUTF_FLIGHT_INTERVAL, EFIGHTER_FLIGHT_INTERVAL, EliteFIG_FLIGHT_INTERVAL	;相应类别敌机的飞行间隔
enemyWidth db SCOUTF_WIDTH, EFIGHTER_WIDTH, EliteFIG_WIDTH						;相应类别敌机的宽度
enemyHeight db SCOUTF_HEIGHT, EFIGHTER_HEIGHT, EliteFIG_HEIGHT					;相应类别敌机的高度

;敌机子弹
mbulletCycle db 0,BULLET1_FLIGHT_INTERVAL,BULLET2_FLIGHT_INTERVAL,BULLET3_FLIGHT_INTERVAL
ebulletWidth db 0,BULLET1_WIDTH,BULLET2_WIDTH,BULLET3_WIDTH
ebulletHeight db 0,BULLET1_HEIGHT,BULLET2_HEIGHT,BULLET3_HEIGHT

enemyFactor db 0					;敌机因子，用于生成相应类别的敌机
foe db 0							;生成的敌机的类别
;出敌规律
loadOrder db 0						;敌机加载序号
tempTimes db 0						;临时存放每波出敌剩余次数
tempX dw ?							;临时存放x坐标，以将最终的x坐标传递给生成的敌机
;positionX应在-30~270之间
positionX dw 60, 	171, 	90, 	0,			230,		50,		0
increment dw 0, 	0, 		0, 		0,			0,			10,		15
eachLoadTimes db 6, 6, 		4, 		8,			8,			5,		4,     0	;每波出敌次数，须以0标记结尾
;并排以左为基准
juxtaposition db 1, 1, 		2, 		1,			1,			2,		2
category db SCOUTF, SCOUTF, SCOUTF, EFIGHTER, EFIGHTER, EliteFIG, EliteFIG
xWay db 0,			0,		0,		1,			-1,			0,		0
yWay db 1,			1,		1,		1,			1,			1,		1
attack db 0,		0,		0,		BULLET1,	BULLET1, BULLET2, BULLET3					;攻击方式，0不攻击，非0发射相应的子弹


;**********************************************************
;侦察机图像
scoutFighterBmp db 0,43,43, 43,0,43, 43,43,0
				db 0,0,0, 43,43,43, 0,0,0
				db 0,0,0, 43,14,43, 0,0,0
				db 0,0,43, 43,14,43, 43,0,0
				db 43,43,43, 14,14,14, 43,43,43
				db 0,0,43, 43,14,43, 43,0,0
				db 0,0,0, 43,14,43, 0,0,0
				db 0,0,0, 43,43,43, 0,0,0
				db 0,0,0, 0,43,0, 0,0,0
				db 0,0,0, 0,43,0, 0,0,0
;
fightFighterBmp db 48,48,48, 0,0,0, 48,48,48
				db 0,0,48, 48,48,48, 48,0,0
				db 0,0,0, 48,68,48, 0,0,0
				db 0,0,48, 66,68,66, 48,0,0
				db 48,48,66, 68,68,68, 66,48,48
				db 0,48,66, 66,68,66, 66,48,0
				db 0,0,48, 68,40,68, 48,0,0
				db 0,0,0, 48,40,48, 0,0,0
				db 0,0,0, 48,48,48, 0,0,0
				db 0,0,0, 0,48,0, 0,0,0
;
eliteFighterBmp db 0,0,0, 13,13,0, 0,0,0, 0,0,0, 0,0,0, 0,13,13, 0,0,0
				db 0,0,0, 0,13,13, 0,0,0, 40,40,40, 0,0,0, 13,13,0, 0,0,0
				db 102,0,0, 0,0,13, 13,0,40, 40,40,40, 40,0,13, 13,0,0, 0,0,102
				db 48,102,48, 0,0,0, 102,13,13, 13,13,13, 13,13,102, 0,0,0, 48,102,48
				db 102,48,48, 48,0,0, 0,102,13, 13,13,13, 13,102,0, 0,0,48,48, 48,102
				db 0,48,48, 48,13,13, 13,13,13, 13,13,13, 13,13,13,13, 13,48,48, 48,0
				db 0,48,48, 48,13,13, 13,13,13, 13,13,13, 13,13,13,13, 13,48,48, 48,0
				db 0,48,48, 48,0,0, 0,102,13, 13,13,13, 13,102,0, 0,0,48,48, 48,0
				db 0,48,48, 48,0,0, 0,102,13, 13,13,13, 13,102,0, 0,0,48,48, 48,0
				db 0,48,48, 48,0,0, 0,102,13, 13,13,13, 13,102,0, 0,0,48,48, 48,0
				db 0,48,48, 48,0,0, 0,102,13, 13,13,13, 13,102,0, 0,0,48,48, 48,0
				db 0,48,48, 48,13,13, 13,13,13, 13,13,13, 13,13,13,13, 13,48,48, 48,0
				db 0,48,48, 48,13,13, 13,13,13, 13,13,13, 13,13,13,13, 13,48,48, 48,0
				db 0,102,48, 48,0,0, 0,102,43, 43,43,43, 43,102,0, 0,0,48,48, 102,0
				db 0,0,48, 0,0,0, 0,0,13, 43,43,43, 13,0,0, 0,0,0, 48,0,0
				db 0,0,102, 0,0,0, 0,0,0, 13,43,13, 0,0,0, 0,0,0, 102,0,0
				db 0,0,0, 0,0,0, 0,0,0, 13,13,13, 0,0,0, 0,0,0, 0,0,0
				db 0,0,0, 0,0,0, 0,0,0, 0,13,0, 0,0,0, 0,0,0, 0,0,0
;
;**********************************************************
ebullet1Bmp db 0,30,0
			db 30,31,30
			db 0,30,0
;
ebullet2Bmp	db 0,108,0
			db 108,35,108
			db 58,35,58
			db 58,35,58
			db 59,35,59
			db 0,59,0
;
ebullet3Bmp db 0,0,68,0,0
			db 0,66,35,66,0
			db 68,35,40,35,68
			db 0,66,35,66,0
			db 0,0,68,0,0




data ends
;++++++++++++++++++++++++++++++++++++++++++++++++++++

;++++++++++++++++++++++++++++++++++++++++++++++++++++
code segment
assume cs:code,ds:data
;敌机动作过程
;-------------------------------------------------------
actionFoes proc far
	push ds
	push ax
	push bx
	push cx
	push dx
	push si
	push di
	
	mov ax,data
	mov ds,ax
	
	cmp enemyFactor,0	;以0作为开始条件便于程序的编写
	jne createNd
	
	cmp tempTimes,0
	jne foeLoading
	xor bx,bx
	mov bl,loadOrder
	cmp eachLoadTimes[bx],0	;取每波出敌次数，并判断是否结尾
	jne eachWaveInit
	mov loadOrder,0
	mov bl,loadOrder
	
	;检测并写入测试结果
;	push bx
;	mov ah,40H
;	mov bx,foesfileHandle
;	mov cx,2
;	lea dx,aRound
;	int 21H
;	pop bx
	
	jmp short eachWaveInit
createNd:	jmp short created
	
eachWaveInit:	mov al,eachLoadTimes[bx]	;每波敌机初始化
	mov tempTimes,al
	shl bx,1
	mov ax,positionX[bx]
	mov tempX,ax
	
foeLoading:	xor bx,bx
	mov bl,loadOrder
	cmp juxtaposition[bx], 1	;判断同时出敌的数量，同时出多个敌人则要通过计算位置差以确定各出敌位置
	jna enemyLoading
	;计算并列出敌位置差值
	mov ax, Axis_Of_Symmetry
	sub ax, tempX
	push bx
	mov bl, category[bx]
	mov cl, enemyWidth[bx]
	xor ch,ch
	pop bx
	shr cx,1
	sub ax,cx
	;xor ah,ah
	shl ax,1
	mov ch,juxtaposition[bx]
	dec ch
	div ch
	xor ah,ah
	;ax为最终的差值
	
enemyLoading: 
	mov cx,FOES
	sub cx,foep	;取敌机生成空位数
	cmp juxtaposition[bx],cl
	ja created
	
	mov cl, juxtaposition[bx]
abreast: call enemyCreate		;生成敌机
	loop abreast
	
	dec tempTimes
	cmp tempTimes,0
	je nextWave
	shl bx,1
	mov ax,increment[bx]
	add tempX,ax			;添加下一组敌人的位置增量
	jmp short created
nextWave: inc loadOrder		;指向下一波敌人
	
created:inc enemyFactor
	xor bx,bx
	mov bl,foe
	mov al,enemyFactor	;不同的敌机与各自的参数比较
	cmp al,enemyCycle[bx]
	jb enemyMotion
	mov enemyFactor,0
	
enemyMotion: call enemyMovement;敌机运动
	call ebulletDeal;敌机子弹处理
	
	pop di
	pop si
	pop dx
	pop cx
	pop bx
	pop ax
	pop ds
	ret
	
actionFoes endp
;-------------------------------------------------------

;敌机图像清除子程序
;参数：bx传递战机类别及显示方式,si传递敌机索引
;-------------------------------------------------------
clearEnemy proc far
	cmp bh,1	;存在并显示时需要清除原图
	je enemyCleared
	push ax
	push bx
	push dx
	push si
	push di
	
	push ds
	mov ax,data
	mov ds,ax
	
	cmp bh,3	;擦除裁剪的图像
	je clearetrimBmp
	xor bh,bh
	mov di,enemyX[si]
	mov ax,enemyY[si]
	mov dl,enemyWidth[bx]
	mov dh,enemyHeight[bx]
	jmp short clearenemyPicture
	
clearetrimBmp:	xor bh,bh
	mov di,etrimX[si]
	mov ax,etrimY[si]
	mov dx,etrimWH[si]
clearenemyPicture:	mov si,enemyReplaceUnit[si]
	clearPicture ax,dx
	pop ds
	
	pop di
	pop si
	pop dx
	pop bx
	pop ax
	
enemyCleared: ret
clearEnemy endp


;敌机生成过程
;参数：ax传递差值，bx传递序号
;cl和juxtaposition[bx]不等时传递差值
;-------------------------------------------------------
enemyCreate proc
	push cx
	xor si,si
	mov cx,FOES
vacancyCheck:	mov dx,enemy[si]
	cmp dh,0
	je enemyDispose
	add si,2
	loop vacancyCheck
	
enemyDispose:	pop cx		;确保必定进行这一步
	mov dl,category[bx]	;置敌机类别
	mov foe,dl			;保存生成的敌机的类别
	mov dh,1				;置敌机状态为存在并隐藏
	mov enemy[si],dx
	;置Y坐标
	xor dh,dh
	mov di,dx
	or dh,0FFH				;拓展为16位符号数
	xor dl,dl
	sub dl,enemyHeight[di]
	mov enemyY[si],dx
	
	;置X坐标
	mov dx,tempX
	cmp cl, juxtaposition[bx]
	je transmitPosX
	add dx,ax
	shl ax,1
transmitPosX:	mov enemyX[si],dx
	
	;检测并写入测试结果
;	push ax
;	push bx
;	push cx
;	mov ax,foep
;	add al,'A'
;	mov letterSequence,al
;	mov ah,40H
;	mov bx,foesfileHandle
;	mov cx,1
;	lea dx,letterSequence
;	int 21H
;	pop cx
;	pop bx
;	pop ax
	
	;置飞行参数
	mov dh,foeCycle[di]
	xor dl,dl
	mov foeFlightFactor[si],dx
	
	;置飞行增量方式
	mov dl,xWay[bx]
	cmp dl,0
	jl signX
	xor dh,dh
	jmp short setX
signX:	or dh,0FFH				;拓展为16位符号数
setX:	mov xMove[si],dx
	
	mov dl,yWay[bx]
	cmp dl,0
	jl signY
	xor dh,dh
	jmp short setY
signY:	or dh,0FFH				;拓展为16位符号数
setY:	mov yMove[si],dx
	
	;敌机子弹发射因子置0
	mov ebulletFactor[si],0
	;置敌机攻击方式
	xor dh,dh
	mov dl,attack[bx]
	mov ebulletp[si],dx
	
	push ax
	;取中心坐标和碰撞半径
	xor dx,dx
	mov dl,enemyWidth[di]
	shr dl,1
	mov al,dl
	add dx,enemyX[si]
	mov enemyCoreX[si],dx
	xor dx,dx
	mov dl,enemyHeight[di]
	shr dl,1
	add al,dl
	add dx,enemyY[si]
	mov enemyCoreY[si],dx
	inc al
	shr al,1
	shr si,1
	mov enemyRc[si],al
	shl si,1
	pop ax
	
	inc foep	;当前敌机数＋1
	ret
enemyCreate endp
;-------------------------------------------------------

;战机碰撞响应过程,由战机调用
;参数ax,dx传递中心坐标，bl碰撞半径，bh战机为1，子弹为2，di存在参数,返回di
;-------------------------------------------------------
fighterCollisionResponse proc far
	push cx
	push si
	push ds
	
	push bx
	mov bx,data
	mov ds,bx			;置敌机段
	pop bx
	xor si,si
	mov cx,FOES
seekEnemy:	push ax
	push dx
	
	push bx
	mov bx,enemy[si]
	cmp bh,0
	pop bx
	je enemyNext
	
	;传递中心坐标
	push dx
	push ax
	
;	push si
;	add si,offset enemyCoreY
;	mov dx,[si]
;	pop si
	push enemyCoreY[si]
	push enemyCoreX[si]
	;传递碰撞半径
	mov dl,bl
	shr si,1
	mov dh,enemyRc[si]
	shl si,1
	
	;检测并写入测试结果
;	push ax
;	push bx
;	push cx
;	push dx
	;mov ax,si
;	mov al,dh
;	add al,'A'
;	mov letterSequence,al
;	mov ah,40H
;	mov bx,foesfileHandle
;	mov cx,1
;	lea dx,letterSequence
;	int 21H
;	pop dx
;	pop cx
;	pop bx
;	pop ax
	
	call collision
	
	cmp ax,1
	jne enemyNext
	dec di
	push bx
	mov bx,enemy[si]
	call clearEnemy
	pop bx
	mov enemy[si],0	;销毁敌机
	dec foep	;将敌机数减1
	
	push enemyCoreY[si]
	push enemyCoreX[si]
	call detonate			;显示爆炸效果
	
enemyNext:	add si,2
	pop dx
	pop ax
	cmp di,0
	je seeked
	loop seekEnemy
	
	cmp bh,1
	jne seeked
	xor si,si
	mov cx,EBULLETS
seekEbullet:	push ax
	push dx
	
	push bx
	mov bx,ebullet[si]
	cmp bh,0
	pop bx
	je ebulletNext
	
	
	;传递中心坐标
	push dx
	push ax
	push ebulletCoreY[si]
	push ebulletCoreX[si]
	;传递碰撞半径
	mov dl,bl
	xor dh,dh
	call collision
	
	cmp ax,1
	jne ebulletNext
	dec di
	push bx
	mov bx,ebullet[si]
	call clearEbullet
	pop bx
	mov ebullet[si],0	;销毁敌机子弹
	
ebulletNext:	add si,2
	pop dx
	pop ax
	cmp di,0
	je seeked
	loop seekEbullet
	
seeked:	
	pop ds
	pop si
	pop cx
	ret
fighterCollisionResponse endp
;-------------------------------------------------------


;敌机运动处理
;-------------------------------------------------------
enemyMovement proc
	xor si,si
	mov cx,FOES
	
enemyFlight: mov bx,enemy[si]
	cmp bh,0
	je enemyMoved
	mov ax,foeFlightFactor[si]
	cmp al,ah
	jne enemyMoveNext
	xor al,al
	
	cmp bh,1	;存在并显示时需要清除原图
	je enemyFlying
	push ax
	push bx
	push si
	
	cmp bh,3	;擦除裁剪的图像
	je clearetrim
	xor bh,bh
	mov di,enemyX[si]
	mov ax,enemyY[si]
	mov dl,enemyWidth[bx]
	mov dh,enemyHeight[bx]
	jmp short clearenemyPic
	
clearetrim:	xor bh,bh
	mov di,etrimX[si]
	mov ax,etrimY[si]
	mov dx,etrimWH[si]
clearenemyPic:	mov si,enemyReplaceUnit[si]
	clearPicture ax,dx
	pop si
	pop bx
	pop ax
	
enemyFlying: call enemyFlyMode
	
enemyMoveNext:	inc al
	mov foeFlightFactor[si],ax	;敌机完成一次移动
	
	mov bx,ebulletp[si]	;取敌机攻击方式
	cmp bl,0
	je enemyMoved		;noAttack
	
	;mov ax,EBULLETS
	;sub ax,ebulletNum		;取可生成敌机子弹的空位数
	;cmp al,1
	;jb enemyMoved		;vacancyLess
	
	call ebulletFire	;该敌机子弹发射处理
enemyMoved:	add si,2
	push ds
	mov ax,seg fighterHealth
	mov ds,ax
	cmp fighterHealth,0
	pop ds
	je enemyEnd
	loop enemyFlight
	
enemyEnd:	ret
enemyMovement endp
;-------------------------------------------------------

;敌机飞行方式
;参数bx,si
;-------------------------------------------------------
enemyFlyMode proc
	push ax
	
	mov dx,yMove[si]
	add enemyY[si],dx
	cmp enemyY[si], BORDER_BOTTOM
	jg Deprecated			;超出底部则弃用
	
	mov dx,xMove[si]
	add enemyX[si],dx
	
	;取中心坐标
	xor bh,bh
	xor ax,ax
	mov al,enemyWidth[bx]
	shr al,1
	add ax,enemyX[si]
	mov enemyCoreX[si],ax
	xor dx,dx
	mov dl,enemyHeight[bx]
	shr dl,1
	add dx,enemyY[si]
	mov enemyCoreY[si],dx
	
	push bx
	mov bl,enemyRc[si]
	mov di,1
	call efighterCollisionResponse	;敌机碰撞响应
	pop bx
	cmp di,0
	jne enemyShow
	push enemyCoreY[si]
	push enemyCoreX[si]
	call detonate
	jmp short Deprecated
	
enemyShow:	
	cmp enemyX[si], RIGHT_BORDER
	jg shelter
	
	
	mov dl,enemyWidth[bx]
	dec dl
	xor dh,dh
	add dx,enemyX[si]
	cmp dx,LEFT_BORDER
	jl shelter
	
	xor ah,ah
	mov al,enemyHeight[bx]
	dec al
	add ax,enemyY[si]
	cmp ax,BORDER_TOP
	jl shelter
	jmp short showEnemys
	
Deprecated:	xor bh,bh
	dec foep			;当前敌机数-1
	jmp flyed

shelter:	mov bh,1
	jmp flyed
	
showEnemys:	cmp ax,BORDER_BOTTOM
	jg cut
	cmp dx,RIGHT_BORDER
	jg cut
	cmp enemyY[si], BORDER_TOP
	jl cut
	cmp enemyX[si], LEFT_BORDER
	jl cut
	push bx
	push si
	mov al,enemyWidth[bx]
	mov ah,enemyHeight[bx]
	mov di,enemyX[si]
	mov dx,enemyY[si]
	push cx
	mov cx,enemyReplaceUnit[si]
	shl bx,1
	mov si,enemyImage[bx]
	mov bx,cx
	pop cx
	displayIMG dx,ax
	pop si
	pop bx
	mov bh,2
	jmp short flyed
	
cut: push bx
	push si
	mov al,enemyWidth[bx]
	mov ah,enemyHeight[bx]
	mov di,enemyX[si]
	mov dx,enemyY[si]
	push cx
	mov cx,enemyReplaceUnit[si]
	shl bx,1
	mov si,enemyImage[bx]
	mov bx,cx
	pop cx
	
	trimPicture di,dx,ax
	push di
	mov si,bx
	displayIMG dx,ax
	pop di
	
	pop si
	pop bx
	mov etrimX[si],di
	mov etrimY[si],dx
	mov etrimWH[si],ax
	
	mov bh,3
flyed:	mov enemy[si],bx
	pop ax
	ret
enemyFlyMode endp
;-------------------------------------------------------

;敌机发射子弹处理过程
;参数：si敌机元素,bx传递子弹类别
;-------------------------------------------------------
ebulletFire proc
	
	cmp ebulletFactor[si],0	;为0时发射子弹
	je isfire
	jmp fired
isfire:	push cx
	xor di,di
	mov cx,EBULLETS
vacancy:	mov dx,ebullet[di]
	cmp dh,0
	je fire
	add di,2
	loop vacancy
	pop cx
	
	;call check
	
	jmp fireNext	;无空位
	
fire:	pop cx
	
	push bx
	mov bx,enemy[si]
	xor bh,bh
	mov dl,enemyHeight[bx]
	pop bx
	mov ax,enemyY[si]
	add ax,dx
	cmp ax,BORDER_TOP
	jnl fireForY
	jmp fireNext
fireForY:	mov dl,ebulletHeight[bx]
	add dx,ax
	cmp dx,BORDER_BOTTOM + 1
	jg fireNext
	mov ebulletY[di],ax	;y
	
	push bx
	mov bx,enemy[si]
	xor bh,bh
	mov dl,enemyWidth[bx]
	pop bx
	sub dl,ebulletWidth[bx]
	shr dl,1
	mov ax,enemyX[si]
	xor dh,dh
	add ax,dx
	cmp ax,LEFT_BORDER
	jl fireNext
	mov dl,ebulletWidth[bx]
	add dx,ax
	cmp dx,RIGHT_BORDER + 1
	jg fireNext
	mov ebulletX[di],ax	;x
	
	;取中心坐标
	mov dl,ebulletWidth[bx]
	xor dh,dh
	shr dl,1
	add ax,dx
	mov ebulletCoreX[di],ax
	mov dl,ebulletHeight[bx]
	shr dl,1
	add dx,ebulletY[di]
	mov ebulletCoreY[di],dx
	
	push di
	push bx
	mov bl,0
	mov di,1
	call efighterCollisionResponse	;敌机碰撞响应
	pop bx
	cmp di,0
	pop di
	je fireNext
	
	call firing
	
fired:	inc ebulletFactor[si]	;发射周期处理及判定
	shl bx,1
	mov ax,ebulletCycle[bx]
	cmp ebulletFactor[si],ax
	jb fireNext
	mov ebulletFactor[si],0
	
fireNext:
	ret
	
firing:
	push bx
	push si
	push di
	mov al,ebulletWidth[bx]
	mov ah,ebulletHeight[bx]
	push ax	;传递图片尺寸
	push ebulletY[di]	;传递纵坐标
	shl bx,1
	mov si,ebulletImage[bx]
	mov bx,ebulletReplaceUnit[di]
	mov di,ebulletX[di]
	call outputPicture
	pop di
	pop si
	pop bx
	
	;检测并写入测试结果
;	push bx
;	push cx
;	mov ax,di
;	shr ax,1
;	add al,'A'
;	mov letterSequence,al
;	mov ah,40H
;	mov bx,foesfileHandle
;	mov cx,1
;	lea dx,letterSequence
;	int 21H
;	pop cx
;	pop bx
	
	mov ah,mbulletCycle[bx]
	xor al,al
	mov ebulletFlightFactor[di],ax
	
	mov bh,1
	mov ebullet[di],bx
	xor bh,bh
	ret
	
;check:	;检测并写入测试结果
;	push bx
;	push cx
;	mov ah,40H
;	mov bx,foesfileHandle
;	mov cx,2
;	lea dx,aRound
;	int 21H
;	pop cx
;	pop bx
;	ret
	
ebulletFire endp
;-------------------------------------------------------

;-------------------------------------------------------
clearEbullet proc
	push di
	push si
	xor bh,bh
	mov al,ebulletWidth[bx]
	mov ah,ebulletHeight[bx]
	mov di,ebulletX[si]
	push ax			;传递图片尺寸
	push ebulletY[si]	;传递纵坐标
	mov si,ebulletReplaceUnit[si]
	call clear			;首先清除原图
	pop si
	pop di
	
	ret
clearEbullet endp
;-------------------------------------------------------

;敌机子弹飞行、销毁
;-------------------------------------------------------
ebulletDeal proc
	mov si,0
	mov cx,EBULLETS

ebulletFlight:	push ds
	mov ax,seg fighterHealth
	mov ds,ax
	cmp fighterHealth,0
	pop ds
	je ebulletEnd
	mov bx,ebullet[si]
	cmp bh,0
	je ebulletMoved
	mov ax,ebulletFlightFactor[si]
	cmp al,ah
	jne ebulletMoveNext
	xor al,al
	
	call ebulletMode

ebulletMoveNext: inc al
	mov ebulletFlightFactor[si],ax
ebulletMoved: add si,2
	loop ebulletFlight

ebulletEnd:	ret
ebulletDeal endp
;-------------------------------------------------------

;敌机子弹飞行方式
;参数：ax,bl,si
;-------------------------------------------------------
ebulletMode proc
	push ax
	
	push si
	xor bh,bh
	mov al,ebulletWidth[bx]
	mov ah,ebulletHeight[bx]
	mov di,ebulletX[si]
	push ax			;传递图片尺寸
	push ebulletY[si]	;传递纵坐标
	mov si,ebulletReplaceUnit[si]
	call clear			;首先清除原图
	pop si
	
	mov dl,ah
	xor dh,dh
	add dx,ebulletY[si]
	cmp dx,BORDER_BOTTOM
	jna ebulletOk
	jmp ebulletDestroy
ebulletOk:	inc ebulletY[si]
	push bx
	
	cmp bl,BULLET3		;追踪判定
	jne moveN
	push ds
	mov ax,seg fighterCoreX
	mov ds,ax
	mov ax,fighterCoreX
	pop ds
	cmp ax,ebulletCoreX[si]
	je moveN
	cmp ax,ebulletCoreX[si]
	jb toleft
	inc ebulletX[si]
	jmp short moveN
toleft:	dec ebulletX[si]
moveN:	
	;取中心坐标
	xor ax,ax
	mov al,ebulletWidth[bx]
	shr al,1
	add ax,ebulletX[si]
	mov ebulletCoreX[si],ax
	xor dx,dx
	mov dl,ebulletHeight[bx]
	shr dl,1
	add dx,ebulletY[si]
	mov ebulletCoreY[si],dx
	
	push bx
	mov bl,0
	mov di,1
	call efighterCollisionResponse	;敌机碰撞响应
	pop bx
	cmp di,0
	je hit
	
	push si
	push di
	mov al,ebulletWidth[bx]
	mov ah,ebulletHeight[bx]
	push ax	;传递图片尺寸
	push ebulletY[si]	;传递纵坐标
	shl bx,1
	mov dx,ebulletReplaceUnit[si]
	mov di,ebulletX[si]
	mov si,ebulletImage[bx]
	mov bx,dx
	call outputPicture
	pop di
	pop si

hit:
	pop bx
	inc bh		;由0恢复为1
	cmp di,0
	je hited
ebulletDestroy:	mov ebullet[si],bx
	jmp short ebulletModend
hited:	mov ebullet[si],0
ebulletModend:	pop ax
	ret
ebulletMode endp
;-------------------------------------------------------

;敌机恢复程序
;-------------------------------------------------------
enemyRecovery proc far
	push ax
	push bx
	push cx
	push dx
	push si
	push di
	push ds
	
	mov ax,data
	mov ds,ax
	
	xor si,si
	mov cx,FOES
recoveryEnemy:	mov bx,enemy[si]
	push si
	cmp bh,2
	jb recoveryNextEnemy
	cmp bh,2
	jne recoveryCut
	
	xor bh,bh
	mov al,enemyWidth[bx]
	mov ah,enemyHeight[bx]
	mov di,enemyX[si]
	push ax
	push enemyY[si]
	mov dx,enemyReplaceUnit[si]
	shl bx,1
	mov si,enemyImage[bx]
	mov bx,dx
	call outputPicture
	jmp short recoveryNextEnemy
	
recoveryCut: xor bh,bh
	mov al,enemyWidth[bx]
	mov ah,enemyHeight[bx]
	push ax
	push enemyY[si]
	push enemyX[si]
	mov dx,enemyReplaceUnit[si]
	shl bx,1
	mov si,enemyImage[bx]
	mov bx,dx
	call cutPicture
	mov si,bx
	displayIMG dx,ax
	
recoveryNextEnemy:	pop si
	add si,2
	loop recoveryEnemy

	xor si,si
	mov cx,EBULLETS
recoveryEbullet:	mov bx,ebullet[si]
	push si
	cmp bh,0
	je recoveryNextEbullet
	
	xor bh,bh
	mov al,ebulletWidth[bx]
	mov ah,ebulletHeight[bx]
	push ax	;传递图片尺寸
	push ebulletY[si]	;传递纵坐标
	shl bx,1
	mov dx,ebulletReplaceUnit[si]
	mov di,ebulletX[si]
	mov si,ebulletImage[bx]
	mov bx,dx
	call outputPicture

recoveryNextEbullet: pop si
	add si,2
	loop recoveryEbullet
	
	pop ds
	pop di
	pop si
	pop dx
	pop cx
	pop bx
	pop ax
	ret
enemyRecovery endp
;-------------------------------------------------------

code ends
;++++++++++++++++++++++++++++++++++++++++++++++++++++
end