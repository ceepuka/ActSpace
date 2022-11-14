public keyboard

code segment
assume cs:code

keyboard proc far
	xor ax,ax		;清空ax
	in al,60H		;读键盘的扫描码
	cmp al,11H		;W
	je Wkey
	cmp al,1EH		;A
	je Akey
	cmp al,1FH		;S
	je Skey
	cmp al,20H		;D
	je Dkey
	ret
	
	;ah决定移动，默认0不移动
	;bx为偏移地址，对应 W,A,S,D
Wkey: mov bx,0
	jmp short return
Akey: mov bx,2
	jmp short return
Skey: mov bx,4
	jmp short return
Dkey: mov bx,6
return:	mov ah,1
	ret
keyboard endp

code ends
end