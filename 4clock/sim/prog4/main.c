#include <stdint.h>

#define MIP_MEIP (1 << 11) // External interrupt pending
#define MIP_MTIP (1 << 7)  // Timer interrupt pending
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

int main() {
    extern float frs_pos_0;  // 32-bit float
    extern float frs_pos_1;  // 32-bit float
    extern float frs_pos_2;  // 32-bit float
    extern float frs_neg_0;  // 32-bit float
    extern float frs_neg_1;  // 32-bit float
    extern float frs_neg_2;  // 32-bit float

    extern uint32_t Negative_Infinity ;
    extern uint32_t Negative_Normal   ;
    extern uint32_t Negative_Subnormal;
    extern uint32_t Negative_Zero     ;
    extern uint32_t Positive_Zero     ;
    extern uint32_t Positive_Subnormal;
    extern uint32_t Positive_Normal   ;
    extern uint32_t Positive_Infinity ;
    extern uint32_t Signaling_NaN     ;
    extern uint32_t Quiet_NaN         ;
    uint32_t* inputs[] = {
        &Negative_Infinity, &Negative_Normal, &Negative_Subnormal,
        &Negative_Zero, &Positive_Zero, &Positive_Subnormal,
        &Positive_Normal, &Positive_Infinity, &Signaling_NaN, &Quiet_NaN
    };
    int result;
    float fresult;
    int index;
    index = 0;

    extern int pos_int_input;
    extern int neg_int_input;

    // result address
    extern float _test_start;

    // testing
    // FADDS
    *(&_test_start + index) = frs_pos_0 + frs_pos_1;
    index++;
    *(&_test_start + index) = frs_pos_0 + frs_neg_0;
    index++;
    *(&_test_start + index) = frs_neg_0 + frs_neg_1;
    index++;
    // FSUBS
    *(&_test_start + index) = frs_pos_0 - frs_pos_1;
    index++;
    *(&_test_start + index) = frs_pos_0 - frs_neg_0;
    index++;
    *(&_test_start + index) = frs_neg_0 - frs_neg_1;
    index++;
    // FMULS
    *(&_test_start + index) = frs_pos_0 * frs_pos_1;
    index++;
    *(&_test_start + index) = frs_pos_0 * frs_neg_0;
    index++;
    *(&_test_start + index) = frs_neg_0 * frs_neg_1;
    index++;
    
    // FMADD
    asm volatile ("fmadd.s %0, %1, %2, %3" : "=f"(fresult) : "f"(frs_pos_0), "f"(frs_pos_1), "f"(frs_pos_2));
    *(&_test_start + index) = fresult;
    index++;
    asm volatile ("fmadd.s %0, %1, %2, %3" : "=f"(fresult) : "f"(frs_pos_0), "f"(frs_neg_0), "f"(frs_pos_1));
    *(&_test_start + index) = fresult;
    index++;

    // FMSUB
    asm volatile ("fmsub.s %0, %1, %2, %3" : "=f"(fresult) : "f"(frs_pos_0), "f"(frs_pos_1), "f"(frs_pos_2));
    *(&_test_start + index) = fresult;
    index++;
    asm volatile ("fmsub.s %0, %1, %2, %3" : "=f"(fresult) : "f"(frs_pos_0), "f"(frs_neg_0), "f"(frs_pos_1));
    *(&_test_start + index) = fresult;
    index++;

    // FNMADD
    asm volatile ("fnmadd.s %0, %1, %2, %3" : "=f"(fresult) : "f"(frs_pos_0), "f"(frs_pos_1), "f"(frs_pos_2));
    *(&_test_start + index) = fresult;
    index++;
    asm volatile ("fnmadd.s %0, %1, %2, %3" : "=f"(fresult) : "f"(frs_pos_0), "f"(frs_neg_0), "f"(frs_pos_1));
    *(&_test_start + index) = fresult;
    index++;

    // FNMSUB
    asm volatile ("fnmsub.s %0, %1, %2, %3" : "=f"(fresult) : "f"(frs_pos_0), "f"(frs_pos_1), "f"(frs_pos_2));
    *(&_test_start + index) = fresult;
    index++;
    asm volatile ("fnmsub.s %0, %1, %2, %3" : "=f"(fresult) : "f"(frs_pos_0), "f"(frs_neg_0), "f"(frs_pos_1));
    *(&_test_start + index) = fresult;
    index++;

    // FCVTWS
    asm volatile ("fcvt.w.s %0, %1, rtz" : "=r"(*(&_test_start + index)) : "f"(frs_pos_0));
    index++;
    asm volatile ("fcvt.w.s %0, %1, rtz" : "=r"(*(&_test_start + index)) : "f"(frs_neg_0));
    index++;

    // FCVTWUS
    asm volatile ("fcvt.wu.s %0, %1, rtz" : "=r"(*(&_test_start + index)) : "f"(frs_pos_0));
    index++;
    asm volatile ("fcvt.wu.s %0, %1, rtz" : "=r"(*(&_test_start + index)) : "f"(frs_neg_0));
    index++;

    // FCVTSW
    asm volatile ("fcvt.s.w %0, %1" : "=f"(fresult) : "r"(pos_int_input));
    *(&_test_start + index) = fresult;
    index++;
    asm volatile ("fcvt.s.w %0, %1" : "=f"(fresult) : "r"(neg_int_input));
    *(&_test_start + index) = fresult;
    index++;

    // FCVTSWU
    asm volatile ("fcvt.s.wu %0, %1" : "=f"(fresult) : "r"(pos_int_input));
    *(&_test_start + index) = fresult;
    index++;
    asm volatile ("fcvt.s.wu %0, %1" : "=f"(fresult) : "r"(neg_int_input));
    *(&_test_start + index) = fresult;
    index++;

    // FCLASS
    for (int i = 0; i < 10; ++i) {
        asm volatile (
            "flw fa0, 0(%1)\n\t"
            "fclass.s %0, fa0\n\t" 
            : "=r"(*(&_test_start + index)) 
            : "r"(inputs[i]) : "fa0"               
        );
        index++;
    }

    // FEQS
    asm volatile ("feq.s %0, %1, %2" : "=r"(*(&_test_start + index)) : "f"(frs_pos_0), "f"(frs_pos_0));
    index++;
    asm volatile ("feq.s %0, %1, %2" : "=r"(*(&_test_start + index)) : "f"(frs_pos_0), "f"(frs_pos_1));
    index++;
    asm volatile ("feq.s %0, %1, %2" : "=r"(*(&_test_start + index)) : "f"(frs_pos_0), "f"(frs_neg_1));
    index++;
    asm volatile ("feq.s %0, %1, %2" : "=r"(*(&_test_start + index)) : "f"(frs_neg_0), "f"(frs_neg_1));
    index++;

    // FLTS
    asm volatile ("flt.s %0, %1, %2" : "=r"(*(&_test_start + index)) : "f"(frs_pos_0), "f"(frs_pos_0));
    index++;
    asm volatile ("flt.s %0, %1, %2" : "=r"(*(&_test_start + index)) : "f"(frs_pos_0), "f"(frs_pos_1));
    index++;
    asm volatile ("flt.s %0, %1, %2" : "=r"(*(&_test_start + index)) : "f"(frs_pos_0), "f"(frs_neg_1));
    index++;
    asm volatile ("flt.s %0, %1, %2" : "=r"(*(&_test_start + index)) : "f"(frs_neg_0), "f"(frs_neg_1));
    index++;

    // FLES
    asm volatile ("fle.s %0, %1, %2" : "=r"(*(&_test_start + index)) : "f"(frs_pos_0), "f"(frs_pos_0));
    index++;
    asm volatile ("fle.s %0, %1, %2" : "=r"(*(&_test_start + index)) : "f"(frs_pos_0), "f"(frs_pos_1));
    index++;
    asm volatile ("fle.s %0, %1, %2" : "=r"(*(&_test_start + index)) : "f"(frs_pos_0), "f"(frs_neg_1));
    index++;
    asm volatile ("fle.s %0, %1, %2" : "=r"(*(&_test_start + index)) : "f"(frs_neg_0), "f"(frs_neg_1));
    index++;

    // FMAXS
    *(&_test_start + index) = (frs_pos_0 > frs_pos_1) ? frs_pos_0 : frs_pos_1;
    index++;

    // FMINS
    *(&_test_start + index) = (frs_pos_0 < frs_pos_1) ? frs_pos_0 : frs_pos_1;
    index++;

    // FSGNJS
    asm volatile ("fsgnj.s %0, %1, %2" : "=f"(fresult) : "f"(frs_pos_0), "f"(frs_pos_1));
    *(&_test_start + index) = fresult;
    index++;
    asm volatile ("fsgnj.s %0, %1, %2" : "=f"(fresult) : "f"(frs_pos_0), "f"(frs_neg_0));
    *(&_test_start + index) = fresult;
    index++;

    // FSGNJNS
    asm volatile ("fsgnjn.s %0, %1, %2" : "=f"(fresult) : "f"(frs_pos_0), "f"(frs_pos_1));
    *(&_test_start + index) = fresult;
    index++;
    asm volatile ("fsgnjn.s %0, %1, %2" : "=f"(fresult) : "f"(frs_pos_0), "f"(frs_neg_0));
    *(&_test_start + index) = fresult;
    index++;

    // FSGNJXS
    asm volatile ("fsgnjx.s %0, %1, %2" : "=f"(fresult) : "f"(frs_pos_0), "f"(frs_pos_1));
    *(&_test_start + index) = fresult;
    index++;
    asm volatile ("fsgnjx.s %0, %1, %2" : "=f"(fresult) : "f"(frs_pos_0), "f"(frs_neg_0));
    *(&_test_start + index) = fresult;
    index++;
    asm volatile ("fsgnjx.s %0, %1, %2" : "=f"(fresult) : "f"(frs_neg_0), "f"(frs_neg_1));
    *(&_test_start + index) = fresult;
    index++;

    // FMVXW
    asm volatile ("fmv.x.w %0, %1" : "=r"(*(&_test_start + index)) : "f"(frs_pos_0));
    index++;

    // FMVWX
    asm volatile ("fmv.w.x %0, %1" : "=f"(fresult) : "r"(pos_int_input));
    *(&_test_start + index) = fresult;
    index++;
    asm volatile ("fmv.w.x %0, %1" : "=f"(fresult) : "r"(neg_int_input));
    *(&_test_start + index) = fresult;
    index++;

	return 0;
}

