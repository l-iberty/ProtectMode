; ==========================================
; pmtest2.asm
; 编译方法：nasm pmtest2.asm -o pmtest2.com
; ==========================================

%include	"pm.inc"	; 常量, 宏, 以及一些说明
		org 0100h
		jmp LABEL_START

; //////////////////////////////////////////////////////////////////////////////////////////////

; GDT
[SECTION .gdt]
;					Base		Limit		Attr
LABEL_GDT:		Descriptor	0,		0,		0		; 空描述符, 处理器的要求
LABEL_DESC_NORMAL:	Descriptor	0,		0FFFFh,		DA_D32		; Normal 描述符
LABEL_DESC_CODE32:	Descriptor	0,		SegCode32Len-1,	DA_C32		; 32-bit 代码段描述符
LABEL_DESC_CODE16:	Descriptor	0,		0FFFFh,		DA_C16		; 16-bit 位代码段描述符
LABEL_DESC_VIDEO:	Descriptor	0B8000h,	0FFFFh,		DA_D32		; 32-bit 位视频段描述符
LABEL_DESC_STACK:	Descriptor	0,		0,		DA_S32_L	; 32-bit 位堆栈段描述符
LABEL_DESC_DATA:	Descriptor	0,		DataLen-1,	DA_D32		; 32-bit 位数据段描述符
LABEL_DESC_LDT:		Descriptor	0,		LdtLen-1,	DA_LDT		; LDT 描述符 (保护模式下需要使用 GDT 对其寻址 )

GdtLen	equ	$ - LABEL_GDT	; GDT　长度
GdtPtr:	dw	GdtLen - 1	; GDT　界限
	dd	0		; GDT线性基地址

; GDT　选择子, 16 bits
Selector_Normal		equ	LABEL_DESC_NORMAL	- LABEL_GDT
Selector_Code32		equ	LABEL_DESC_CODE32	- LABEL_GDT
Selector_Code16		equ	LABEL_DESC_CODE16	- LABEL_GDT
Selector_Video		equ	LABEL_DESC_VIDEO	- LABEL_GDT
Selector_Stack		equ	LABEL_DESC_STACK	- LABEL_GDT
Selector_Data		equ	LABEL_DESC_DATA		- LABEL_GDT
Selector_Ldt		equ	LABEL_DESC_LDT		- LABEL_GDT	; 通过该选择子寻址 LDT

; ///////////////////////////////// End of [SECTION .gdt] /////////////////////////////////


; LDT
[SECTION .ldt]
ALIGN 32	; 使用 LDT 时已处于 32-bit 保护模式下
LABEL_LDT:
;					Base	Limit		Attr
LABEL_LDT_DESC_CODE32:	Descriptor	0,	CodeLLen-1,	DA_C32
LABEL_LDT_DESC_DATA:	Descriptor	0,	DataLLen-1,	DA_D32

LdtLen	equ	$ - LABEL_LDT

; LDT 选择子, 16 bits
Selector_Code32L	equ	LABEL_LDT_DESC_CODE32	- LABEL_LDT + SA_TI_LDT
Selector_DataL		equ	LABEL_LDT_DESC_DATA	- LABEL_LDT + SA_TI_LDT

; ///////////////////////////////// End of [SECTION .ldt] /////////////////////////////////


; 堆栈段
[SECTION .stack]
ALIGN 32
[BITS 32]
LABEL_SEG_STACK:
	times 512 db 0
ButtomOfStack	equ $ - LABEL_SEG_STACK

; ///////////////////////////////// End of [SECTION .stack] /////////////////////////////////


; 数据段
[SECTION .data]
ALIGN 32
[BITS 32]
LABEL_SEG_DATA:
szTest:		db 'In Protection Mode', 0
Offset_szTest	equ szTest - LABEL_SEG_DATA

szCR0:		db 'CR0:', 0
Offset_szCR0	equ szCR0 - LABEL_SEG_DATA

szESP:		db 'ESP:', 0
Offset_szESP	equ szESP - LABEL_SEG_DATA

SPValueInRealMode	dw 0

szVar:		db 'Var(Hex):', 0
Offset_szVar	equ szVar - LABEL_SEG_DATA

Var		dw 0
Offset_Var	equ Var - LABEL_SEG_DATA

DataLen	equ	$ - LABEL_SEG_DATA

; ///////////////////////////////// End of [SECTION .data] /////////////////////////////////


