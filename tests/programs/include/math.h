#ifndef __MATH_H__
#define __MATH_H__


#include "inttypes.h"


/*
 * Alignment
 */
#define ALIGN_UP(s, a)      (((s) + ((a) - 1)) & ~((a) - 1))
#define ALIGN_DOWN(s, a)    ((s) & ~((a) - 1))
#define ALIGNED(s, a)       (!((s) & ((a) - 1)))


/*
 * Bit
 */
extern u16 swap_endian16(u16 val);
extern u32 swap_endian32(u32 val);
extern u64 swap_endian64(u64 val);
extern ulong swap_endian(ulong val);
extern u16 swap_big_endian16(u16 val);
extern u32 swap_big_endian32(u32 val);
extern u64 swap_big_endian64(u64 val);
extern ulong swap_big_endian(ulong val);
extern u16 swap_little_endian16(u16 val);
extern u32 swap_little_endian32(u32 val);
extern u64 swap_little_endian64(u64 val);
extern ulong swap_little_endian(ulong val);

extern int popcount64(u64 val);
extern int popcount32(u32 val);
extern int popcount16(u16 val);
extern int popcount(ulong val);

extern int clz64(u64 val);
extern int clz32(u32 val);
extern int clz16(u16 val);
extern int clz(ulong val);

extern int ctz64(u64 val);
extern int ctz32(u32 val);
extern int ctz16(u16 val);
extern int ctz(ulong val);


/*
 * Math
 */
extern u32 mul_u32(u32 a, u32 b);
extern s32 mul_s32(s32 a, s32 b);
extern u64 mul_u64(u64 a, u64 b);
extern s64 mul_s64(s64 a, s64 b);
extern ulong mul_ulong(ulong a, ulong b);
extern ulong mul_long(long a, long b);

extern void div_u32(u32 a, u32 b, u32 *qout, u32 *rout);
extern void div_s32(s32 a, s32 b, s32 *qout, s32 *rout);
extern void div_u64(u64 a, u64 b, u64 *qout, u64 *rout);
extern void div_s64(s64 a, s64 b, s64 *qout, s64 *rout);
extern void div_ulong(ulong a, ulong b, ulong *qout, ulong *rout);
extern void div_long(long a, long b, long *qout, long *rout);

extern u64 quo_u64(u64 a, u64 b);
extern u64 quo_s64(s64 a, s64 b);
extern u32 quo_u32(u32 a, u32 b);
extern u64 quo_s32(s32 a, s32 b);
extern ulong quo_ulong(ulong a, ulong b);
extern long quo_long(long a, long b);

extern u64 rem_u64(u64 a, u64 b);
extern u64 rem_s64(s64 a, s64 b);
extern u32 rem_u32(u32 a, u32 b);
extern u64 rem_s32(s32 a, s32 b);
extern ulong rem_ulong(ulong a, ulong b);
extern long rem_long(long a, long b);


#endif
