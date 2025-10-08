#include <stdint.h>

#define MIP_MEIP (1 << 11) // External interrupt pending
#define MIP_MTIP (1 << 7)  // Timer interrupt pending
#define MIP 0x344

void timer_interrupt_handler(void) {
    volatile unsigned int *WDT_addr = (int *)0x10010000;
    asm("csrsi mstatus, 0x0"); // Disable interrupts in mstatus
    WDT_addr[0x40] = 0;        // Disable WDT
    asm("j _start");
}

void external_interrupt_handler(void) {
    volatile unsigned int *dma_addr_boot = (int *)0x10020000;
    asm("csrsi mstatus, 0x0"); // Disable interrupts in mstatus
    dma_addr_boot[0x40] = 0;   // Disable DMA
}

void trap_handler(void) {
    uint32_t mip;

    // Read the interrupt pending register
    asm volatile("csrr %0, %1" : "=r"(mip) : "i"(MIP));

    // Handle timer interrupt
    if ((mip & MIP_MTIP) >> 7) {
        timer_interrupt_handler();
    }

    // Handle external interrupt
    if ((mip & MIP_MEIP) >> 11) {
        external_interrupt_handler();
    }
}

int main() {
    asm volatile (
        "la              s0, _test_start            \n\t"
        "la              a0, vadd64_data            \n\t"
        "li              t0, 2                      \n\t"
        "vsetvli         x0, t0, e64, m2, tu, mu    \n\t"
        "vle64.v         v8, (a0)                   \n\t"
        "vse64.v         v8, (s0)                   \n\t"
        "addi            s0, s0, 16                 \n\t"
        "li              t0, 1                      \n\t"
        "vsetvli         x0, t0, e64, m1, tu, mu    \n\t"
        "vadd.vv         v0, v8, v9                 \n\t"
        "vsub.vv         v1, v8, v9                 \n\t"
        "li              t0, 2                      \n\t"
        "vsetvli         x0, t0, e64, m2, tu, mu    \n\t"
        "vse64.v         v0, (s0)                   \n\t"
        "addi            s0, s0, 16                 \n\t"
    : // No output operands
    : // Input operands
    : // Clobbered registers
    );

    return 0;
}