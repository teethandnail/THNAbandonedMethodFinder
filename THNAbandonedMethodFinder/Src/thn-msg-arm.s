//
//  zhl-msg.s
//  RealmDemo
//
//  Created by ZhangHonglin on 2017/8/17.
//  Copyright © 2017年 chengdao.enc. All rights reserved.
//


#ifdef __arm__

#include <arm/arch.h>

#ifndef _ARM_ARCH_7
#   error requires armv7
#endif


.data

#if SUPPORT_INDEXED_ISA

.align 2
.globl _objc_indexed_classes
_objc_indexed_classes:
.fill ISA_INDEX_COUNT, 4, 0

#endif

.macro ENTRY /* name */
.text
.thumb
.align 5
.globl $0
.thumb_func
$0:
.endmacro

.macro END_ENTRY /* name */
LExit$0:
.endmacro



/////////////////////////////////////////////////////////////////////
//
// CacheLookup	NORMAL|STRET
// CacheLookup2	NORMAL|STRET
//
// Locate the implementation for a selector in a class's method cache.
//
// Takes:
//	  $0 = NORMAL, STRET
//	  r0 or r1 (STRET) = receiver
//	  r1 or r2 (STRET) = selector
//	  r9 = class to search in
//
// On exit: r9 clobbered
//	    (found) continues after CacheLookup, IMP in r12, eq set
//	    (not found) continues after CacheLookup2
//
/////////////////////////////////////////////////////////////////////

.macro ThnCacheLookup

ldrh	r12, [r9, #CACHE_MASK]	// r12 = mask
ldr	r9, [r9, #CACHE]	// r9 = buckets
.if $0 == STRET
and	r12, r12, r2		// r12 = index = SEL & mask
.else
and	r12, r12, r1		// r12 = index = SEL & mask
.endif
add	r9, r9, r12, LSL #3	// r9 = bucket = buckets+index*8
ldr	r12, [r9]		// r12 = bucket->sel
6:
.if $0 == STRET
teq	r12, r2
.else
teq	r12, r1
.endif
bne	8f
ldr	r12, [r9, #4]		// r12 = bucket->imp

.if $0 == STRET
tst	r12, r12		// set ne for stret forwarding
.else
// eq already set for nonstret forwarding by `teq` above
.endif

.endmacro

.macro ThnCacheLookup2

8:
cmp	r12, #1
blo	8f			// if (bucket->sel == 0) cache miss
it	eq			// if (bucket->sel == 1) cache wrap
ldreq	r9, [r9, #4]		// bucket->imp is before first bucket
ldr	r12, [r9, #8]!		// r12 = (++bucket)->sel
b	6b
8:

.endmacro



/********************************************************************
 * IMP thn_cache_getImp(Class cls, SEL sel)
 *
 * On entry:    r0 = class whose cache is to be searched
 *              r1 = selector to search for
 *
 * If found, returns method implementation.
 * If not found, returns NULL.
 ********************************************************************/

ENTRY _thn_cache_getImp

mov	r9, r0
ThnCacheLookup NORMAL
// cache hit, IMP in r12
mov	r0, r12
bx	lr			// return imp

ThnCacheLookup2 GETIMP
// cache miss, return nil
mov	r0, #0
bx	lr

END_ENTRY _thn_cache_getImp

#endif
