#ifndef __UniAsyncRxTx_HH__
#define __UniAsyncRxTx_HH__


#include <cstdio>
#include <vector>
#include <atomic>
#include <thread>
#include "sim.hh"


class UniAsyncRxTx: public AddressRange
{
private:
    const uint64_t UART_DATA = 0;
    
    FILE *outf;
    
    static const uint64_t RXBUF_SIZE = 16384;
    char rxbuf[RXBUF_SIZE];
    std::atomic<uint64_t> rxbufIdxRd, rxbufIdxWr;
    
    static const uint64_t TXBUF_SIZE = 16384;
    char txbuf[TXBUF_SIZE];
    std::atomic<uint64_t> txbufIdxRd, txbufIdxWr;
    
    int fdRx, fdTx;
    std::thread *asyncRxThread, *asyncTxThread;
    void asyncRx();
    void asyncTx();

public:
    UniAsyncRxTx(const char *name, ArgParser *cmd, int uart_idx, uint64_t start, uint64_t size);
    ~UniAsyncRxTx();
    
    virtual int startup() override;
    virtual int cleanup() override;
    
    virtual uint64_t read_atomic(uint64_t addr, int size) override;
    virtual void write_atomic(uint64_t addr, int size, uint64_t data) override;
};


#endif

