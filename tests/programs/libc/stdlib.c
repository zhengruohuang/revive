#include "inttypes.h"
#include "stddef.h"
#include "math.h"
#include "bare.h"


/*
 * Digit and alpha
 */
int isdigit(int ch)
{
    return ch && (ch >= '0' && ch <= '9');
}

int isxdigit(int ch)
{
    return ch && (
        (ch >= '0' && ch <= '9') ||
        (ch >= 'a' && ch <= 'f') ||
        (ch >= 'A' && ch <= 'F')
    );
}


/*
 * String to number
 */
u64 stou64(const char *str, int base)
{
    if (!str || !*str) {
        return 0;
    }

    int neg = 0;
    if (*str == '-') {
        str++;
        neg = 1;
    }

    if ((base == 0 || base == 16) &&
        (str[0] == '0' && (str[1] == 'x' || str[1] == 'X'))
    ) {
        str += 2;
        base = 16;
    }

    u64 num = 0;
    for (char ch = *str; isxdigit(ch); ch = *++str) {
        if (base == 16) {
            num *= 16ull;
        } else {
            num *= 10ull;
        }

        if (ch >= '0' && ch <= '9') {
            num += ch - '0';
        } else if (base == 16 && ch >= 'a' && ch <= 'f') {
            num += ch - 'a' + 10;
        } else if (base == 16 && ch >= 'A' && ch <= 'F') {
            num += ch - 'A' + 10;
        }
    }

    return neg ? -num : num;
}

u32 stou32(const char *str, int base)
{
    return (u32)stou64(str, base);
}

ulong stoul(const char *str, int base)
{
    return (ulong)stou64(str, base);
}

int stoi(const char *str, int base)
{
    return (int)stou64(str, base);
}

int atoi(const char *str)
{
    return stoi(str, 10);
}

ulong atol(const char *str)
{
    return stoul(str, 10);
}

u64 atoll(const char *str)
{
    return stou64(str, 10);
}


/*
 * Terminate
 */
void abort()
{
    sim_term(-1);
}

void exit(int status)
{
    sim_term(status);
}


/*
 * Rand
 */
static u32 rand_state = 0;

int rand()
{
    rand_state = mul_u32(rand_state, 1103515245u) + 12345u;
    return rand_state & 0x7fffffff;
}

int rand_r(u32 *seedp)
{
    if (!seedp) {
        return 0;
    }

    u32 r = *seedp;
    r = mul_u32(r, 1103515245u) + 12345u;
    *seedp = r;
    return r & 0x7fffffff;
}

void srand(u32 seed)
{
    rand_state = seed;
}

