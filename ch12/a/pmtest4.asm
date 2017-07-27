; ==========================================
; pmtest4.asm
; 定义向下扩展的堆栈段
; 编译方法：nasm pmtest4.asm -o pmtest4.com
; ==========================================

%include	"pm.inc"	; 常量, 宏, 以及一些说明
		org 0100h
		jmp LABEL_START

; //////////////////////////////////////////////////////////////////////////////////////////////

[SECTION .gdt]
; GDT
;					Base		Limit		Attr
LABEL_GDT:		Descriptor	0,		0,		0		; 空描述符, 处理器的要求
LABEL_DESC_CODE32:	Descriptor	0,		SegCode32Len-1,	DA_C32		; 32位代码段描述符
LABEL_DESC_VIDEO:	Descriptor	0B8000h,	0FFFFh,		DA_D32		; 32位视频段描述符
LABEL_DESC_STACK:	Descriptor	0,		0,		DA_S32_L	; 32位堆栈段描述符
LABEL_DESC_DATA:	Descriptor	0,		0FFFFh,		DA_D32		; 32位数据端描述符

GdtLen	equ	$ - LABEL_GDT	; GDT　长度
GdtPtr:	dw	GdtLen - 1	; GDT　界限
	dd	0		; GDT线性基地址

; GDT　选择子, 16 bits
Selector_Code32		equ	LABEL_DESC_CODE32 - LABEL_GDT		; 值为8 -> 1_0_00b -> 描述符索引=1; TI=0, RPL=00
Selector_Video		equ	LABEL_DESC_VIDEO - LABEL_GDT		; 值为16 -> 10_0_00b -> 描述符索引=2; TI=0, RPL=00
Selector_Stack		equ	LABEL_DESC_STACK - LABEL_GDT		; 值为24 -> 11_0_00b -> 描述符索引=3; TI=0, RPL=00
Selector_Data		equ	LABEL_DESC_DATA - LABEL_GDT

; ///////////////////////////////// End of [SECTION .gdt] /////////////////////////////////


; 堆栈段
[SECTION .stack]
ALIGN 32
[BITS 32]
LABEL_STACK:
	times 512 db 0
ButtomOfStack	equ $ - LABEL_STACK

; ///////////////////////////////// End of [SECTION .stack] /////////////////////////////////

[SECTION .c16] ; 16 位代码段
[BITS 16]
LABEL_START:
	mov	ax, cs
	mov	ds, ax
	mov	es, ax
	mov	ss, ax
	mov	sp, 0100h

	; 初始化 32 位代码段描述符中的"段基址", 参照描述符格式
	xor	eax, eax
	mov	ax, cs
	shl	eax, 4
	add	eax, LABEL_SEG_CODE32			; 段地址 << 4 + 偏移地址 = 线性地址
	mov	word [LABEL_DESC_CODE32 + 2], ax	; ax = 线性基地址的低16 bits, 填入描述符的"段基址1"
	shr	eax, 16					; ax = 线性基地址的高16 bits
	mov	byte [LABEL_DESC_CODE32 + 4], al	; 段基址2
	mov	byte [LABEL_DESC_CODE32 + 7], ah	; 段基址3

	; 初始化堆栈段描述符
	xor	eax, eax
	mov	ax, ds
	shl	eax, 4
	add	eax, LABEL_STACK
	mov	word [LABEL_DESC_STACK + 2], ax
	shr	eax, 16
	mov	byte [LABEL_DESC_STACK + 4], al
	mov	byte [LABEL_DESC_STACK + 7], ah

	; 将数据段作为代码段的别名段
	xor	eax, eax
	mov	ax, cs
	shl	eax, 4
	add	eax, LABEL_SEG_CODE32
	mov	word [LABEL_DESC_DATA + 2], ax
	shr	eax, 16
	mov	byte [LABEL_DESC_DATA + 4], al
	mov	byte [LABEL_DESC_DATA + 7], ah

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


; ///////////////////////////////// End of [SECTION .c16] /////////////////////////////////

[SECTION .c32] ; 32　位代码段, 由实模式跳入
[BITS 32]
LABEL_SEG_CODE32:
	mov	ax, Selector_Video	; 选择子为 16 bits, 无需使用 eax
	mov	gs, ax

	mov	ax, Selector_Stack	; 堆栈段选择子
	mov	ss, ax
	mov	esp, ButtomOfStack

	mov	ax, Selector_Data	; 数据段选择子
	mov	ds, ax

	mov	edi, (80 * 10 + 0) * 2	; 屏幕第 10 行, 第 0 列
	call	TestRead
	
	call	TestWrite

	mov	edi, (80 * 11 + 0) * 2	; 屏幕第 11 行, 第 0 列
	call	TestRead

	; 到此停止
	jmp	$

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
	mov	ah, 0Ch			; 0000: 黑底    1100: 红字
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
; TestRead: 读取数据开头 5 字节, 并显示在 gs:edi 指向的显存
;	ds:esi 指向待读取内存的第一字节
;-------------------------------------------------------------------------------
TestRead:
	push	esi
	push	ecx

	xor	esi, esi
	mov	ecx, 5
.read:
	mov	al, [cs:esi]
	call	DispAL
	inc	esi
	loop	.read

	pop	ecx
	pop	esi
	ret
;-------------------------------------------------------------------------------

;-------------------------------------------------------------------------------
; TestWrite: 写数据段开头 5 字节
;	ds:esi 指向待写入内存的第一字节
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

SegCode32Len	equ	$ - LABEL_SEG_CODE32

; ///////////////////////////////// End of [SECTION .c32] /////////////////////////////////


