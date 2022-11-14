public initialize,information,showHP,message,detonate,explosion,destoryExplode,setgameHelp,explainShow,recordio,recordOperation,gameRecord,explodeBmp
extrn fighterHealth:word,fighterX:word,fighterY:word,fighterShiftFactor:byte,bulletFactor:word,bulletPointer:word,bulletFireFactor:byte,fighterCoreX:word,fighterCoreY:word	;引用战机
extrn enemy:word,foep:word,ebullet:word,enemyFactor:byte,loadOrder:byte,tempTimes:byte	;引用敌机
extrn outputPicture:far,clear:far

include gamePara

BLAST_WIDTH equ 8
BLAST_HEIGHT equ 8
BLAST_EXIST equ 50	;爆炸图持续存在50个延时单元
explainPage equ 1	;help选项内容显示页
explainLength equ 337

recordPage equ 2
recordLength equ 4 * 25	;4B，25行

;++++++++++++++++++++++++++++++++++++++++++++++++++++
data segment
explodeX dw FOES dup (?)
explodeY dw FOES dup (?)
explode dw FOES dup (?)		;低字节：存在时间因子，高字节：1存在

explodeBmp db 0,0,0,6, 6,0,0,0
		   db 0,6,6,43, 43,6,6,0
		   db 0,6,43,44, 44,43,6,0
		   db 6,43,44,15, 15,44,43,6
		   db 6,43,44,15, 15,44,43,6
		   db 0,6,43,44, 44,43,6,0
		   db 0,6,6,43, 43,6,6,0
		   db 0,0,0,6, 6,0,0,0

explodeReplaceBlock db FOES * BLAST_WIDTH * BLAST_HEIGHT dup (?)
explodeReplaceUnit label word
x = offset explodeReplaceBlock
	rept FOES
	dw x
x = x + BLAST_WIDTH * BLAST_HEIGHT
endm

handle dw ?		;暂存文件号（句柄）
explainPath db 64 dup (0)	;文件路径最大长度为63字节，且字符串以0结尾
explain db '\explain.txt'	;程序需要打开并进行读写的文件
explainNameLength equ $ - explain
explainBuffer db 1000 dup (?)			;文件内容缓冲区，最多1000B

recordPath db 64 dup (0)	;文件路径最大长度为63字节，且字符串以0结尾
recordName db '\record.txt'	;程序需要打开并进行读写的文件
recordNameLength equ $ - recordName
recordBuffer db 4 * 25 dup (?)			;记录文件内容缓冲区

health db 'HP'
score db 'scores'
scores db '000'
breach db 0		;分数突破标记，突破时置为3

data ends
;++++++++++++++++++++++++++++++++++++++++++++++++++++

code segment
assume cs:code,ds:data

destoryExplode proc far
	push ax
	push bx
	push cx
	push ds
	
	mov ax,data
	mov ds,ax
	xor ax,ax
	mov breach,al
	xor bx,bx
	mov cx,FOES
explodeInit:	mov explode[bx],ax
	add bx,2
	loop explodeInit
	
	pop ds
	pop cx
	pop bx
	pop ax
	ret
destoryExplode endp

;游戏初始化过程
initialize proc far
	push ax
	push bx
	push cx
	push si
	push ds
	
	mov ax,data
	mov ds,ax
	mov al,'0'
	mov scores[0],al
	mov scores[1],al
	mov scores[2],al
	
	call destoryExplode
	
	
	;战机模块初始化
	mov ax,seg fighterHealth
	mov ds,ax
	mov fighterHealth,HP
	mov fighterX, (RIGHT_BORDER - FIGHTER_WIDTH) / 2	;111，横坐标
	mov fighterY, BORDER_BOTTOM - FIGHTER_HEIGHT + 1	;181，纵坐标
	xor ax,ax
	mov fighterShiftFactor,al
	lea bx,bulletFactor
	xor si,si
	mov cx,BULLET_MAX_NUM
bulletInit:	mov [bx+si],ax
	add si,2
	loop bulletInit
	mov bulletPointer,ax
	mov bulletFireFactor,al
	mov fighterCoreX , (RIGHT_BORDER - FIGHTER_WIDTH) / 2 + FIGHTER_WIDTH / 2
	mov fighterCoreY , BORDER_BOTTOM - FIGHTER_HEIGHT + 1 + FIGHTER_HEIGHT / 2
	
	;敌机模块初始化
	mov bx,seg foep
	mov ds,bx
	mov foep,ax
	mov enemyFactor,al
	mov loadOrder,al
	mov tempTimes,al
	lea bx,enemy
	xor si,si
	mov cx,FOES
enemyInit: 	mov [bx+si],ax
	add si,2
	loop enemyInit
	lea bx,ebullet
	xor si,si
	mov cx,EBULLETS
ebulletInit: 	mov [bx+si],ax
	add si,2
	loop ebulletInit
	
	
	
	pop ds
	pop si
	pop cx
	pop bx
	pop ax
	ret
initialize endp