[SECTION .c16_r] ; 实模式下的 16-bit 代码段
[BITS 16]
LABEL_START:
	mov	ax, cs
	mov	ds, ax
	mov	es, ax
	mov	ss, ax
	mov	sp, 0100h

	mov	[SPValueInRealMode], sp			; 保存实模式下的sp
	mov	[LABEL_BACK_TO_REAL + 3], ax
	mov	[Var], ax				; 保存 cs 原值, 调试时将显示之

	; 初始化 32-bit 代码段描述符中的"段基址", 参照描述符格式
	xor	eax, eax
	mov	ax, cs
	shl	eax, 4
	add	eax, LABEL_SEG_CODE32			; 段地址 << 4 + 偏移地址 = 线性地址
	mov	word [LABEL_DESC_CODE32 + 2], ax	; ax = 线性基地址的低16 bits, 填入描述符的"段基址1"
	shr	eax, 16					; ax = 线性基地址的高16 bits
	mov	byte [LABEL_DESC_CODE32 + 4], al	; 段基址2
	mov	byte [LABEL_DESC_CODE32 + 7], ah	; 段基址3

	; 初始化 16-bit 代码段描述符
	xor	eax, eax
	mov	ax, cs
	shl	eax, 4
	add	eax, LABEL_SEG_CODE16
	mov	word [LABEL_DESC_CODE16 + 2], ax
	shr	eax, 16
	mov	byte [LABEL_DESC_CODE16 + 4], al
	mov	byte [LABEL_DESC_CODE16 + 7], ah

	; 初始化堆栈段描述符
	xor	eax, eax
	mov	ax, ds
	shl	eax, 4
	add	eax, LABEL_SEG_STACK
	mov	word [LABEL_DESC_STACK + 2], ax
	shr	eax, 16
	mov	byte [LABEL_DESC_STACK + 4], al
	mov	byte [LABEL_DESC_STACK + 7], ah

	; 初始化数据段描述符
	xor	eax, eax
	mov	ax, ds
	shl	eax, 4
	add	eax, LABEL_SEG_DATA
	mov	word [LABEL_DESC_DATA + 2], ax
	shr	eax, 16
	mov	byte [LABEL_DESC_DATA + 4], al
	mov	byte [LABEL_DESC_DATA + 7], ah

	; 初始化 GDT 中的 LDT 描述符
	xor	eax, eax
	mov	ax, ds
	shl	eax, 4
	add	eax, LABEL_LDT
	mov	word [LABEL_DESC_LDT + 2], ax
	shr	eax, 16
	mov	byte [LABEL_DESC_LDT + 4], al
	mov	byte [LABEL_DESC_LDT + 7], ah

	; 初始化 LDT 中的 32-bit 代码段描述符
	xor	eax, eax
	mov	ax, cs
	shl	eax, 4
	add	eax, LABEL_LDT_SEG_CODE32
	mov	word [LABEL_LDT_DESC_CODE32 + 2], ax
	shr	eax, 16
	mov	byte [LABEL_LDT_DESC_CODE32 + 4], al
	mov	byte [LABEL_LDT_DESC_CODE32 + 7], ah

	; 初始化 LDT 中的数据段描述符
	xor	eax, eax
	mov	ax, ds
	shl	eax, 4
	add	eax, LABEL_LDT_SEG_DATA
	mov	word [LABEL_LDT_DESC_DATA + 2], ax
	shr	eax, 16
	mov	byte [LABEL_LDT_DESC_DATA + 4], al
	mov	byte [LABEL_LDT_DESC_DATA + 7], ah

	; 为加载 GDT 做准备
	xor	eax, eax
	mov	ax, ds
	shl	eax, 4
	add	eax, LABEL_GDT			; eax <- GDT线性基地址
	mov	dword [GdtPtr + 2], eax		; [GdtPtr + 2] <- GDT线性基地址

	; 加载 GDT
	lgdt	[GdtPtr]

	; 打开　A20 地址线
	in	al, 92h
	or	al, 0000_0010b
	out	92h, al

	; 关中断
	cli

	; 控制寄存器 cr0 的PE位置1
	mov	eax, cr0
	or	eax, 1
	mov	cr0, eax

	; 进入保护模式
	jmp	dword Selector_Code32:0
	; dword 关键字强制处理器将'0'解释为32位偏移量; 否则, 如果偏移量是一个超过16位的数, 高16位会丢失.
	; jmp 指令将 Selector_Code32 加载到代码段选择器 cs, 并从 GDT 中取出对应的描述符, 加载到cs描述符
	; 高速缓存器; 同时, 把指令中给出的32位偏移量传送到 eip, 处理器便从新的地方取得指令并执行.

