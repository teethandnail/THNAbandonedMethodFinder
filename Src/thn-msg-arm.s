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

// Set FP=1 on architectures that pass parameters in floating-point registers
#if __ARM_ARCH_7K__
#   define FP 1
#else
#   define FP 0
#endif

#if FP

#   if !__ARM_NEON__
#       error sorry
#   endif

#   define FP_RETURN_ZERO \
vmov.i32  q0, #0  ; \
vmov.i32  q1, #0  ; \
vmov.i32  q2, #0  ; \
vmov.i32  q3, #0

#   define FP_SAVE \
vpush	{q0-q3}

#   define FP_RESTORE \
vpop	{q0-q3}

#else

#   define FP_RETURN_ZERO
#   define FP_SAVE
#   define FP_RESTORE

#endif

// Define SUPPORT_INDEXED_ISA for targets which store the class in the ISA as
// an index in to a class table.
// Note, keep this in sync with objc-config.h.
// FIXME: Remove this duplication.  We should get this from objc-config.h.
#if __ARM_ARCH_7K__ >= 2
#   define SUPPORT_INDEXED_ISA 1
#else
#   define SUPPORT_INDEXED_ISA 0
#endif

// Note, keep these in sync with objc-private.h
#define ISA_INDEX_IS_NPI      1
#define ISA_INDEX_MASK        0x0001FFFC
#define ISA_INDEX_SHIFT       2
#define ISA_INDEX_BITS        15
#define ISA_INDEX_COUNT       (1 << ISA_INDEX_BITS)
#define ISA_INDEX_MAGIC_MASK  0x001E0001
#define ISA_INDEX_MAGIC_VALUE 0x001C0001

.syntax unified

#define MI_EXTERN(var) \
.non_lazy_symbol_pointer                        ;\
L##var##$$non_lazy_ptr:                                 ;\
.indirect_symbol var                            ;\
.long 0

#define MI_GET_EXTERN(reg,var)  \
movw	reg, :lower16:(L##var##$$non_lazy_ptr-7f-4)  ;\
movt	reg, :upper16:(L##var##$$non_lazy_ptr-7f-4)  ;\
7:	add	reg, pc                                      ;\
ldr	reg, [reg]

#define MI_GET_ADDRESS(reg,var)  \
movw	reg, :lower16:(var-7f-4)  ;\
movt	reg, :upper16:(var-7f-4)  ;\
7:	add	reg, pc                                     ;\


.data

#if SUPPORT_INDEXED_ISA

.align 2
.globl _objc_indexed_classes
_objc_indexed_classes:
.fill ISA_INDEX_COUNT, 4, 0

#endif



// _objc_entryPoints and _objc_exitPoints are used by method dispatch
// caching code to figure out whether any threads are actively
// in the cache for dispatching.  The labels surround the asm code
// that do cache lookups.  The tables are zero-terminated.

.align 2


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
7:
.section __DATA,__objc_msg_break
.long 7b
.long ENTER
.text
.endmacro
.macro MESSENGER_END_FAST
7:
.section __DATA,__objc_msg_break
.long 7b
.long FAST_EXIT
.text
.endmacro
.macro MESSENGER_END_SLOW
7:
.section __DATA,__objc_msg_break
.long 7b
.long SLOW_EXIT
.text
.endmacro
.macro MESSENGER_END_NIL
7:
.section __DATA,__objc_msg_break
.long 7b
.long NIL_EXIT
.text
.endmacro


/********************************************************************
 * Names for relative labels
 * DO NOT USE THESE LABELS ELSEWHERE
 * Reserved labels: 6: 7: 8: 9:
 ********************************************************************/
// 6: used by CacheLookup
// 7: used by MI_GET_ADDRESS etc and MESSENGER_START etc
// 8: used by CacheLookup
#define LNilReceiver 	9
#define LNilReceiver_f 	9f
#define LNilReceiver_b 	9b


/********************************************************************
 * Macro parameters
 ********************************************************************/

#define NORMAL 0
#define STRET 1


/********************************************************************
 *
 * Structure definitions.
 *
 ********************************************************************/

/* objc_super parameter to sendSuper */
#define RECEIVER         0
#define CLASS            4

/* Selected field offsets in class structure */
#define ISA              0
#define SUPERCLASS       4
#define CACHE            8
#define CACHE_MASK      12

/* Selected field offsets in method structure */
#define METHOD_NAME      0
#define METHOD_TYPES     4
#define METHOD_IMP       8


//////////////////////////////////////////////////////////////////////
//
// ENTRY		functionName
//
// Assembly directives to begin an exported function.
//
// Takes: functionName - name of the exported function
//////////////////////////////////////////////////////////////////////

.macro ENTRY /* name */
.text
.thumb
.align 5
.globl $0
.thumb_func
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

.macro CacheLookup

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

.macro CacheLookup2

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
CacheLookup NORMAL
// cache hit, IMP in r12
mov	r0, r12
bx	lr			// return imp

CacheLookup2 GETIMP
// cache miss, return nil
mov	r0, #0
bx	lr

END_ENTRY _thn_cache_getImp


#endif
