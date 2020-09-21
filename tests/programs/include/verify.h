#ifndef __VERIFY_H__
#define __VERIFY_H__

// https://github.com/riscv/riscv-tests/blob/master/benchmarks/common/util.h

#ifndef typeof
#define typeof __typeof__
#endif

#define static_assert(cond) switch(0) { case 0: case !!(long)(cond): ; }

static inline int verify(int n, const volatile int* test, const int* verify)
{
  int i;
  // Unrolled for faster verification
  for (i = 0; i < n/2*2; i+=2)
  {
    int t0 = test[i], t1 = test[i+1];
    int v0 = verify[i], v1 = verify[i+1];
    if (t0 != v0) return i+1;
    if (t1 != v1) return i+2;
  }
  if (n % 2 != 0 && test[n-1] != verify[n-1])
    return n;
  return 0;
}

static inline int verify_u(int n, const volatile unsigned int* test, const unsigned int* v)
{
    return verify(n, (const volatile int*)test, (const int*)v);
}

#endif

