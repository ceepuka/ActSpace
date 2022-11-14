public mainMenu
extrn fighterHealth:word
;主菜单选项，能够修改
OPTION_TOP equ 12		;顶部选项（行）
OPTION_BOTTOM equ 16	;底部选项（行）
;######################################################	
ShowMenuBar macro head,pageColour,len,row,col
	;使用前需要传递参数：es（字符串段地址），ax=1300H
	lea bp,head 		;显示标题，字符串偏移地址
	mov bx,pageColour	;显示页和颜色，只需颜色值默认0页即可
	mov cx,len		;标题字符串长度
	mov dh,row		;显示行位置
	mov dl,col		;显示列位置
	int 10H
	endm
;######################################################	

;++++++++++++++++++++++++++++++++++++++++++++++++++++
data segment
;主菜单界面
headline DB 'ACT  SPACE'	;10 B，在4行15列开始显示
menuOption1 DB 'Continue'	;8 B，12行16列
menuOption2 DB 'Start'		;5 B，13行18列
menuOption3 DB 'Help'		;4 B，14行18列
menuOption4 DB 'Record'		;6 B，15行17列
menuOption5 DB 'Exit'		;4 B，16行18列
top DB OPTION_TOP
currentRow DB OPTION_TOP + 1	;初始化当前行
data ends
;++++++++++++++++++++++++++++++++++++++++++++++++++++

menuCode segment
assume cs:menuCode,ds:data

mainMenu proc far	;返回选定的选项
	mov ax,01H	;设置文本显示方式01H
	int 10H
	mov ah,1			;置光标类型
	mov cx,1000H		;隐藏光标
	int 10H
	
	mov ax,data
	mov ds,ax
	
	push ds
	mov ax,seg fighterHealth
	mov ds,ax
	cmp fighterHealth,0
	pop ds
	jne direct
	inc top
	
direct:	mov ax,data
	mov es,ax
	mov ax,1300H	;显示字符串，方式0
	;显示游戏标题
	ShowMenuBar headline,4H,10,4,15
	cmp top,13
	je option2
	;显示选项1
	ShowMenuBar menuOption1,7H,8,12,16
	;显示选项2
option2:	ShowMenuBar menuOption2,7H,5,13,18
	;显示选项3
	ShowMenuBar menuOption3,7H,4,14,18
	
	ShowMenuBar menuOption4,7H,6,15,17
	
	ShowMenuBar menuOption5,7H,4,16,18
	
	mov al,top
	mov currentRow,al	;设置当前行
	call indicateRow		;切换行属性
	
	;按上、下方向键选择
userSelect: mov ah,0
	int 16H
	cmp ah,1CH
	je confirm		;回车键为确认
	cmp ah,48H
	je moveUp
	cmp ah,50H
	je moveDn
	jmp short userSelect

moveUp: call moveUpward
	jmp short userSelect
moveDn: call moveDown
	jmp short userSelect
	
;确认选项
confirm:
	xor bh,bh
	mov bl,currentRow
	sub bl,OPTION_TOP
	shl bx,1			;该模块向调用者返回一个参数bx
	mov top,OPTION_TOP	;准备继续选项
	ret
mainMenu endp

;当前指示行，倒置切换行属性，切换两次即还原
;-------------------------------------------------------
indicateRow proc
	push ax
	push bx
	push cx
	push es
	;参数：currentRow
	mov ax,0B800H
	mov es,ax
	mov al,currentRow
	mov bl,80
	mul bl
	mov bx,ax
	
	mov ah,01111111B
	mov cx,40
indicate:	xor es:[bx + 1],ah
	add bx,2
	loop indicate
	
	;返回：无
	pop es
	pop cx
	pop bx
	pop ax
	ret
indicateRow endp
;-------------------------------------------------------

;向上选择
;-------------------------------------------------------
moveUpward proc
	call indicateRow		;首先恢复原行
	;参数：currentRow
	mov al,currentRow
	cmp al,top
	je optionTop		;是顶部选项则转移
	dec currentRow		;上移则减行
	jmp short mUpNext
optionTop:	mov currentRow,OPTION_BOTTOM	;由顶部转到底部
mUpNext:
	call indicateRow
	ret
moveUpward endp
;-------------------------------------------------------

;向下选择
;-------------------------------------------------------
moveDown proc
	call indicateRow		;首先恢复原行
	;参数：currentRow
	cmp currentRow,OPTION_BOTTOM
	je optionBot		;是底部选项则转移
	inc currentRow		;下移则增行
	jmp short mDnNext
optionBot:	mov al,top
	mov currentRow,al	;由底部转到顶部
mDnNext:
	call indicateRow
	ret
moveDown endp
;-------------------------------------------------------

menuCode ends
end