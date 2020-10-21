#include <iostream>
#include <iomanip>
#include <fstream>
#include <vector>
#include <cstdint>
#include <cstring>
#include <csignal>

#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <unistd.h>

#include "sim.hh"
#include "as.hh"
#include "uart.hh"
#include "debug.hh"


UniAsyncRxTx::UniAsyncRxTx(const char *name, ArgParser *cmd, int uart_idx,
                           uint64_t start, uint64_t size)
    : AddressRange(name, cmd), outf(nullptr)
{
    cmd->addString("uart_out", "", "--uart-out", "target/uart.txt");
    
    setRange(start, size);
    
    rxbufIdxRd = rxbufIdxWr = 0;
    ::memset(rxbuf, 0, sizeof(rxbuf));
    
    txbufIdxRd = txbufIdxWr = 0;
    ::memset(txbuf, 0, sizeof(txbuf));
    
    fdRx = fdTx = -1;
    asyncRxThread = nullptr;
    asyncTxThread = nullptr;
}

UniAsyncRxTx::~UniAsyncRxTx()
{
}

int
UniAsyncRxTx::startup()
{
    const char *out_filename = cmd->get("uart_out")->valueString;
    if (strcmp(out_filename, "none")) {
        outf = openOutputFile(out_filename);
        if (!outf) {
            return -1;
        }
    }
    
    signal(SIGPIPE, SIG_IGN);
    
    asyncRxThread = new std::thread(&UniAsyncRxTx::asyncRx, this);
    if (!asyncRxThread) {
        return -1;
    }
    
    asyncTxThread = new std::thread(&UniAsyncRxTx::asyncTx, this);
    if (!asyncTxThread) {
        return -1;
    }
    
    return 0;
}

int
UniAsyncRxTx::cleanup()
{
    close(fdTx);
    close(fdRx);
    signal(SIGINT, SIG_DFL);
    
    if (outf) {
        fclose(outf);
    }
    
    return 0;
}

uint64_t
UniAsyncRxTx::read_atomic(uint64_t addr, int size)
{
#if __BYTE_ORDER__ == __ORDER_BIG_ENDIAN__
    #error "Big endian not supported!"
#endif
    
    uint64_t offset = addr - getStart();
    panic_if(offset & (size - 1), "Unaligned atomic read addr @ ", addr);
    
    if (offset == UART_DATA) {
        if (rxbufIdxRd >= rxbufIdxWr) {
            return 0;
        } else {
            char ch = rxbuf[rxbufIdxRd % RXBUF_SIZE];
            rxbufIdxRd++;
            return (unsigned char)ch;
        }
    }
    
    return 0;
}

void
UniAsyncRxTx::write_atomic(uint64_t addr, int size, uint64_t data)
{
#if __BYTE_ORDER__ == __ORDER_BIG_ENDIAN__
    #error "Big endian not supported!"
#endif
    
    uint64_t offset = addr - getStart();
    panic_if(offset & (size - 1), "Unaligned atomic write addr @ ", addr);
    
    if (offset == UART_DATA) {
        char ch = (char)data;
        if (outf) {
            fprintf(outf, "%c", ch);
            fflush(outf);
        }
        //out << ch << std::flush;
        //std::cout << ch << std::flush;
        if (txbufIdxWr - txbufIdxRd >= TXBUF_SIZE) {
            txbufIdxRd++;
        }
        txbuf[txbufIdxWr % TXBUF_SIZE] = ch;
        txbufIdxWr++;
    }
}

void
UniAsyncRxTx::asyncRx()
{
    while (true) {
        fdRx = open("target/uart.pipe1", O_CREAT | O_RDONLY);
        if (fdRx < 0) {
            continue;
        }
        
        while (true) {
            char ch = 0; // = getchar();
            int cnt = ::read(fdRx, &ch, 1);
            if (!cnt) {
                break;
            }
            
            while (rxbufIdxWr - rxbufIdxRd >= RXBUF_SIZE) {
                std::this_thread::yield();
            }
            
            if (cnt && ch) {
                rxbuf[rxbufIdxWr % RXBUF_SIZE] = ch;
                rxbufIdxWr++;
            }
        }
    }
}

void
UniAsyncRxTx::asyncTx()
{
    while (true) {
        fdTx = open("target/uart.pipe2", O_CREAT | O_WRONLY);
        if (fdTx < 0) {
            continue;
        }
        
        while (true) {
            while (txbufIdxWr <= txbufIdxRd) {
                std::this_thread::sleep_for(std::chrono::milliseconds(10));
            }
            
            char ch = txbuf[txbufIdxRd % TXBUF_SIZE];
            txbufIdxRd++;
            int cnt = ::write(fdTx, &ch, 1);
            if (!cnt) {
                break;
            }
        }
    }
}

