#include <stdint.h>
#define MIN(a, b) ((a) < (b) ? (a) : (b))
#define MIP_MEIP (1 << 11) // External interrupt pending
#define MIP_MTIP (1 << 7)  // Timer interrupt pending
#define MIP 0x344

unsigned int *copy_addr; // = &_test_start;
volatile unsigned int *WDT_addr = (int *) 0x10010000;

void timer_interrupt_handler(void) {
  asm("csrsi mstatus, 0x0"); // MIE of mstatus
  WDT_addr[0x40] = 0; // WDT_en
  asm("j _start");
}

void external_interrupt_handler(void) {
	volatile unsigned int *dma_addr_boot = (int *) 0x10020000;
	asm("csrsi mstatus, 0x0"); // MIE of mstatus
	dma_addr_boot[0x40] = 0; // disable DMA
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


void imatmul_4x4(int32_t *c, const int32_t *a, const int32_t *b,
                 const unsigned long int m, const unsigned long int n,
                 const unsigned long int p);
void imatmul_vec_4x4_slice_init();
void imatmul_vec_4x4(int32_t *c, const int32_t *a, const int32_t *b,
                     const unsigned long int n, const unsigned long int p);


void imatmul_4x4(int32_t *c, const int32_t *a, const int32_t *b,
                 const unsigned long int M, const unsigned long int N,
                 const unsigned long int P) {
  // We work on 4 rows of the matrix at once
  const unsigned long int block_size = 4;
  unsigned long int block_size_p;

  // Set the vector configuration
  asm volatile("vsetvli %0, %1, e32, m2, ta, ma" : "=r"(block_size_p) : "r"(P));

  // Slice the matrix into a manageable number of columns p_
  for (unsigned long int p = 0; p < P; p += block_size_p) {
    // Set the vector length
    const unsigned long int p_ = MIN(P - p, block_size_p);

    // Find pointers to the submatrices
    const int32_t *b_ = b + p;
    int32_t *c_ = c + p;

    asm volatile("vsetvli zero, %0, e32, m2, ta, ma" ::"r"(p_));

    // Iterate over the rows
    for (unsigned long int m = 0; m < M; m += block_size) {
      // Find pointer to the submatrices
      const int32_t *a_ = a + m * N;
      int32_t *c__ = c_ + m * P;

      imatmul_vec_4x4_slice_init();
      imatmul_vec_4x4(c__, a_, b_, N, P);
    }
  }
}

void imatmul_vec_4x4_slice_init() {
  asm volatile("vmv.v.i v0,  0");
  asm volatile("vmv.v.i v2,  0");
  asm volatile("vmv.v.i v4,  0");
  asm volatile("vmv.v.i v6, 0");
}

void imatmul_vec_4x4(int32_t *c, const int32_t *a, const int32_t *b,
                     const unsigned long int N, const unsigned long int P) {
  // Temporary variables
  int32_t t0, t1, t2, t3;

  // Original pointer
  const int32_t *a_ = a;

  // Prefetch one row of matrix B
  asm volatile("vle32.v v16, (%0);" ::"r"(b));
  b += P;

  // Prefetch one row of scalar values
  t0 = *a, a += N;
  t1 = *a, a += N;
  t2 = *a, a += N;
  t3 = *a;

  // Compute the multiplication
  unsigned long int n = 0;

  while (n < N) {

    // Calculate pointer to the matrix A
    a = a_ + ++n;

    asm volatile("vmacc.vx v0, %0, v16" ::"r"(t0));
    t0 = *a, a += N;

    // Load one row of B
    asm volatile("vle32.v v18, (%0);" ::"r"(b));
    b += P;

    asm volatile("vmacc.vx v2, %0, v16" ::"r"(t1));
    t1 = *a, a += N;
    asm volatile("vmacc.vx v4, %0, v16" ::"r"(t2));
    t2 = *a, a += N;
    asm volatile("vmacc.vx v6, %0, v16" ::"r"(t3));
    t3 = *a;

    a = a_ + ++n;

    if (n == N)
      break;

    asm volatile("vmacc.vx v0, %0, v18" ::"r"(t0));
    t0 = *a, a += N;

    // Load one row of B
    asm volatile("vle32.v v16, (%0);" ::"r"(b));
    b += P;

    asm volatile("vmacc.vx v2, %0, v18" ::"r"(t1));
    t1 = *a, a += N;
    asm volatile("vmacc.vx v4, %0, v18" ::"r"(t2));
    t2 = *a, a += N;
    asm volatile("vmacc.vx v6, %0, v18" ::"r"(t3));
    t3 = *a;
  }

  // Last iteration: store results
  asm volatile("vmacc.vx v0, %0, v18" ::"r"(t0));
  asm volatile("vse32.v v0, (%0);" ::"r"(c));
  c += P;
  asm volatile("vmacc.vx v2, %0, v18" ::"r"(t1));
  asm volatile("vse32.v v2, (%0);" ::"r"(c));
  c += P;
  asm volatile("vmacc.vx v4, %0, v18" ::"r"(t2));
  asm volatile("vse32.v v4, (%0);" ::"r"(c));
  c += P;
  asm volatile("vmacc.vx v6, %0, v18" ::"r"(t3));
  asm volatile("vse32.v v6, (%0);" ::"r"(c));
}


// Define Matrix dimensions:
// C = AB with A=[MxN], B=[NxP], C=[MxP]
extern uint32_t M;
extern uint32_t N;
extern uint32_t P;

extern int32_t a[] ;
extern int32_t b[] ;
extern int32_t _test_start[] ;


int main() {
    imatmul_4x4(_test_start, a, b, M, N, P);
    return 0;
}
