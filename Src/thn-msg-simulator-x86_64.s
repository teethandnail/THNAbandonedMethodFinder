//
//  thn-msg-arm-x86_64.s
//  RealmDemo
//
//  Created by ZhangHonglin on 2017/8/17.
//  Copyright © 2017年 chengdao.enc. All rights reserved.
//

#include <TargetConditionals.h>
#if __x86_64__  &&  TARGET_OS_SIMULATOR

.data
.align 4



/********************************************************************
 * List every exit insn from every messenger for debugger use.
 * Format:
 * (
 *   1 word instruction's address
 *   1 word type (ENTER or FAST_EXIT or SLOW_EXIT or NIL_EXIT)
 * )
 * 1 word zero
 *
 * ENTER is the start of a dispatcher
 * FAST_EXIT is method dispatch
 * SLOW_EXIT is uncached method lookup
 * NIL_EXIT is returning zero from a message sent to nil
 * These must match objc-gdb.h.
 ********************************************************************/

#define ENTER     1
#define FAST_EXIT 2
#define SLOW_EXIT 3
#define NIL_EXIT  4

.section __DATA,__objc_msg_break
.globl _gdb_objc_messenger_breakpoints
_gdb_objc_messenger_breakpoints:
// contents populated by the macros below

.macro MESSENGER_START
4:
.section __DATA,__objc_msg_break
.quad 4b
.quad ENTER
.text
.endmacro
.macro MESSENGER_END_FAST
4:
.section __DATA,__objc_msg_break
.quad 4b
.quad FAST_EXIT
.text
.endmacro
.macro MESSENGER_END_SLOW
4:
.section __DATA,__objc_msg_break
.quad 4b
.quad SLOW_EXIT
.text
.endmacro
.macro MESSENGER_END_NIL
4:
.section __DATA,__objc_msg_break
.quad 4b
.quad NIL_EXIT
.text
.endmacro




/********************************************************************
 * Recommended multi-byte NOP instructions
 * (Intel 64 and IA-32 Architectures Software Developer's Manual Volume 2B)
 ********************************************************************/
#define nop1 .byte 0x90
#define nop2 .byte 0x66,0x90
#define nop3 .byte 0x0F,0x1F,0x00
#define nop4 .byte 0x0F,0x1F,0x40,0x00
#define nop5 .byte 0x0F,0x1F,0x44,0x00,0x00
#define nop6 .byte 0x66,0x0F,0x1F,0x44,0x00,0x00
#define nop7 .byte 0x0F,0x1F,0x80,0x00,0x00,0x00,0x00
#define nop8 .byte 0x0F,0x1F,0x84,0x00,0x00,0x00,0x00,0x00
#define nop9 .byte 0x66,0x0F,0x1F,0x84,0x00,0x00,0x00,0x00,0x00


/********************************************************************
 * Names for parameter registers.
 ********************************************************************/

#define a1  rdi
#define a1d edi
#define a1b dil
#define a2  rsi
#define a2d esi
#define a2b sil
#define a3  rdx
#define a3d edx
#define a4  rcx
#define a4d ecx
#define a5  r8
#define a5d r8d
#define a6  r9
#define a6d r9d


/********************************************************************
 * Names for relative labels
 * DO NOT USE THESE LABELS ELSEWHERE
 * Reserved labels: 6: 7: 8: 9:
 ********************************************************************/
#define LCacheMiss 	6
#define LCacheMiss_f 	6f
#define LCacheMiss_b 	6b
#define LGetIsaDone 	7
#define LGetIsaDone_f 	7f
#define LGetIsaDone_b 	7b
#define LNilOrTagged 	8
#define LNilOrTagged_f 	8f
#define LNilOrTagged_b 	8b
#define LNil		9
#define LNil_f		9f
#define LNil_b		9b

/********************************************************************
 * Macro parameters
 ********************************************************************/

#define NORMAL 0
#define FPRET 1
#define FP2RET 2
#define STRET 3

#define CALL 100
#define GETIMP 101
#define LOOKUP 102


/********************************************************************
 *
 * Structure definitions.
 *
 ********************************************************************/

// objc_super parameter to sendSuper
#define receiver 	0
#define class 		8

// Selected field offsets in class structure
// #define isa		0    USE GetIsa INSTEAD

// Method descriptor
#define method_name 	0
#define method_imp 	16


//////////////////////////////////////////////////////////////////////
//
// ENTRY		functionName
//
// Assembly directives to begin an exported function.
//
// Takes: functionName - name of the exported function
//////////////////////////////////////////////////////////////////////

