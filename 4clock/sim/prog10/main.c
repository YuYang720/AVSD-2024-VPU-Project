#include <stdint.h>
#define MIN(a, b) ((a) < (b) ? (a) : (b))
unsigned int *copy_addr; // = &_test_start;
volatile unsigned int *WDT_addr = (int *)0x10010000;

#define MIP_MEIP (1 << 11) // External interrupt pending
#define MIP_MTIP (1 << 7)  // Timer interrupt pending
#define MIP 0x344

void timer_interrupt_handler(void)
{
  asm("csrsi mstatus, 0x0"); // MIE of mstatus
  WDT_addr[0x40] = 0;        // WDT_en
  asm("j _start");
}

void external_interrupt_handler(void)
{
  volatile unsigned int *dma_addr_boot = (int *)0x10020000;
  asm("csrsi mstatus, 0x0"); // MIE of mstatus
  dma_addr_boot[0x40] = 0;   // disable DMA
}

void trap_handler(void)
{
  uint32_t mip;

  // 讀取中斷狀態寄存器
  asm volatile("csrr %0, %1" : "=r"(mip) : "i"(MIP));

  // 檢查並處理計時器中斷
  if ((mip & MIP_MTIP) >> 7)
  {
    timer_interrupt_handler(); // 調用計時器中斷處理程序
  }

  // 檢查並處理外部中斷
  if ((mip & MIP_MEIP) >> 11)
  {
    external_interrupt_handler(); // 調用外部中斷處理程序
  }
}

extern int8_t input[];       // [ (M+floor(F/2)) * (N+floor(F/2)) ]
extern int8_t filter[];      // [ F*F ]
extern int8_t _test_start[]; // [ M*N ]
// extern int8_t golden_o[]; // [ M*N ]
// M, N, F defined in data.S
extern int8_t M;
extern int8_t N;
extern int8_t F;

void iconv2d_3x3(int8_t *o, int8_t *i, int8_t *f, int8_t R, int8_t C,
                 int8_t F);
void iconv2d_vec_4xC_slice_preload_3x3(int8_t *i, int8_t C, int8_t F);
void iconv2d_vec_4xC_slice_move_3x3(int8_t C, int8_t F);
void iconv2d_vec_4xC_3x3(int8_t *o, int8_t *i, int8_t *f, int8_t C,
                         int8_t F);

void iconv2d_3x3(int8_t *o, int8_t *i, int8_t *f, int8_t R, int8_t C,
                 int8_t F)
{
  // We work on 4 rows of the output matrix at once
  int8_t block_size_o = 4;

  // First iteration round, r = 0
  int8_t *i_ = i;
  int8_t *o_ = o;

  // Preload the first two input rows -> This is not needed in the other rounds
  iconv2d_vec_4xC_slice_preload_3x3(i_, C, F);

  // The first F-1 rows have already been loaded by
  // iconv2d_vec_4xC_slice_preload_3x3()
  int8_t *i__ = i_ + (F - 1) * (C + F + 1);
  iconv2d_vec_4xC_3x3(o_, i__, f, C, F);
  // Re-use some of the already-loaded input rows
  // iconv2d_vec_4xC_slice_move_3x3(C, F);

  // Iterate over the output rows
  for (int8_t r = block_size_o; r < R; r += block_size_o)
  {
    o_ = o + r * C;
    i_ = i + r * (C + F + 1);
    i__ = i_ + (F - 1) * (C + F + 1);
    iconv2d_vec_4xC_slice_move_3x3(C, F);
    iconv2d_vec_4xC_3x3(o_, i__, f, C, F);
  }
}
// Load 4 rows of the output matrix
void iconv2d_vec_4xC_slice_preload_3x3(int8_t *i, int8_t C, int8_t F)
{
  // Helper variables
  int8_t ldi = (C + F + 1);

  // Set the vector configuration
  asm volatile("vsetvli zero, %0, e8, m2, ta, ma" ::"r"(C + F + 1));
  // Fetch the first floor(F/2) + 1 input rows
  asm volatile("vle8.v v8,  (%0); add %0, %0, %1" : "+&r"(i) : "r"(ldi));
  asm volatile("vle8.v v10, (%0); add %0, %0, %1" : "+r"(i));
}