;++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
LABEL_REAL_ENTRY:		; 从保护模式跳回实模式后就跳到了这里
	mov	ax, cs		; cs 已被恢复为实模式下的原值
	mov	ds, ax
	mov	es, ax
	mov	ss, ax
	mov	sp, [SPValueInRealMode]

	; 关闭　A20 地址线
	in	al, 92h
	and	al, 1111_1101b
	out	92h, al

	; 开中断
	sti

	mov	ax, 0B800h
	mov	gs, ax
	mov	di, (80 * 13 + 0) * 2	; 屏幕第 13 行, 第 0 列
	mov	si, _szMsg
	call	DispMsg
	
	mov	ax, 4c00h
	int	21h

_szMsg:	db 'In Real Mode', 0

;---------------------------------------------------------------
; DispMsg: 实模式下在 gs:di 处显示字符串
; ds:si 指向字符串第一字节
;---------------------------------------------------------------
DispMsg:
	push	bx
	mov	ah, 0Ch			; 0000: 黑底    1100: 红字
	xor	bx, bx
	mov	si, _szMsg
.a:
	mov	al, [si+bx]
	cmp	al, 0
	jz	.b
	mov	[gs:edi], ax
	add	edi, 2
	inc	si
	jmp	.a
.b:
	pop	bx
	ret
;----------------------------------------------------------------


; ///////////////////////////////// End of [SECTION .c16_r] /////////////////////////////////

[SECTION .c32] ; 32-bit 代码段, 由实模式跳入
[BITS 32]
LABEL_SEG_CODE32:
	mov	ax, Selector_Video	; 选择子为 16 bits, 无需使用 eax
	mov	gs, ax

	mov	ax, Selector_Stack	; 堆栈段选择子
	mov	ss, ax
	mov	esp, ButtomOfStack

	mov	ax, Selector_Data	; 数据段选择子
	mov	ds, ax

	; 显示一个字符串
	mov	edi, (80 * 8 + 0) * 2	; 屏幕第 8 行, 第 0 列
	mov	esi, Offset_szTest
	call	DispStr

	; 显示　cr0 和 esp 的内容
	mov	edi, (80 * 10 + 0) * 2	; 屏幕第 10 行, 第 0 列
	mov	esi, Offset_szCR0
	call	DispStr
	mov	eax, cr0
	call	Disp_DWORD
	mov	edi, (80 * 11 + 0) * 2	; 屏幕第 11 行, 第 0 列
	mov	esi, Offset_szESP
	call	DispStr
	mov	eax, esp
	call	Disp_DWORD

	; 显示实模式下 cs 原值
	mov	edi, (80 * 12 + 0) * 2	; 屏幕第 12 行, 第 0 列
	mov	esi, Offset_szVar
	call	DispStr
	mov	esi, Offset_Var
	mov	ax, [ds:esi]
	;mov	eax, [ds:esi] 会引发异常，因为操作数是 dword　会发生越界访问数据段的异常
	call	Disp_DWORD

	;jmp	Selector_Code16:0

	; 加载 LDT
	mov	ax, Selector_Ldt
	lldt	ax

	; 跳入局部任务
	jmp	Selector_Code32L:0


;-------------------------------------------------------------------------------
; DispAL: 显示 AL 中的数字 (十六进制)
; 显示位置: gs:edi 指向的显存
; 调用结束后, gs:edi 指向下一个显示位置
;-------------------------------------------------------------------------------
DispAL:
	push	ebx
	push	ecx

	mov	bl, al
	shr	al, 4
	mov	ecx, 2
.loop:
	and	al, 0Fh
	cmp	al, 0Ah
	jb	.1
	sub	al, 0Ah
	add	al, 'A'
	jmp	.2
.1:
	add	al, '0'
.2:
	mov	ah, 0Fh			; 0000: 黑底    1111: 白字
	mov	[gs:edi], ax
	add	edi, 2

	mov	al, bl
	loop	.loop

	add	edi, 2
	pop	ecx
	pop	ebx
	ret
;-------------------------------------------------------------------------------


;-------------------------------------------------------------------------------
; DispAlChar: 显示 AL 中的 ACSII 字符
; 显示位置: gs:edi 指向的显存
; 调用结束后, gs:edi 指向下一个显示位置
;-------------------------------------------------------------------------------
DispAlChar:
	mov	ah, 0Fh			; 0000: 黑底    1111: 白字
	mov	[gs:edi], ax
	add	edi, 2
	ret
;-------------------------------------------------------------------------------


;-------------------------------------------------------------------------------
; DispStr: 显示以 0 结尾字符串
; 显示位置: gs:edi 指向的显存
; 字符串地址: ds:esi
;-------------------------------------------------------------------------------
DispStr:
.continue:
	mov	al, [ds:esi]
	cmp	al, 0
	jz	.end
	call	DispAlChar
	inc	esi
	jmp	.continue
