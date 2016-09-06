	opt x+

	;Labels to export (the symbols won't be exported otherwise)
	xdef _drop_to_asm
	xdef START
	xdef ScratchBuffer
	xdef ClearScreen
	xdef ProcessKSPPacket
	xdef .foundHeader
	xdef .readPacketByte

	xdef IncomingBuffer

	xdef FloatG
	xdef FloatAP
	xdef FloatPE
	xdef FloatSMajA
	xdef FloatSMinA
	xdef FloatE
	xdef FloatInc
	xdef FloatTAp
	xdef FloatTpe
	xdef Floatperd
	xdef ByteCStg
	xdef ByteTStg

;Are we in debug mode?
DEBUG_PACKET equ 0

SECTION CODE

	include include/GEMDOS.I
	include include/XBIOS.I
	include include/STMACROS.I
	include include/KSPACKET.I

;Reposition the VT-52 cursor. Remember, the top left is (32,32) so add 32 first!
M_CursorPosition	MACRO
					PrintString PositionCursor
					PUSHW	#\1
					GEMDOS	c_conout, 4
					PUSHW	#\2
					GEMDOS	c_conout, 4
					ENDM

;Draw a data label.
M_FlightDataLabel	MACRO
					M_CursorPosition \2,\3
					PrintString lbl_\1
					ENDM

;Draw a byte field.
M_FlightByteField	MACRO
					M_CursorPosition \2,\3
					IFEQ	DEBUG_PACKET
					lea		IncomingBuffer,a0
					ENDC
					IFNE	DEBUG_PACKET
					lea		TestPacket,a0
					ENDC
					add.l	#KSP_\1,a0
					move.b	(a0),d0
					add.b	#$30,d0
					PUSHW	d0
					GEMDOS	c_conout, 4
					PrintString unit_\1
					ENDM

;Draw a float field.
M_FlightFloatField 	MACRO
					M_CursorPosition \2,\3
					IFEQ	DEBUG_PACKET
					lea	IncomingBuffer,a0
					ENDC
					IFNE	DEBUG_PACKET
					lea		TestPacket,a0
					ENDC
					add.l	#KSP_\1,a0
					move.l	(a0),d0
				    ror.w   #8, d0
				    swap    d0
				    ror.w   #8, d0
					JSR	FloatToString
					;PrintString	lbl_\1
					PrintString BlankOutField
					PrintString ScratchBuffer
					PrintString unit_\1
					ENDM
	
	even
_drop_to_asm:
	;get video memory addresses
	jsr	GetPhysicalBase
	jsr	GetLogicalBase

	jsr	Set96008N1
	jsr	FlushSerialBuffer

;WriteSerial:
;	PUSH	#$41
;	GEMDOS	c_auxout, 4
;
;	lea	msgHelloWorld,a1
;	jsr	C_auxws

ClearScreen:
	PrintString	ClearHome

KSPSerial:
	jsr	DrawFlightLabels

	;Use the test packet if we're debugging.
	IFNE	DEBUG_PACKET
	jsr	ProcessTestPacket
	jmp	PressAnyKey
	ENDC

	;Wait for a real packet if we're not debugging.
	IFEQ	DEBUG_PACKET
	jmp	WaitForPacket
	ENDC

WaitForHandshake:
	PrintString	msgWaitingForHandshake
	JSR	ReadKSPPacket

	;Handshake should be 4 bytes	
	;We got 4 bytes. Is it the handshake?
	cmp.l	#$00010203,IncomingBuffer
	beq	ReplyToHandshake
	PrintString	msgBadHandshake
	jmp	PressAnyKey

ReplyToHandshake:
	PrintString	msgGotHandshake
	lea	OutgoingPayload,a2
	
	;size
	move.b	#$04,(a2)+
	;packet type: handshake
	move.b	#$00,(a2)+

	;payload: handshake reply
	move.b	#$03,(a2)+
	move.b	#$01,(a2)+
	move.b	#$04,(a2)+
	JSR	SendKSPPacket		

WaitForPacket:
	JSR	ReadKSPPacket
	JSR	ProcessKSPPacket

	;Is there a key waiting in the buffer?
	GEMDOS	c_conis, 2
	cmp.b	#0,d0
	beq		WaitForPacket ;no, so loop

	GEMDOS	c_conin, 2
	cmp.b	#$71,d0 ;did they press q?
	bne		WaitForPacket ;no, so loop
	;if they did, fall through to PressAnyKey

PressAnyKey:
	M_CursorPosition 55,32
	PrintString	msgAnyKey	
	GEMDOS	1, 2 ;wait for keypress

End:
	jsr	SetHighRes
	GEMDOS	0, 0 ;pterm0

;Functions

ReadKSPPacket:
	;Packet format:
	;Bytes 0-1 are the header 0xBEEF
	;Byte 2 is the size
	;Bytes 3-(size-1) are the payload
	;The last byte is a checksum
	jsr	FlushSerialBuffer

	;Wait for the first character.
	GEMDOS	c_auxin, 2
	cmp.b	#$BE,d0
	bne	ReadKSPPacket ;not the start of a packet
	GEMDOS	c_auxin, 2
	cmp.b	#$EF,d0
	bne	ReadKSPPacket ;bad header

.foundHeader:
	;We found the header. How long is the packet?
	GEMDOS	c_auxin, 2
	move.b	d0,d7
	move.b	d0,Checksum
	lea	IncomingBuffer,a2

	;read the packet ID
	GEMDOS	c_auxin, 2
	move.b	d0,d6	

.readPacketByte:
	;Read d7 bytes from the serial port.
	GEMDOS	c_auxin, 2
	move.b	d0,(a2)+
	subq.b	#1,d7

	eor	d0,Checksum ;recalculate checksum

	cmp.b	#0,d7
	bne	.readPacketByte

.done:
	move.b	Checksum,d1
	GEMDOS	c_auxin, 2
	;d0 is the checksum we received
	;d1 is the checksum we calculated
	RTS

Set96008N1:
	;handle this in TOS
	rts

C_auxws:
	;Write a null-terminated string to AUX.
	;Input:
	;	a1 = pointer to string
.writeloop:
	cmp.b	#$00,(a1)
	beq	.done

	;write the next character
	clr.w	d0
	move.b	(a1)+,d0

	PUSHW	d0 ;put the next character on the stack
	GEMDOS	c_auxout, 4 ;write it and remove it from the stack

	jmp	.writeloop

.done:
	rts

SendKSPPacket:
	lea	OutgoingPayload,a2

	;transmit the header
	PUSHW	#$BE
	GEMDOS	c_auxout, 4
	PUSHW	#$EF
	GEMDOS	c_auxout, 4

	;how many bytes is the payload?
	move.b	(a2),d1
	lea	Checksum,a3
	move.b	(a2),(a3)
	addq	#1,a2

	;send the packet length
SendPacketLength:
	PUSHW	d1
	GEMDOS	c_auxout, 4

SendKSPByte:
	;update checksum
	clr.w	d0
	move.b	(a2)+,d0
	eor	d0,Checksum

	PUSHW	d0
	GEMDOS	c_auxout, 4
	subq	#1,d1
	cmp.b	#0,d1
	bne	SendKSPByte

.done:
	;Send the checksum
	move.b	Checksum,-(sp)
	GEMDOS	c_auxout, 4
	
	rts

ProcessTestPacket:
	

ProcessKSPPacket:
	JSR	DrawOrbitalParams
	JSR DrawFuelQuantities
	JSR DrawSurfaceInfo
	rts

DrawOrbitalParams:
FloatG:		M_FlightFloatField G,			 33,DataColumn1
FloatAP:	M_FlightFloatField AP,			 34,DataColumn1
FloatPE:	M_FlightFloatField PE,			 35,DataColumn1
FloatSMajA:	M_FlightFloatField SemiMajorAxis,36,DataColumn1
FloatSMinA: M_FlightFloatField SemiMinorAxis,37,DataColumn1
FloatE:		M_FlightFloatField e,			 38,DataColumn1
FloatInc:	M_FlightFloatField inc,			 39,DataColumn1
FloatTAp:	M_FlightFloatField TAp,			 40,DataColumn1
FloatTpe:	M_FlightFloatField TPe,			 41,DataColumn1
Floatperd:	M_FlightFloatField period,		 42,DataColumn1
ByteCStg:	M_FlightByteField  CurrentStage, 43,DataColumn1
ByteTStg:	M_FlightByteField  TotalStage,   44,DataColumn1
	rts

DrawFuelQuantities:
	M_FlightFloatField SolidFuel, 33,DataColumn2
	M_FlightFloatField LiquidFuel,34,DataColumn2
	M_FlightFloatField Oxidizer,  35,DataColumn2	
	M_FlightFloatField ECharge,   36,DataColumn2
	rts

DrawSurfaceInfo:
	M_FlightFloatField Pitch,	39,DataColumn2
	M_FlightFloatField Roll,	40,DataColumn2
	M_FlightFloatField Heading, 41,DataColumn2
	M_FlightFloatField Lat,		42,DataColumn2
	M_FlightFloatField Lon,		43,DataColumn2
	M_FlightFloatField RAlt,	44,DataColumn2
	M_FlightFloatField Density, 45,DataColumn2
	rts

DrawFlightLabels:

	;Orbital parameters
	M_CursorPosition 		 		32,LabelColumn1
	PrintString	msgOrbitalParams
	M_FlightDataLabel G,	 		33,LabelColumn1
	M_FlightDataLabel AP,	 		34,LabelColumn1
	M_FlightDataLabel PE,	 		35,LabelColumn1
	M_FlightDataLabel SemiMajorAxis,36,LabelColumn1
	M_FlightDataLabel SemiMinorAxis,37,LabelColumn1
	M_FlightDataLabel e, 	 		38,LabelColumn1
	M_FlightDataLabel inc, 	 		39,LabelColumn1
	M_FlightDataLabel TAp, 	 		40,LabelColumn1
	M_FlightDataLabel TPe, 	 		41,LabelColumn1
	M_FlightDataLabel period,		42,LabelColumn1
	M_FlightDataLabel CurrentStage, 43,LabelColumn1
	M_FlightDataLabel TotalStage,	44,LabelColumn1

	;Fuel quantities
	M_CursorPosition 				32, LabelColumn2
	PrintString	msgFuelQuantities
	M_FlightDataLabel SolidFuel,	33, LabelColumn2
	M_FlightDataLabel LiquidFuel,	34, LabelColumn2
	M_FlightDataLabel Oxidizer, 	35, LabelColumn2
	M_FlightDataLabel ECharge, 		36, LabelColumn2

	;Surface info
	M_CursorPosition 38,64
	PrintString	msgSurfaceInfo
	M_FlightDataLabel Pitch,	39, LabelColumn2
	M_FlightDataLabel Roll,		40, LabelColumn2
	M_FlightDataLabel Heading,	41, LabelColumn2
	M_FlightDataLabel Lat,		42, LabelColumn2
	M_FlightDataLabel Lon,		43, LabelColumn2
	M_FlightDataLabel RAlt,		44, LabelColumn2
	M_FlightDataLabel Density,	45, LabelColumn2
	rts

;Included functions
	include include/LINEHORZ.I
	include include/VIDEO.I
	include include/FLOAT.I
	include include/SERIALIO.I

	SECTION DATA

	even
;Pointers
GFX_BASE			dc.l	0
GFX_LOGICAL_BASE	dc.l	0

;Buffers
FloatBuffer		ds.b	8
ScratchBuffer	ds.b	128
	
IncomingBuffer	ds.b	512 ;allocate 512 bytes for serial incoming
OutgoingPayload	ds.b	512 ;payload buffer

;Global
Checksum		ds.b	1

;A KSP packet.
	even
TestPacket		dc.b	$1B,$53,$68,$44,$63,$1A,$12,$C9,$B1,$17,$93,$48,$B4,$56,$EF,$46,$C4,$54,$EF,$42,$3C,$AC,$7E,$3F 	;24 bytes
TestPacket2		dc.b	$E0,$14,$C7,$3D,$DE,$64,$E1,$40,$0C,$00,$00,$00,$21,$01,$00,$00,$51,$D5,$48,$40,$D3,$88,$8C,$3F,$29 ;25 bytes
TestPacket3		dc.b	$02,$00,$00,$33,$9C,$F8,$42,$53,$DA,$3F,$43,$E2,$54,$EF,$42,$B2,$14,$C7,$BD,$9E,$B8,$8E,$43,$00,$00
TestPacket4		dc.b	$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$48,$42,$00,$00,$48,$42,$00,$00,$20
TestPacket5		dc.b	$41,$00,$00,$20,$41,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$0C,$43,$28,$2F,$D6,$42,$00,$00,$00,$00
TestPacket6		dc.b	$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$02,$00,$00,$00,$00
TestPacket7		dc.b	$00,$00,$00,$2E,$CF,$53,$43,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$B4,$42,$00,$00,$00,$00,$3F,$A0
TestPacket8		dc.b	$D3,$3F,$00,$00,$82,$22,$5F,$1E,$A5,$3E,$F9,$22,$DE,$42,$00,$01

;Escape codes
ClearHome		dc.b	$1B,"E",0
PositionCursor	dc.b	$1B,"Y",0
NewLine			dc.b	$0D,$0A,0
BlankOutField	dc.b	$1B,"j","             ",$1B,"k",0

;Messages
msgHelloWorld		dc.b	"Hello World!",$0D,$0A,0
msgFlushBuffer		dc.b	"Flushing serial buffer.",$0D,$0A,0
msgDrawingLine		dc.b	"Drawing some horizontal lines.",$0D,$0A,0
msgAnyKey			dc.b	"Press any key to exit.",$0D,$0A,0
msgWaitingForHandshake	dc.b	"Awaiting KSP handshake...",$0D,$0A,0
msgGotHandshake		dc.b	"Got KSP handshake!",$0D,$0A,0
msgBadHandshake		dc.b	"KSP handshake is invalid. Abort.",$0D,$0A,0
msgGotCharacter		dc.b	"Got character from aux!",$0D,$0A,0
msgGotPacket		dc.b	"Received a KSP packet.",$0D,$0A,0
msgOrbitalParams	dc.b	"*** ORBITAL PARAMS ***",$0D,$0A,0
msgFuelQuantities	dc.b	"*** FUEL  QUANTITY ***",$0D,$0A,0
msgSurfaceInfo		dc.b	"*** SURFACE   INFO ***",$0D,$0A,0

;Equates
LabelColumn1	equ	32
LabelColumn2	equ	64
DataColumn1		equ	42
DataColumn2		equ	74
