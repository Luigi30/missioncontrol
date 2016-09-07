	idnt	"floatstr.c"
	opt	0
	opt	NQLPSMRBT
	section	"CODE",code
	public	_hexfloat2str
	cnop	0,4
_hexfloat2str
	subq.w	#4,a7
	movem.l	l3,-(a7)
	move.l	(12+l5,a7),a3
	move.l	(8+l5,a7),a2
	move.l	#4,-(a7)
	move.l	a3,-(a7)
	lea	(8+l5,a7),a0
	move.l	a0,-(a7)
	jsr	_memcpy
	move.l	(12+l5,a7),-(a7)
	jsr	__ieees2d
	movem.l	d0/d1,-(a7)
	pea	l2
	move.l	a2,-(a7)
	jsr	_sprintf
	add.w	#32,a7
l1
l3	reg	a2/a3
	movem.l	(a7)+,a2/a3
l5	equ	8
	addq.w	#4,a7
	rts
	cnop	0,4
l2
	dc.b	37
	dc.b	46
	dc.b	50
	dc.b	102
	dc.b	0
	opt	0
	opt	NQLPSMRBT
	public	_main
	cnop	0,4
_main
	movem.l	l7,-(a7)
	jsr	_drop_to_asm
l6
l7	reg
l9	equ	0
	rts
	public	__ieees2d
	public	_sprintf
	public	_memcpy
	public	_drop_to_asm