showHP proc far
	push ax
	push bx
	push cx
	push dx
	push ds
	
	mov ax,seg fighterHealth
	mov ds,ax
	mov ah,2
	mov bh,0
	mov dh,0
	mov dl,35
	int 10h
	mov ax,fighterHealth
	mov ah,9
	add al,'0'
	mov bl,12
	mov bh,0
	mov cx,1
	int 10h
	
	pop ds
	pop dx
	pop cx
	pop bx
	pop ax
	ret
showHP endp

information proc far
	push ax
	push bx
	push cx
	push dx
	push bp
	push ds
	push es
	
	mov ax,data
	mov ds,ax
	mov es,ax
	mov ax,1300H	;显示字符串，方式0
	lea bp,health 		;显示标题，字符串偏移地址
	mov bx,7	;显示页和颜色，只需颜色值默认0页即可
	mov cx,2		;标题字符串长度
	mov dh,0		;显示行位置
	mov dl,31		;显示列位置
	int 10H
	
	lea bp,score 		;显示标题，字符串偏移地址
	mov bx,7	;显示页和颜色，只需颜色值默认0页即可
	mov cx,6		;标题字符串长度
	mov dh,2		;显示行位置
	mov dl,32		;显示列位置
	int 10H
	
	lea bp,scores 		;显示标题，字符串偏移地址
	mov bx,1	;显示页和颜色，只需颜色值默认0页即可
	mov cx,3		;字符串长度
	mov dh,4		;显示行位置
	mov dl,32		;显示列位置
	int 10H
	
	
	call showHP
	
	pop es
	pop ds
	pop bp
	pop dx
	pop cx
	pop bx
	pop ax
	ret
information endp

message proc far
	push ax
	push bx
	push cx
	push dx
	push bp
	push ds
	push es
	
	mov ax,data
	mov ds,ax
	mov es,ax
	
	mov bx,2
number:	xor ah,ah
	mov al,scores[bx]
	add al,'1'
	aaa
	or al,30h
	mov scores[bx],al
	cmp bx,0
	je numberLim
	cmp ah,0
	je showNumber
	dec bx
	jmp short number
	
numberLim: cmp ah,0	
	je showNumber
	mov breach,3	;分数突破
	
showNumber: mov ax,1300H	;显示字符串，方式0
	lea bp,scores 		;显示标题，字符串偏移地址
	mov bx,1	;显示页和颜色，只需颜色值默认0页即可
	mov cx,3		;字符串长度
	mov dh,4		;显示行位置
	mov dl,32		;显示列位置
	int 10H	
	
	pop es
	pop ds
	pop bp
	pop dx
	pop cx
	pop bx
	pop ax
	ret
message endp

;起爆
;参数：[bp + 6]为横坐标，[bp + 8]为纵坐标
detonate proc far
	push bp
	mov bp,sp
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
retrieval:	mov ax,explode[si]
	cmp ah,0
	je detonateOK
	add si,2
	loop retrieval
	
detonateOK: xor al,al
	inc ah
	mov cx,[bp + 6]
	mov dx,[bp + 8]
	sub cx,BLAST_WIDTH / 2 -1
	sub dx,BLAST_HEIGHT / 2 -1
	cmp cx,0
	jl x0
	cmp cx,RIGHT_BORDER + 1 - BLAST_WIDTH
	jg xr
	jmp short setY
	
x0:	xor cx,cx
	jmp short setY
xr:	mov cx,RIGHT_BORDER + 1 - BLAST_WIDTH
	
setY:	mov explodeX[si],cx
	cmp dx,0
	jl y0
	cmp dx,BORDER_BOTTOM + 1 - BLAST_HEIGHT
	jg yd
	jmp short position
	
y0:	xor dx,dx
	jmp short position
yd:	mov dx,BORDER_BOTTOM + 1 - BLAST_HEIGHT
position:	mov explodeY[si],dx
	push si
	
	mov cl,BLAST_WIDTH
	mov ch,BLAST_HEIGHT
	push cx
	push explodeY[si]
	mov di,explodeX[si]
	mov bx,explodeReplaceUnit[si]
	lea si,explodeBmp
	call outputPicture
	
	pop si
	mov explode[si],ax
	
	pop ds
	pop di
	pop si
	pop dx
	pop cx
	pop bx
	pop ax
	mov sp,bp
	pop bp
	ret 4
detonate endp

;爆炸持续过程
explosion proc far
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
	mov cx,FOES
explosive:	mov ax,explode[bx]
	cmp ah,0
	je blastNext
	cmp al,BLAST_EXIST
	jb sustain
	
	mov dl,BLAST_WIDTH
	mov dh,BLAST_HEIGHT
	mov si,explodeReplaceUnit[bx]
	mov di,explodeX[bx]
	push dx
	push explodeY[bx]
	call clear
	xor ah,ah
	
sustain:	inc al
	mov explode[bx],ax
blastNext:	add bx,2
	loop explosive
	
	pop ds
	pop di
	pop si
	pop dx
	pop cx
	pop bx
	pop ax
	ret
