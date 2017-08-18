//
//  thn-msg-arm64.s
//  RealmDemo
//
//  Created by ZhangHonglin on 2017/8/17.
//  Copyright © 2017年 chengdao.enc. All rights reserved.
//

#ifdef __arm64__

#include <arm/arch.h>


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


/* objc_super parameter to sendSuper */
#define RECEIVER         0
#define CLASS            8

/* Selected field offsets in class structure */
#define SUPERCLASS       8
#define CACHE            16

/* Selected field offsets in isa field */
#define ISA_MASK         0x0000000ffffffff8

/* Selected field offsets in method structure */
#define METHOD_NAME      0
#define METHOD_TYPES     8
#define METHOD_IMP       16


/********************************************************************
 * ENTRY functionName
 * STATIC_ENTRY functionName
 * END_ENTRY functionName
 ********************************************************************/

.macro ENTRY /* name */
.text
.align 5
.globl    $0
$0:
.endmacro



.macro END_ENTRY /* name */
LExit$0:
.endmacro


/********************************************************************
 *
 * CacheLookup NORMAL|GETIMP|LOOKUP
 *
 * Locate the implementation for a selector in a class method cache.
 *
 * Takes:
 *	 x1 = selector
 *	 x16 = class to be searched
 *
 * Kills:
 * 	 x9,x10,x11,x12, x17
 *
 * On exit: (found) calls or returns IMP
 *                  with x16 = class, x17 = IMP
 *          (not found) jumps to LCacheMiss
 *
 ********************************************************************/

#define NORMAL 0
#define GETIMP 1
#define LOOKUP 2

.macro CacheHit
.if $0 == NORMAL
MESSENGER_END_FAST
br	x17			// call imp
.elseif $0 == GETIMP
mov	x0, x17			// return imp
ret
.elseif $0 == LOOKUP
ret				// return imp via x17
.else
.abort oops
.endif
.endmacro

.macro CheckMiss
// miss if bucket->sel == 0
.if $0 == GETIMP
cbz	x9, LGetImpMiss
.elseif $0 == NORMAL
cbz	x9, __objc_msgSend_uncached
.elseif $0 == LOOKUP
cbz	x9, __objc_msgLookup_uncached
.else
.abort oops
.endif
.endmacro

.macro JumpMiss
.if $0 == GETIMP
b	LGetImpMiss
.elseif $0 == NORMAL
b	__objc_msgSend_uncached
.elseif $0 == LOOKUP
b	__objc_msgLookup_uncached
.else
.abort oops
.endif
.endmacro

.macro CacheLookup
// x1 = SEL, x16 = isa
ldp	x10, x11, [x16, #CACHE]	// x10 = buckets, x11 = occupied|mask
and	w12, w1, w11		// x12 = _cmd & mask
add	x12, x10, x12, LSL #4	// x12 = buckets + ((_cmd & mask)<<4)

ldp	x9, x17, [x12]		// {x9, x17} = *bucket
1:	cmp	x9, x1			// if (bucket->sel != _cmd)
b.ne	2f			//     scan more
CacheHit $0			// call or return imp

2:	// not hit: x12 = not-hit bucket
CheckMiss $0			// miss if bucket->sel == 0
cmp	x12, x10		// wrap if bucket == buckets
b.eq	3f
ldp	x9, x17, [x12, #-16]!	// {x9, x17} = *--bucket
b	1b			// loop

3:	// wrap: x12 = first bucket, w11 = mask
add	x12, x12, w11, UXTW #4	// x12 = buckets+(mask<<4)

// Clone scanning loop to miss instead of hang when cache is corrupt.
// The slow path may detect any corruption and halt later.

ldp	x9, x17, [x12]		// {x9, x17} = *bucket
1:	cmp	x9, x1			// if (bucket->sel != _cmd)
b.ne	2f			//     scan more
CacheHit $0			// call or return imp

2:	// not hit: x12 = not-hit bucket
CheckMiss $0			// miss if bucket->sel == 0
cmp	x12, x10		// wrap if bucket == buckets
b.eq	3f
ldp	x9, x17, [x12, #-16]!	// {x9, x17} = *--bucket
b	1b			// loop

3:	// double wrap
JumpMiss $0

.endmacro

ENTRY _thn_cache_getImp

and	x16, x0, #ISA_MASK
CacheLookup GETIMP

LGetImpMiss:
mov	x0, #0
ret

END_ENTRY _thn_cache_getImp

#endif
