	idnt	"floatstr.c"
	opt	0
	opt	NQLPSMRBT
	section	"CODE",code
	public	_hexfloat2str
	cnop	0,4
_hexfloat2str
	sub.w	#24,a7
	movem.l	l5,-(a7)
	move.l	(28+l7,a7),a3
	move.l	(32+l7,a7),a2
	moveq	#0,d0
	move.b	(3,a2),d0
	move.l	d0,-(a7)
	moveq	#0,d0
	move.b	(2,a2),d0
	move.l	d0,-(a7)
	moveq	#0,d0
	move.b	(1,a2),d0
	move.l	d0,-(a7)
	moveq	#0,d0
	move.b	(a2),d0
	move.l	d0,-(a7)
	pea	l2
	lea	(20+l7,a7),a0
	move.l	a0,-(a7)
	jsr	_sprintf
	lea	(40+l7,a7),a0
	move.l	a0,-(a7)
	pea	l3
	lea	(32+l7,a7),a0
	move.l	a0,-(a7)
	jsr	_sscanf
	lea	(52+l7,a7),a0
	move.l	(a0),d2
	move.l	d2,-(a7)
	jsr	__ieees2d
	movem.l	d0/d1,-(a7)
	pea	l4
	move.l	a3,-(a7)
	jsr	_sprintf
	add.w	#56,a7
l1
l5	reg	a2/a3/d2
	movem.l	(a7)+,a2/a3/d2
l7	equ	12
	add.w	#24,a7
	rts
	cnop	0,4
l2
	dc.b	37
	dc.b	120
	dc.b	37
	dc.b	120
	dc.b	37
	dc.b	120
	dc.b	37
	dc.b	120
	dc.b	0
	cnop	0,4
l3
	dc.b	37
	dc.b	120
	dc.b	0
	cnop	0,4
l4
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
	movem.l	l9,-(a7)
	jsr	_drop_to_asm
l8
l9	reg
l11	equ	0
	rts
	public	__ieees2d
	public	_sprintf
	public	_sscanf
	public	_drop_to_asm