// Calculate 4 output matrix rows
void iconv2d_vec_4xC_3x3(int8_t *o, int8_t *i, int8_t *f, int8_t C,
                         int8_t F)
{

  // Temporary variables
  int8_t t0, t1, t2;

  // Helper variables
  int8_t ldo = C;
  int8_t ldi = (C + F + 1);
  int8_t ldf = F;
  int8_t *f_;

  asm volatile("vsetvli zero, %0, e8, m2, ta, ma" ::"r"(C + F + 1));
  f_ = f;
  // Fetch the first column of the filter, and start calculating its
  // contribution on the four output rows (v0, v2, v4, v6)
  asm volatile("lb %1, (%0); add %0, %0, %2" : "+&r"(f_), "=&r"(t0) : "r"(ldf));
  asm volatile("lb %1, (%0); add %0, %0, %2" : "+&r"(f_), "=&r"(t1) : "r"(ldf));
  asm volatile("lb %1, (%0);" : "+&r"(f_), "=&r"(t2));

  asm volatile("vle8.v v12, (%0); add %0, %0, %1" : "+&r"(i) : "r"(ldi));
  asm volatile("vle8.v v14, (%0); add %0, %0, %1" : "+&r"(i) : "r"(ldi));
  asm volatile("vle8.v v16, (%0); add %0, %0, %1" : "+&r"(i) : "r"(ldi));
  asm volatile("vle8.v v18, (%0); add %0, %0, %1" : "+&r"(i) : "r"(ldi));

  asm volatile("vmul.vx v0, v8, %0" ::"r"(t0));
  asm volatile("vmul.vx v2, v10, %0" ::"r"(t0));
  asm volatile("vmul.vx v4, v12, %0" ::"r"(t0));
  asm volatile("vmul.vx v6, v14, %0" ::"r"(t0));

  asm volatile("vmacc.vx v0, %0, v10" ::"r"(t1));
  asm volatile("vmacc.vx v2, %0, v12" ::"r"(t1));
  asm volatile("vmacc.vx v4, %0, v14" ::"r"(t1));
  asm volatile("vmacc.vx v6, %0, v16" ::"r"(t1));

  asm volatile("vmacc.vx v0, %0, v12" ::"r"(t2));
  asm volatile("vmacc.vx v2, %0, v14" ::"r"(t2));
  asm volatile("vmacc.vx v4, %0, v16" ::"r"(t2));
  asm volatile("vmacc.vx v6, %0, v18" ::"r"(t2));

  asm volatile("vslidedown.vi v20, v8,  1");
  asm volatile("vslidedown.vi v22, v10, 1");
  asm volatile("vslidedown.vi v24, v12, 1");
  asm volatile("vslidedown.vi v26, v14, 1");
  asm volatile("vslidedown.vi v28, v16, 1");
  asm volatile("vslidedown.vi v30, v18, 1");

  f_ = f + 1;
  // Fetch the middle column of the filter, and start calculating its
  // contributions on the output rows To do so, slide down the input rows by one
  asm volatile("lb %1, (%0); add %0, %0, %2" : "+&r"(f_), "=&r"(t0) : "r"(ldf));
  asm volatile("lb %1, (%0); add %0, %0, %2" : "+&r"(f_), "=&r"(t1) : "r"(ldf));
  asm volatile("lb %1, (%0);" : "+&r"(f_), "=&r"(t2));

  asm volatile("vmacc.vx v0, %0, v20" ::"r"(t0));
  asm volatile("vmacc.vx v2, %0, v22" ::"r"(t0));
  asm volatile("vmacc.vx v4, %0, v24" ::"r"(t0));
  asm volatile("vmacc.vx v6, %0, v26" ::"r"(t0));

  asm volatile("vmacc.vx v0, %0, v22" ::"r"(t1));
  asm volatile("vmacc.vx v2, %0, v24" ::"r"(t1));
  asm volatile("vmacc.vx v4, %0, v26" ::"r"(t1));
  asm volatile("vmacc.vx v6, %0, v28" ::"r"(t1));

  asm volatile("vmacc.vx v0, %0, v24" ::"r"(t2));
  asm volatile("vmacc.vx v2, %0, v26" ::"r"(t2));
  asm volatile("vmacc.vx v4, %0, v28" ::"r"(t2));
  asm volatile("vmacc.vx v6, %0, v30" ::"r"(t2));

  asm volatile("vslidedown.vi v20, v8,  2");
  asm volatile("vslidedown.vi v22, v10, 2");
  asm volatile("vslidedown.vi v24, v12, 2");
  asm volatile("vslidedown.vi v26, v14, 2");
  asm volatile("vslidedown.vi v28, v16, 2");
  asm volatile("vslidedown.vi v30, v18, 2");

  f_ = f + 2;
  // Repeat for the last filter column, and then store the output rows
  asm volatile("lb %1, (%0); add %0, %0, %2" : "+&r"(f_), "=&r"(t0) : "r"(ldf));
  asm volatile("lb %1, (%0); add %0, %0, %2" : "+&r"(f_), "=&r"(t1) : "r"(ldf));
  asm volatile("lb %1, (%0);" : "+&r"(f_), "=&r"(t2));

  asm volatile("vmacc.vx v0, %0, v20" ::"r"(t0));
  asm volatile("vmacc.vx v2, %0, v22" ::"r"(t0));
  asm volatile("vmacc.vx v4, %0, v24" ::"r"(t0));
  asm volatile("vmacc.vx v6, %0, v26" ::"r"(t0));

  asm volatile("vmacc.vx v0, %0, v22" ::"r"(t1));
  asm volatile("vmacc.vx v2, %0, v24" ::"r"(t1));
  asm volatile("vmacc.vx v4, %0, v26" ::"r"(t1));
  asm volatile("vmacc.vx v6, %0, v28" ::"r"(t1));

  asm volatile("vmacc.vx v0, %0, v24" ::"r"(t2));
  asm volatile("vmacc.vx v2, %0, v26" ::"r"(t2));
  asm volatile("vmacc.vx v4, %0, v28" ::"r"(t2));
  asm volatile("vmacc.vx v6, %0, v30" ::"r"(t2));

  // Compute on C elements
  asm volatile("vsetvli zero, %0, e8, m2, ta, ma" ::"r"(C));

  asm volatile("vse8.v  v0, (%0); add %0, %0, %1" : "+&r"(o) : "r"(ldo));
  asm volatile("vse8.v  v2, (%0); add %0, %0, %1" : "+&r"(o) : "r"(ldo));
  asm volatile("vse8.v  v4, (%0); add %0, %0, %1" : "+&r"(o) : "r"(ldo));
  asm volatile("vse8.v  v6, (%0);" : "+r"(o));
}

void iconv2d_vec_4xC_slice_move_3x3(int8_t C, int8_t F)
{
  asm volatile("vsetvli zero, %0, e8, m2, ta, ma" ::"r"(C + F + 1));
  // Move the last floor(F/2) + 1 input rows
  asm volatile("vmv.v.v v8, v16");
  asm volatile("vmv.v.v v10, v18");
}

int main()
{

  iconv2d_3x3(_test_start, input, filter, M, N, F);

  return 0;
}
