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

    // 讀取中斷狀態寄存器
    asm volatile("csrr %0, %1" : "=r"(mip) : "i"(MIP));

    // 檢查並處理計時器中斷
    if ((mip & MIP_MTIP) >> 7) {
        timer_interrupt_handler(); // 調用計時器中斷處理程序
    }

    // 檢查並處理外部中斷
    if ((mip & MIP_MEIP) >> 11) {
        external_interrupt_handler(); // 調用外部中斷處理程序
    }
}

int main() {
    extern unsigned int array1_size, array1_addr;
    extern unsigned int array2_size, array2_addr;
    extern unsigned int _test_start;

    int8_t *array1 = (int8_t*)(&array1_addr);
    int8_t *array2 = (int8_t*)(&array2_addr);
    int8_t *ans    = (int8_t*)(&_test_start);
    int8_t *ans2   = (int8_t*)(&_test_start + array1_size);


    for (int i = 0; i < array1_size; i += 8) { // 每次處理 8 個元素
        asm volatile (
            "vsetvli t0, %3, e8, m1      \n\t" // 設定向量長度為 e8 (8 位元), m1 (單精度)
            "vle8.v   v1, (%0)           \n\t" // 將 array1 的資料載入到 v1
            "vle8.v   v2, (%1)           \n\t" // 將 array2 的資料載入到 v2
            "vmul.vv  v3, v1, v2         \n\t" // 向量相乘 v3 = v1 * v2
            "vse8.v   v3, (%2)           \n\t" // 將結果存回 ans
            : // 沒有輸出
            : "r"(array1 + i), "r"(array2 + i), "r"(ans + i), "r"(array1_size - i) // 輸入參數
            : "t0", "v1", "v2", "v3" // 使用的暫存器
        );
    }

    // original vec add
    // for (int i = 0; i < array1_size; i++) {
    //     ans[i] = array1[i] + array2[i];
    // }

    return 0;
}