.end:
	ret
;-------------------------------------------------------------------------------


;-------------------------------------------------------------------------------
; TestRead: 读取数据段开头 5 字节, 并显示在 gs:edi 指向的显存
;-------------------------------------------------------------------------------
TestRead:
	push	esi
	push	ecx

	xor	esi, esi
	mov	ecx, 5
.read:
	mov	al, [ds:esi]
	call	DispAL
	inc	esi
	loop	.read

	pop	ecx
	pop	esi
	ret
;-------------------------------------------------------------------------------


;-------------------------------------------------------------------------------
; TestWrite: 写数据段开头 5 字节
;-------------------------------------------------------------------------------
TestWrite:
	push	esi
	push	ecx

	xor	esi, esi
	mov	al, 'A'
	mov	ecx, 5
.write:
	mov	byte [ds:esi], al
	inc	esi
	inc	al
	loop	.write

	pop	ecx
	pop	esi
	ret
;-------------------------------------------------------------------------------


;-------------------------------------------------------------------------------
; Disp_DWORD: 在 gs:edi 指向的显存显示一个 dword (十六进制)
;　调用者将 dword 存放在 eax
;-------------------------------------------------------------------------------
Disp_DWORD:
	push	ebx
	push	ecx
	push	edx

	mov	edx, eax	; 保存 eax
	mov	cl, 24		; 移位位数
	mov	ebx, 4		; 循环次数
	
	; 显示 '0x'
	mov	al, '0'
	call	DispAlChar
	mov	al, 'x'
	call	DispAlChar

.disp_al:
	mov	eax, edx
	shr	eax, cl
	call	DispAL
	sub	cl, 8
	sub	edi, 2		; 显示位置回退一个字符
	dec	ebx
	cmp	ebx, 0
	jg	.disp_al

	add	edi, 2
	pop	edx
	pop	ecx
	pop	ebx
	ret
;-------------------------------------------------------------------------------

SegCode32Len	equ	$ - LABEL_SEG_CODE32

; ///////////////////////////////// End of [SECTION .c32] /////////////////////////////////


[SECTION c16_p] ; 保护模式下的 16-bit 代码段
ALIGN	32
[BITS	16]
LABEL_SEG_CODE16:
	mov	ax, Selector_Normal	; Selector_Normal 指定的段的线性基地址为 0
	mov	ds, ax
	mov	es, ax
	mov	fs, ax
	mov	gs, ax
	mov	ss, ax

	; 清 cr0 PE位
	mov	eax, cr0
	and	al, 11111110b
	mov	cr0, eax

	; 跳回实模式
LABEL_BACK_TO_REAL:
	jmp	0:LABEL_REAL_ENTRY	; 段地址在程序开始处被设置成正确的值, 即跳入保护模式前实模式下的 cs 原值
					; 同时, jmp 指令会修改 cs 为实模式下的原值

SegCode16Len	equ	$ - LABEL_SEG_CODE16
; 不可定义该代码段的界限为 (SegCodeLen - 1), 否则 LABEL_BACK_TO_REAL 处的 jmp 将引发异常. 因为目标代码已经超越了界限.

; ///////////////////////////////// End of [SECTION .c16_p] /////////////////////////////////


[SECTION .lc32] ; 32-bit 局部代码段
ALIGN 32
[BITS 32]
LABEL_LDT_SEG_CODE32:
	mov	ax, Selector_Video
	mov	gs, ax
	mov	edi, (80 * 14 + 10) * 2	; 屏幕第 14 行, 第 10 列

	mov	ax, Selector_DataL
	mov	ds, ax
	mov	esi, Offset_szLDTMessage
	
	mov	ah, 0Ch			; 0000 黑底, 1100 红字
.prints:
	mov	al, [ds:esi]
	cmp	al, 0
	jz	.prints_end
	mov	[gs:edi], ax
	inc	esi
	add	edi, 2
	jmp	.prints
.prints_end:
	; 跳入 16-bit 代码段，最终回到实模式
	jmp	Selector_Code16:0

CodeLLen	equ	$ - LABEL_LDT_SEG_CODE32

; ///////////////////////////////// End of [SECTION .lc32] /////////////////////////////////


[SECTION .ldata] ; 32-bit 局部数据段
ALIGN 32
[BITS 32]
LABEL_LDT_SEG_DATA:
szLDTMessage:		db 'LDT_Message', 0
Offset_szLDTMessage	equ szLDTMessage - LABEL_LDT_SEG_DATA

DataLLen	equ $ - LABEL_LDT_SEG_DATA

; ///////////////////////////////// End of [SECTION .ldata] /////////////////////////////////