explosion endp

;游戏帮助
setgameHelp proc far
	push ax
	push bx
	push cx
	push dx
	push si
	push ds
	
	mov ax,data
	mov ds,ax
	lea bx,explain
	mov cx,explainNameLength
	lea si,explainPath
	call filePath
	
	;打开文件
	mov ax,3d02H
	mov dx,si
	int 21H
	
	;读文件到缓冲
	mov bx,ax
	mov ah,3fH
	mov cx,explainLength
	lea dx,explainBuffer
	int 21H
	
	;关闭文件
	mov ah,3eH
	int 21H
	
	pop ds
	pop si
	pop dx
	pop cx
	pop bx
	pop ax
	ret
setgameHelp endp

explainShow proc far
	push ax
	push bx
	push cx
	push dx
	push bp
	push ds
	push es
	
	mov ax,data
	mov ds,ax
	mov es,ax
	
	mov ax,1300H	;显示字符串，方式0
	lea bp,explainBuffer 		;显示标题，字符串偏移地址
	mov bh,explainPage
	mov bl,7	;显示页和颜色
	mov cx,explainLength		;标题字符串长度
	xor dx,dx		;显示行位置
			;显示列位置
	int 10H
	
	;置当前显示页
	mov ah,5H
	mov al,explainPage
	int 10H
	
	mov ah,0
	int 16H	;按任意键返回
	
	;置默认显示页
	mov ah,5H
	xor al,al
	int 10H
	
	pop es
	pop ds
	pop bp
	pop dx
	pop cx
	pop bx
	pop ax
	ret
explainShow endp

;取文件路径
;参数：ax段地址（es）,bx文件名偏移地址，cx文件名长度，si存放当前目录字符串的偏移地址
filePath proc
	push si
	push di
	push es
	mov es,ax
	
	mov ah,19H	;取当前缺省驱动器号，返回al
	int 21H
	inc al
	cmp al,3
	je saveC
	cmp al,4
	je saveD
	
saveC: mov byte ptr [si],'C'
	jmp short head
	
saveD: mov byte ptr [si],'D'
head:	inc si
	mov byte ptr [si],':'
	inc si
	mov byte ptr [si],'\'
	inc si
	
	mov dl,al
	mov ah,47H	;取当前目录
	int 21H
	
	mov di,si
dirname:	inc di
	cmp byte ptr [di],0
	jne dirname
	
	mov si,bx
	cld
	rep movsb
	
	pop es
	pop di
	pop si
	ret
filePath endp

;纪录文件操作
;参数:di：0读，1写
recordio proc far
	push ax
	push bx
	push cx
	push dx
	push si
	push ds
	
	mov ax,data
	mov ds,ax
	lea bx,recordName
	mov cx,recordNameLength
	lea si,recordPath
	call filePath
	
	;打开文件
	mov ax,3d02H
	mov dx,si
	int 21H
	
	mov bx,ax
	mov cx,recordLength
	lea dx,recordBuffer
	cmp di,1
	je writeFile
	
	;读文件到缓冲
	mov ah,3fH
	jmp short readFile
	
	;写内存数据到文件
writeFile:	
	mov ah,40H
readFile:	int 21H
	
	;关闭文件
	mov ah,3eH
	int 21H
	
	pop ds
	pop si
	pop dx
	pop cx
	pop bx
	pop ax
	ret
recordio endp

;纪录操作
recordOperation proc far
	push ax
	push bx
	push cx
	push ds
	mov ax,data
	mov ds,ax
	
	mov cx,24
	mov bx,24 * 4
new:	push cx
	mov cx,4
replace:	mov al,recordBuffer[bx - 4]
	mov recordBuffer[bx],al
	dec bx
	loop replace
	pop cx
	loop new
	mov al,breach
	mov recordBuffer[bx],al
	
	mov cx,3
update:	inc bx
	mov al,scores[bx -1]
	mov recordBuffer[bx],al
	loop update
	
	pop ds
	pop cx
	pop bx
	pop ax
	ret
recordOperation endp

;显示游戏纪录
gameRecord proc far
	push ax
	push bx
	push cx
	push dx
	push bp
	push ds
	push es
	
	mov ax,data
	mov ds,ax
	mov es,ax
	
	mov ax,1300H	;显示字符串，方式0
	lea bp,recordBuffer 		;显示标题，字符串偏移地址
	mov bh,recordPage
	mov bl,5aH		;显示页和颜色
	xor dx,dx		;显示行列位置
	
	mov cx,25
showRecord:	push cx
	mov cx,4		;标题字符串长度
	int 10H
	add bp,cx
	inc dh
	pop cx
	loop showRecord
	
	;置当前显示页
	mov ah,5H
	mov al,recordPage
	int 10H
	
	mov ah,0
	int 16H	;按任意键返回
	
	;置默认显示页
	mov ah,5H
	xor al,al
	int 10H
	
	pop es
	pop ds
	pop bp
	pop dx
	pop cx
	pop bx
	pop ax
	ret
gameRecord endp


code ends
end