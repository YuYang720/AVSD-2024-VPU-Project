#include <stdint.h>

#define MIP_MEIP (1 << 11) // External interrupt pending
#define MIP_MTIP (1 << 7 ) // Timer interrupt pending
#define MIP 0x344

volatile unsigned int *WDT_addr      = (int *) 0x10010000;
volatile unsigned int *dma_addr_boot = (int *) 0x10020000;

void timer_interrupt_handler(void) {
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
    asm volatile("csrr %0, %1" : "=r"(mip) : "i"(MIP));

    if ((mip & MIP_MTIP) >> 7) {
        timer_interrupt_handler();
    }

    if ((mip & MIP_MEIP) >> 11) {
        external_interrupt_handler();
    }
}

int main(void) {
    extern unsigned int _test_start;
    extern unsigned int _binary_image_bmp_start;
    extern unsigned int _binary_image_bmp_end;
    extern unsigned int _binary_image_bmp_size;

    uint8_t* image_addr = (uint8_t*)(&_binary_image_bmp_start);
    uint8_t* gray_image = (uint8_t*)(&_test_start);
    uint32_t image_size = (uint32_t)(&_binary_image_bmp_size);
    uint8_t  b, g, r, gray;

    for (int i = 0; i < image_size; i += 3) {
        
        // Store the first 54 byte header
        if(i < 54) {
            gray_image[i    ] = image_addr[i    ];
            gray_image[i + 1] = image_addr[i + 1];
            gray_image[i + 2] = image_addr[i + 2];

        } else {
            // Read out rgb
            b = image_addr[i    ];
            g = image_addr[i + 1];
            r = image_addr[i + 2];
            
            // Turn to gray scale
            gray = (11 * b + 59 * g + 30 * r) / 100;

            // Store the gray scale
            gray_image[i    ] = gray;
            gray_image[i + 1] = gray;
            gray_image[i + 2] = gray;
        }
    }

    return 0;
}
