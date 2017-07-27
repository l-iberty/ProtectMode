; 描述符
; usage: Descriptor Base, Limit, Attr
;	 %1 -> Base:	dd, 32　bits段基址(线性基地址)
;	 %2 -> Limit:	dd, 20　bits段界限(低20　bits可用)
;	 %3 -> Attr:	dw, 12　bits属性(高字节的低4　bits恒为0)
%macro Descriptor 3
	dw	%2 & 0FFFFh				; 段界限1
	dw	%1 & 0FFFFh				; 段基址1
	db	(%1 >> 16) & 0FFh			; 段基址2
	dw	(%3 & 0F0FFh) | ((%2 >> 8) & 0F00h)	; 属性 + 段界限2
	db	(%1 >> 24) & 0FFh			; 段基址3
%endmacro ; 64 bits, 8 Bytes


; 描述符属性
;	DA_: Descriptor Attribute
DA_C32		equ	0_1_0_0_0000_1_00_1_1000b	; 32位代码段属性 ( TYPE=1000b -> 只执行 )
DA_D32		equ	0_1_0_0_0000_1_00_1_0010b	; 32位数据段属性 ( TYPE=0010b -> 可读写, 向高地址扩展 )
DA_S32_L	equ	0_1_0_0_0000_1_00_1_0110b	; 32位堆栈段属性 ( TYPE=0110b, 可读写, 向低地址扩展 )
DA_S32_H	equ	0_1_0_0_0000_1_00_1_0010b	; 32位堆栈段属性 ( TYPE=0010b, 可读写, 向高地址扩展 )
; 描述符特权级 DPL:
DPL_0	equ	00_0_0000b
DPL_1	equ	01_0_0000b
DPL_2	equ	10_0_0000b
DPL_3	equ	11_0_0000b


; 选择子类型值
;	SA_: Selector Attribute
; 请求特权级 RPL　( 位1, 位0 ) :
SA_RPL_0	equ	0
SA_RPL_1	equ	1
SA_RPL_2	equ	2
SA_RPL_3	equ	3
; TI ( 位2 ) :
SA_TI_GDT	equ	0	; TI = 0, 描述符在 GDT 中
SA_TI_LDT	equ	4	; TI = 1, 描述符在 LDT 中
