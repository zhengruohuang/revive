#ifndef __DEBUG_HH__
#define __DEBUG_HH__


#include <cstdio>
#include <iostream>


extern void forceTerminate();


static inline void debug_print() { std::cout << std::endl; }

template<typename First, typename ...Rest>
static inline void debug_print(First &&first, Rest && ...rest)
{
    std::cout << std::forward<First>(first);
    debug_print(std::forward<Rest>(rest)...);
}


/*
 * Panic
 */
#define panic(...)                                                  \
    do {                                                            \
        std::cout << "[PANIC] Condition: always"                    \
                  << ", file: " << __FILE__                         \
                  << ", line: " << __LINE__ << std::endl;           \
        debug_print(__VA_ARGS__);                                   \
        forceTerminate();                                           \
    } while (0)

#define panic_if(cond, ...)                                         \
    do {                                                            \
        if (cond) {                                                 \
            std::cout << "[PANIC] Condition: " << #cond             \
                      << ", file: " << __FILE__                     \
                      << ", line: " << __LINE__ << std::endl;       \
            debug_print(__VA_ARGS__);                               \
            exit(-1);                                               \
        }                                                           \
    } while (0)


/*
 * Assert
 */
#ifdef assert
#undef assert
#endif

#ifdef NDEBUG

#define assert(cond)                                                \
    do {                                                            \
        if (!(cond)) {                                              \
            std::cout << "[ASSERT] Failed: " << #cond               \
                      << ", file: " << __FILE__                     \
                      << ", line: " << __LINE__ << std::endl;       \
            exit(-1);                                               \
        }                                                           \
    } while (0)

#define assert_if(cond, ...)                                        \
    do {                                                            \
        if (!(cond)) {                                              \
            std::cout << "[ASSERT] Failed: " << #cond               \
                      << ", file: " << __FILE__                     \
                      << ", line: " << __LINE__ << std::endl;       \
            debug_print(__VA_ARGS__);                               \
            exit(-1);                                               \
        }                                                           \
    } while (0)

#else

#define assert(cond)
#define assert_if(cond, ...)

#endif


#endif

