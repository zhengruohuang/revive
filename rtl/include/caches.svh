`ifndef __CACHE_SVH__
`define __CACHE_SVH__


`include "include/config.svh"
`include "include/ps.svh"


/*
 * Common types
 */
`define VPN_WIDTH   (`VADDR_WIDTH - `PAGE_SIZE_BITS)
`define PPN_WIDTH   (`PADDR_WIDTH - `PAGE_SIZE_BITS)

typedef logic [`VADDR_WIDTH - 1:0]      vaddr_t;
typedef logic [`PADDR_WIDTH - 1:0]      paddr_t;

typedef logic [`VPN_WIDTH - 1:0]        vpn_t;
typedef logic [`PPN_WIDTH - 1:0]        ppn_t;

typedef logic [`CACHELINE_WIDTH - 1:0]  cacheline_t;

function paddr_t compose_paddr;
    input ppn_t     ppn;
    input vaddr_t   vaddr;
    begin
        compose_paddr = { ppn, vaddr[`PAGE_SIZE_BITS - 1:0] };
    end
endfunction

function ppn_t compose_ppn;
    input paddr_t   paddr;
    begin
        compose_ppn = paddr[`PADDR_WIDTH - 1:`PAGE_SIZE_BITS];
    end
endfunction

/*
 * ITLB
 */
`define ITLB_VPN_TAG_WIDTH  (`VPN_WIDTH - `ITLB_SETS_BITS)

typedef logic [`ITLB_VPN_TAG_WIDTH - 1:0] itlb_tag_t;

typedef struct packed {
    logic           cached;
    asid_t          asid;
    itlb_tag_t      vpn;
    logic           valid;
} itlb_tag_entry_t;

typedef struct packed {
    ppn_t           ppn;
} itlb_data_entry_t;

function itlb_tag_entry_t compose_itlb_tag_entry;
    input logic     cached;
    input asid_t    asid;
    input vaddr_t   vaddr;
    input logic     valid;
    begin
        compose_itlb_tag_entry = { cached, asid, vaddr[`VADDR_WIDTH - 1:`VADDR_WIDTH - `ITLB_VPN_TAG_WIDTH], valid };
    end
endfunction


/*
 * ICache
 */
`define ICACHE_PADDR_TAG_WIDTH  (`PADDR_WIDTH - `CACHELINE_SIZE_BITS - `ICACHE_SETS_BITS)
`define ICACHE_DATA_SLOTS       (`CACHELINE_WIDTH / `FETCH_DATA_WIDTH)
`define ICACHE_DATA_SLOTS_BITS  (`CACHELINE_WIDTH_BITS - `FETCH_DATA_WIDTH_BITS)

typedef logic [`ICACHE_PADDR_TAG_WIDTH - 1:0]   icache_tag_t;

typedef struct packed {
    icache_tag_t    tag;
    logic           valid;
} icache_tag_entry_t;

typedef struct packed {
    cacheline_t     data;
} icache_data_entry_t;

function icache_tag_entry_t compose_icache_tag_entry;
    input paddr_t   paddr;
    begin
        compose_icache_tag_entry = { paddr[`PADDR_WIDTH - 1:`PADDR_WIDTH - `ICACHE_PADDR_TAG_WIDTH], 1'b1 };
    end
endfunction


`endif

