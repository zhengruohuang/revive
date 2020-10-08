#include "inttypes.h"
#include "sim_ctrl.h"
#include "io.h"

#define UART_DATA (SIM_UART0_START + 0x0ul)

void uart_putchar(int ch)
{
    volatile char *buf = (void *)UART_DATA;
    *buf = (char)ch;
}

int uart_getchar()
{
    volatile char *buf = (void *)UART_DATA;
    char ch = *buf;
    return ch;
}

