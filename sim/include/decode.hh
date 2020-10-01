#ifndef __DECODE_HH__
#define __DECODE_HH__


/*
 * CSR
 */
struct CSRisa
{
    union {
        uint32_t value;
        
        struct {
            uint32_t a      : 1;    // atomic
            uint32_t b      : 1;    // bit-manuplication
            uint32_t c      : 1;    // compressed
            uint32_t d      : 1;    // double-precision
            uint32_t e      : 1;    // rv32e
            uint32_t f      : 1;    // single-precision
            uint32_t g      : 1;    // additional standard exts
            uint32_t h      : 1;    // hypervisor
            uint32_t i      : 1;    // rv32i base
            uint32_t j      : 1;    // dynamic translated languages
            uint32_t k      : 1;    // reserved
            uint32_t l      : 1;    // decimal floating point
            uint32_t m      : 1;    // integer mul/div
            uint32_t n      : 1;    // user-level interrupts
            uint32_t o      : 1;    // reserved
            uint32_t p      : 1;    // packed SIMD
            uint32_t q      : 1;    // quad-precision
            uint32_t r      : 1;    // reserved
            uint32_t s      : 1;    // supervisor mode
            uint32_t t      : 1;    // transactional memory
            uint32_t u      : 1;    // user mode
            uint32_t v      : 1;    // vector
            uint32_t w      : 1;    // reserved
            uint32_t x      : 1;    // non-std ext
            uint32_t y      : 1;    // reserved
            uint32_t z      : 1;    // reserved
            uint32_t        : 4;
            uint32_t mxl    : 2;    // machine xlen
        };
    };
};

struct CSRstatus
{
    union {
        uint32_t value;
        
        struct {
            uint32_t uie    : 1;    // user global interrupt enabled
            uint32_t sie    : 1;    // supervisor
            uint32_t        : 1;
            uint32_t mie    : 1;    // machine
            uint32_t upie   : 1;    // user previous interrupt enabled
            uint32_t spie   : 1;    // supervisor
            uint32_t        : 1;
            uint32_t mpie   : 1;    // machine
            uint32_t spp    : 1;    // supervisor previous privilege mode
            uint32_t        : 2;
            uint32_t mpp    : 2;    // machine
            uint32_t fs     : 2;    // fp reg state     0=off, 1=init,
            uint32_t xs     : 2;    // ext reg state    2=clean, 3=dirty
            uint32_t mprv   : 1;    // modify privilege
            uint32_t sum    : 1;    // permit supervisor user memory access
            uint32_t mxr    : 1;    // make executable readable
            uint32_t tvm    : 1;    // trap virtual memory
            uint32_t tw     : 1;    // timeout wait
            uint32_t tsr    : 1;    // trap SRET
            uint32_t        : 8;
            uint32_t sd     : 1;    // dirty = fs == 0b11 || xs == 0b11
        };
    };
};

struct CSRint
{
    union {
        uint32_t value;
         \
        struct {
            uint32_t us     : 1;    // user software
            uint32_t ss     : 1;    // supervisor
            uint32_t        : 1;
            uint32_t ms     : 1;    // machine
            uint32_t ut     : 1;    // user timer
            uint32_t st     : 1;    // supervisor
            uint32_t        : 1;
            uint32_t mt     : 1;    // machine
            uint32_t ue     : 1;    // user external
            uint32_t se     : 1;    // supervisor
            uint32_t        : 1;
            uint32_t me     : 1;    // machine
            uint32_t        : 20;
        };
    };
};

struct CSRatp
{
    union {
        uint32_t value;
        
        struct {
            uint32_t ppn    : 22;   // physical page number
            uint32_t asid   : 9;    // addr space identifier
            uint32_t mode   : 1;    // 0 = no trans, 1 = Sv32
        };
    };
};

struct CSRpmp
{
    union {
        uint8_t value;
        
        struct {
            uint8_t read    : 1;
            uint8_t write   : 1;
            uint8_t exec    : 1;
            uint8_t match   : 2;
            uint8_t         : 2;
            uint8_t locked  : 1;
        };
    };
};


#endif

