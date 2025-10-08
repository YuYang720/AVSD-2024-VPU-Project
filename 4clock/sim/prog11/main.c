#include <stdint.h>

#define MIP_MEIP (1 << 11) // External interrupt pending
#define MIP_MTIP (1 << 7)  // Timer interrupt pending
#define MIP 0x344

void timer_interrupt_handler(void) {
    volatile unsigned int *WDT_addr = (int *) 0x10010000;
    asm("csrsi mstatus, 0x0"); // MIE of mstatus
    WDT_addr[0x40] = 0;        // WDT_en
    asm("j _start");
}

void external_interrupt_handler(void) {
    volatile unsigned int *dma_addr_boot = (int *) 0x10020000;
    asm("csrsi mstatus, 0x0"); // MIE of mstatus
    dma_addr_boot[0x40] = 0;   // disable DMA
}

void trap_handler(void) {
    uint32_t mip;

    // Read the interrupt status register
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
    extern unsigned int input_array_size, input_array_addr;
    extern unsigned int _test_start;

    int8_t *array1 = (int8_t*)(&input_array_addr); // Input array
    int8_t *ans    = (int8_t*)(&_test_start);      // Output array (ReLU result)

    for (int i = 0; i < input_array_size; i += 8) { // Process 8 elements at a time
        asm volatile (
            "vsetvli t0, %2, e8, m1      \n\t" // Set vector length to e8 (8 bits), m1 (single width)
            "vle8.v   v1, (%0)           \n\t" // Load array1's data into vector register v1
            "vmv.v.i  v2, 0              \n\t" // Set all elements in v2 to 0 (used for comparison)
            "vmax.vv  v3, v1, v2         \n\t" // Perform ReLU: v3 = max(v1, 0)
            "vse8.v   v3, (%1)           \n\t" // Store the result into ans
            : // No outputs
            : "r"(array1 + i), "r"(ans + i), "r"(input_array_size - i) // Input parameters
            : "t0", "v1", "v2", "v3" // Registers used
        );
    }

    // Scalar fallback (optional, for debugging or environments without vector support)
    // for (int i = 0; i < array1_size; i++) {
    //     ans[i] = (array1[i] > 0) ? array1[i] : 0; // Apply ReLU manually
    // }

    return 0;
}
