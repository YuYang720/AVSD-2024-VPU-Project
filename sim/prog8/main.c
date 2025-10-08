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
    extern unsigned int x_size, x_addr, y_addr, alpha;
    extern unsigned int _test_start;

    int8_t *x = (int8_t*)(&x_addr);
    int8_t *y = (int8_t*)(&y_addr);
    int8_t *ans = (int8_t*)(&_test_start);

    uint8_t alpha_value = *((uint8_t*)(&alpha));

    for (int i = 0; i < x_size; i += 64) { // 每次處理 64 個元素 (m8 模式)
        asm volatile (
            "vsetvli t0, %4, e8, m8      \n\t" // 設定向量長度為 e8 (8 位元), m8 (八倍精度)
            "vle8.v   v8, (%0)           \n\t" // 將向量 x 的資料載入到 v8
            "vle8.v   v16, (%1)          \n\t" // 將向量 y 的資料載入到 v16
            "vmacc.vx v16, %3, v8        \n\t" // v16 = alpha * v8 + v16
            "vse8.v   v16, (%2)          \n\t" // 將結果存回 ans
            : // 沒有輸出
            : "r"(x + i), "r"(y + i), "r"(ans + i), "r"(alpha_value), "r"(x_size - i) // 輸入參數
            : "t0", "v8", "v16" // 使用的暫存器
        );
    }

    return 0;
}

