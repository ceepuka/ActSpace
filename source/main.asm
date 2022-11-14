extrn mainMenu:far, sceneLoading:far, keyboard:far, showFighter:far, actionFighter:far,explosion:far,destoryExplode:far
extrn actionFoes:far, initialize:far,setgameHelp:far,explainShow:far,recordio:far,recordOperation:far,gameRecord:far
extrn loadBMP:far
;extrn foesfileHandle:word, enemyFuncTestFile:byte	;测试用
extrn fighterHealth:word
FOES_CREATE_TIME_INIT equ 1000	;初始化出敌时间，1000个延时单元
;++++++++++++++++++++++++++++++++++++++++++++++++++++
stack segment STACK
	dw 2048 dup (?)
stack ends
;++++++++++++++++++++++++++++++++++++++++++++++++++++
data segment
	;主菜单各选项
	DW Continue,Start,Help,Gains,Exit
	;敌机初始化因子
foesInitFactor dw 1			;该变量为FOES_CREATE_TIME_INIT时开始出敌
	
data ends
;++++++++++++++++++++++++++++++++++++++++++++++++++++

;主代码段
;++++++++++++++++++++++++++++++++++++++++++++++++++++
mainCode segment
assume cs:mainCode,ds:data,ss:stack
main:
	mov ax,stack
	mov ss,ax
	mov sp,4096
	
	call loadBMP
	cmp si,0
	jne Exit
	
	call setgameHelp
	xor di,di		;读纪录文件
	call recordio
	
	push ds
	mov ax,seg fighterHealth
	mov ds,ax
	mov fighterHealth,0
	pop ds

menu:	
	call mainMenu	;返回bx，确定选项
	mov ax,data
	mov ds,ax
	jmp word ptr [bx]

Exit:
	mov di,1		;写纪录文件
	call recordio
	;关闭已打开的文件foestest.txt
;	mov ax,seg foesfileHandle
;	mov ds,ax
;	mov ah,3eH
;	mov bx,foesfileHandle
;	int 21H
	
	mov ax,3
	int 10H			;恢复初始显示方式
	mov ax,4C00H
	int 21H
	
Start:
	mov foesInitFactor,1
	call initialize
	;打开文件 foestest.txt
;	push ds
;	mov ax,seg foesfileHandle
;	mov ds,ax
;	mov ax,3d02H
;	lea dx,enemyFuncTestFile
;	int 21H
;	mov foesfileHandle,ax	;暂存文件句柄
;	pop ds
Continue:	
	call sceneLoading	;加载场景，以bx为参数判定恢复情况
	call showFighter		;显示战机
	
gameLoop:	call delay
	call keyboard	;返回al（比较用），bx（战机移动用）,ah=1移动
	cmp al,1		;esc
	je returnMainMenu

	call actionFighter
	push ds
	mov ax,seg fighterHealth
	mov ds,ax
	cmp fighterHealth,0
	pop ds
	je gameOver
	cmp foesInitFactor,FOES_CREATE_TIME_INIT
	je enemy
	inc foesInitFactor
	jmp short gameLoop
enemy: call actionFoes
	call explosion
	jmp short gameLoop
gameOver:	call recordOperation
returnMainMenu:	call destoryExplode
	jmp menu




Help:
	call explainShow
	jmp menu

;5毫秒延时单元
;-------------------------------------------------------
delay proc
	push ax
	push cx
	push dx
	
	;延时 0.005s
	mov al,0
	mov ah,86H
	mov cx,0
	mov dx,9C4H
	int 15H
	pop dx
	pop cx
	pop ax
	ret
delay endp
;-------------------------------------------------------

Gains:
	call gameRecord	;显示游戏纪录
	jmp menu

mainCode ends
;++++++++++++++++++++++++++++++++++++++++++++++++++++

end main