.macro ENTRY
.text
.globl	$0
.align	6, 0x90
$0:
.endmacro


//////////////////////////////////////////////////////////////////////
//
// END_ENTRY	functionName
//
// Assembly directives to end an exported function.  Just a placeholder,
// a close-parenthesis for ENTRY, until it is needed for something.
//
// Takes: functionName - name of the exported function
//////////////////////////////////////////////////////////////////////

.macro END_ENTRY
LExit$0:
.endmacro


/////////////////////////////////////////////////////////////////////
//
// CacheLookup	return-type, caller
//
// Locate the implementation for a class in a selector's method cache.
//
// Takes:
//	  $0 = NORMAL, FPRET, FP2RET, STRET
//	  $1 = CALL, LOOKUP, GETIMP
//	  a1 or a2 (STRET) = receiver
//	  a2 or a3 (STRET) = selector
//	  r10 = class to search
//
// On exit: r10 clobbered
//	    (found) calls or returns IMP in r11, eq/ne set for forwarding
//	    (not found) jumps to LCacheMiss, class still in r10
//
/////////////////////////////////////////////////////////////////////

.macro CacheHit

// CacheHit must always be preceded by a not-taken `jne` instruction
// in order to set the correct flags for _objc_msgForward_impcache.

// r11 = found bucket

.if $1 == GETIMP
movq	8(%r11), %rax		// return imp
ret

.else

.if $0 != STRET
// eq already set for forwarding by `jne`
.else
test	%r11, %r11		// set ne for stret forwarding
.endif

.if $1 == CALL
MESSENGER_END_FAST
jmp	*8(%r11)		// call imp

.elseif $1 == LOOKUP
movq	8(%r11), %r11		// return imp
ret

.else
.abort oops
.endif

.endif

.endmacro


.macro	CacheLookup
.if $0 != STRET
movq	%a2, %r11		// r11 = _cmd
.else
movq	%a3, %r11		// r11 = _cmd
.endif
andl	24(%r10), %r11d		// r11 = _cmd & class->cache.mask
shlq	$$4, %r11		// r11 = offset = (_cmd & mask)<<4
addq	16(%r10), %r11		// r11 = class->cache.buckets + offset

.if $0 != STRET
cmpq	(%r11), %a2		// if (bucket->sel != _cmd)
.else
cmpq	(%r11), %a3		// if (bucket->sel != _cmd)
.endif
jne 	1f			//     scan more
// CacheHit must always be preceded by a not-taken `jne` instruction
CacheHit $0, $1			// call or return imp

1:
// loop
cmpq	$$1, (%r11)
jbe	3f			// if (bucket->sel <= 1) wrap or miss

addq	$$16, %r11		// bucket++
2:
.if $0 != STRET
cmpq	(%r11), %a2		// if (bucket->sel != _cmd)
.else
cmpq	(%r11), %a3		// if (bucket->sel != _cmd)
.endif
jne 	1b			//     scan more
// CacheHit must always be preceded by a not-taken `jne` instruction
CacheHit $0, $1			// call or return imp

3:
// wrap or miss
jb	LCacheMiss_f		// if (bucket->sel < 1) cache miss
// wrap
movq	8(%r11), %r11		// bucket->imp is really first bucket
jmp 	2f

// Clone scanning loop to miss instead of hang when cache is corrupt.
// The slow path may detect any corruption and halt later.

1:
// loop
cmpq	$$1, (%r11)
jbe	3f			// if (bucket->sel <= 1) wrap or miss

addq	$$16, %r11		// bucket++
2:
.if $0 != STRET
cmpq	(%r11), %a2		// if (bucket->sel != _cmd)
.else
cmpq	(%r11), %a3		// if (bucket->sel != _cmd)
.endif
jne 	1b			//     scan more
// CacheHit must always be preceded by a not-taken `jne` instruction
CacheHit $0, $1			// call or return imp

3:
// double wrap or miss
jmp	LCacheMiss_f

.endmacro

/********************************************************************
 * IMP thn_cache_getImp(Class cls, SEL sel)
 *
 * On entry:	a1 = class whose cache is to be searched
 *		a2 = selector to search for
 *
 * If found, returns method implementation.
 * If not found, returns NULL.
 ********************************************************************/

ENTRY _thn_cache_getImp

// do lookup
movq	%a1, %r10		// move class to r10 for CacheLookup
CacheLookup NORMAL, GETIMP	// returns IMP on success

LCacheMiss:
// cache miss, return nil
xorl	%eax, %eax
ret

END_ENTRY _thn_cache_getImp

#endif

