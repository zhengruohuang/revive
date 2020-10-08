#include <iostream>
#include <thread>
#include <atomic>
#include <csignal>
#include <cstring>
#include <cstdlib>

#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <unistd.h>

static std::atomic<bool> stop;
static int fdRx = -1, fdTx = -1;

static void asyncRx()
{
    while (!stop) {
        fdRx = open("target/uart.pipe2", O_CREAT | O_RDONLY);
        if (fdRx < 0) {
            continue;
        }
        
        while (!stop) {
            char ch = 0; // = getchar();
            int cnt = ::read(fdRx, &ch, 1);
            if (!cnt) {
                std::cerr << "[TERM] Receiver pipe broken" << std::endl;
                break;
            }
            
            std::cout << ch << std::flush;
        }
    }
}

static void asyncTx()
{
    while (!stop) {
        fdTx = open("target/uart.pipe1", O_CREAT | O_WRONLY);
        if (fdTx < 0) {
            continue;
        }
        
        while (!stop) {
            char ch = getchar();
            int cnt = ::write(fdTx, &ch, 1);
            if (!cnt) {
                std::cerr << "[TERM] Transmitter pipe broken" << std::endl;
                break;
            }
        }
    }
}

static void sigintHandler(int sig_num)
{
    stop = true;
    close(fdRx);
    close(fdTx);
    exit(0);
}

int main(int argc, char *argv[])
{
    signal(SIGINT, sigintHandler);
    signal(SIGPIPE, SIG_IGN);
    stop = false;
    
    std::thread *asyncRxThread = new std::thread(&asyncRx);
    if (!asyncRxThread) {
        return -1;
    }
    
    std::thread *asyncTxThread = new std::thread(&asyncTx);
    if (!asyncTxThread) {
        return -1;
    }
    
    asyncRxThread->join();
    asyncTxThread->join();
}

