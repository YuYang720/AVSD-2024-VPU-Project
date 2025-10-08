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

void swap(int16_t* a, int16_t* b) {
    int16_t temp = *a;
    *a = *b;
    *b = temp;
}

int partition(int16_t* arr, int low, int high) {
    int p = arr[low];
    int i = low;
    int j = high;

    while (i < j) {
        while (arr[i] <= p && i <= high - 1) {
            i++;
        }

        while (arr[j] > p && j >= low + 1) {
            j--;
        }
        if (i < j) {
            swap(&arr[i], &arr[j]);
        }
    }
    swap(&arr[low], &arr[j]);
    return j;
}

void quickSort(int16_t* arr, int low, int high) {
    if (low < high) {
        int pivot = partition(arr, low, high);
        quickSort(arr,       low, pivot - 1);
        quickSort(arr, pivot + 1,      high);
    }
}

int main() {
    extern unsigned int array_size, array_addr;
    extern unsigned int _test_start;

    int16_t *arr = (int16_t*)(&array_addr );
    int16_t *ans = (int16_t*)(&_test_start);

    quickSort(arr, 0, array_size - 1);

    for (int i = 0; i < array_size; i++) {
        ans[i] = arr[i];
    }

    return 0;
}

