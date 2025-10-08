#include <stdint.h>
unsigned int *copy_addr; // = &_test_start;
volatile unsigned int *WDT_addr = (int *)0x10010000;

#define CLAMP(value, min, max) ((value) < (min) ? (min) : ((value) > (max) ? (max) : (value)))
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

// External variables
extern uint8_t _binary_image_bmp_start[];
extern uint8_t _test_start[];

extern int32_t _W0;
extern int32_t _H0;
extern int32_t _srcWidth;
extern int32_t _srcHeight;
extern int32_t _dstWidth;
extern int32_t _dstHeight;

int cubicInterpolateInt(int p[4], int x)
{
    int a = (-p[0] + 3 * p[1] - 3 * p[2] + p[3]) >>1;
    int b = (2 * p[0] - 5 * p[1] + 4 * p[2] - p[3])>>1;
    int c = (-p[0] + p[2]) >>1;
    int d = p[1];

    int x2 = (x * x);
    int x3 = (x2 * x) / 256;

    int result = (a * x3 + b * x2 + c * x * 256 + d * 65532) >> 16; // Adjusted scaling
    return CLAMP(result, 0, 255);
}

// Perform 2D bicubic interpolation using integers
int bicubicInterpolateInt(int grid[4][4], int x, int y)
{
    int arr[4];
    int re_grid[4][4];
    for(int i=0;i<4;i++){
      for(int j=0;j<4;j++){
        re_grid[i][j] = grid[j][i];
      }
    }

    // 設定向量長度
    asm volatile("vsetvli zero, %0, e32, m2, ta, ma" ::"r"(4));

    asm volatile("vle32.v v0, (%0)" ::"r"(&re_grid[0][0]));
    asm volatile("vle32.v v2, (%0)" ::"r"(&re_grid[1][0]));
    asm volatile("vle32.v v4, (%0)" ::"r"(&re_grid[2][0]));
    asm volatile("vle32.v v6, (%0)" ::"r"(&re_grid[3][0]));

    // // 使用 vlse.v 載入 grid[][0] 到向量寄存器 v0
    // asm volatile(
    //     "vlse32.v v0, (%0), %1" ::"r"(&grid[0][0]), "r"(4) // grid 的基址和 stride
    // );

    // // 使用 vlse.v 載入 grid[][1] 到向量寄存器 v2
    // asm volatile(
    //     "vlse32.v v2, (%0), %1" ::"r"(&grid[0][1]), "r"(4) // grid 的基址和 stride
    // );

    // // 使用 vlse.v 載入 grid[][2] 到向量寄存器 v4
    // asm volatile(
    //     "vlse32.v v4, (%0), %1" ::"r"(&grid[0][2]), "r"(4) // grid 的基址和 stride
    // );

    // // 使用 vlse.v 載入 grid[][3] 到向量寄存器 v6
    // asm volatile(
    //     "vlse32.v v6, (%0), %1" ::"r"(&grid[0][3]), "r"(4) // grid 的基址和 stride
    // );

    // a = v8 ; b = v10 ; c = v12 ; d = v2
    asm volatile("vmv.v.i v8,  0");
    asm volatile("vmv.v.i v10,  0");
    asm volatile("vmv.v.i v12,  0");
    asm volatile("vmv.v.i v16,  0");
    
    // a = (-p[0] + 3 * p[1] - 3 * p[2] + p[3]) /2;
    asm volatile("vmul.vx v8, v2, %0" ::"r"(3));    // v8 = 3 * p[1]
    asm volatile("vmul.vx v10, v0, %0" ::"r"(2));   // v10 = 2 * p[0]
    asm volatile("vsub.vv v8, v8, v0");             // v8 = -p[0] + 3 * p[1]
    asm volatile("vmacc.vx v10, %0, v2" ::"r"(-5)); // v10 = 2 * p[0] - 5 * p[1]
    asm volatile("vmacc.vx v8, %0, v4" ::"r"(-3));  // v8 = -p[0] + 3 * p[1] - 3 * p[2]
    asm volatile("vmacc.vx v10, %0, v4" ::"r"(4));  // v10 = 2 * p[0] - 5 * p[1] + 4 * p[2]
    asm volatile("vadd.vv v8, v8, v6");             // v8 = -p[0] + 3 * p[1] - 3 * p[2] + p[3]
    asm volatile("vsra.vi v8, v8, 1");             // v8 = (-p[0] + 3 * p[1] - 3 * p[2] + p[3]) / 2

    // b = (2 * p[0] - 5 * p[1] + 4 * p[2] - p[3]) /2;

    asm volatile("vsub.vv v10, v10, v6"); // v10 = 2 * p[0] - 5 * p[1] + 4 * p[2] - p[3]
    asm volatile("vsra.vi v10, v10, 1");            // v10 = (2 * p[0] - 5 * p[1] + 4 * p[2] - p[3]) / 2

    // c = (-p[0] + p[2]) /2;
    asm volatile("vsub.vv v12, v4, v0"); // v12 = (-p[0] + p[2])
    asm volatile("vsra.vi v12, v12, 1"); // v12 = (-p[0] + p[2]) / 2

    asm volatile("vmul.vx v16, v2, %0" ::"r"(65532)); // v8 = a * x3 + b * x2 + c * x * 256 + d * 65536
    int x_256 = x * 256;
    asm volatile("vmacc.vx v16, %0, v12" ::"r"(x_256)); // v8 = a * x3 + b * x2 + c * x * 256
    int x2 = (x * x);
    asm volatile("vmacc.vx v16, %0, v10" ::"r"(x2)); // v8 = a * x3 + b * x2
    int x3 = (x2 * x) / 256;
    asm volatile("vmacc.vx v16, %0, v8" ::"r"(x3)); // v8 = a * x3

    //asm volatile("vsra.vi v16, v16, 17");                // v8 = (a * x3 + b * x2 + c * x * 256 + d * 65536) / 65536

    asm volatile("vse32.v v16, (%0);" ::"r"(&arr[0]));

    for (int i = 0; i < 4; i++)
    {
        int tmp = arr[i] >> 16;
        arr[i] = CLAMP(tmp, 0, 255);
    }

    int result = cubicInterpolateInt(arr, y);
    return result;
}

void bicubicResizeInt(uint8_t *src, int srcWidth, int srcHeight,
                      uint8_t *dst, int dstWidth, int dstHeight,
                      int W0, int H0, int channelOffset, uint32_t Image_width, uint32_t Image_height)
{
    int xRatio = ((srcWidth - 1) << 8) / (dstWidth - 1);
    int yRatio = ((srcHeight - 1) << 8) / (dstHeight - 1);

    for (int dy = 0; dy < dstHeight; dy++)
    {
        for (int dx = 0; dx < dstWidth; dx++)
        {
            int gx = dx * xRatio;
            int gy = dy * yRatio;
            int x = gx >> 8;
            int y = gy >> 8;

            int grid[4][4];

            for (int j = -1; j <= 2; j++)
            {
                for (int i = -1; i <= 2; i++)
                {

                    int px = CLAMP(x + i + W0, 0, Image_width - 1);
                    int py = CLAMP(y + j + H0, 0, Image_height - 1);
                    int pixelIndex = (py * Image_width + px) * 3; // 乘以 3 因為 RGB 各佔 1 byte

                    // 根據需要處理 R/G/B 通道，這裡以 R 通道為例
                    grid[j + 1][i + 1] = src[pixelIndex + channelOffset]; // channelOffset = 0(R), 1(G), 2(B)
                }
            }

            int fractionalX = gx & 255;
            int fractionalY = gy & 255;

            int value = bicubicInterpolateInt(grid, fractionalX, fractionalY);

            dst[(dy * dstWidth + dx) * 3 + channelOffset] = (uint8_t)CLAMP(value, 0, 255);
        }
    }
}

void bicubicResizeRGB(uint8_t *src, int srcWidth, int srcHeight,
                      uint8_t *dst, int dstWidth, int dstHeight,
                      int W0, int H0, uint32_t Image_width, uint32_t Image_height)
{
    uint8_t *S0 = src + (H0 * Image_width + W0) * 3;

    bicubicResizeInt(S0, srcWidth, srcHeight, dst, dstWidth, dstHeight, W0, H0, 0, Image_width, Image_height); // R
    bicubicResizeInt(S0, srcWidth, srcHeight, dst, dstWidth, dstHeight, W0, H0, 1, Image_width, Image_height); // G
    bicubicResizeInt(S0, srcWidth, srcHeight, dst, dstWidth, dstHeight, W0, H0, 2, Image_width, Image_height); // B
}

int main()
{
    uint8_t *srcImage = &_binary_image_bmp_start[54]; // Skip BMP header
    uint8_t *dstImage = _test_start;
    uint32_t Image_width = _binary_image_bmp_start[18] |
                           (_binary_image_bmp_start[19] << 8) |
                           (_binary_image_bmp_start[20] << 16) |
                           (_binary_image_bmp_start[21] << 24);
    uint32_t Image_height = _binary_image_bmp_start[22] |
                            (_binary_image_bmp_start[23] << 8) |
                            (_binary_image_bmp_start[24] << 16) |
                            (_binary_image_bmp_start[25] << 24);

    bicubicResizeRGB(srcImage, _srcWidth, _srcHeight,
                     dstImage, _dstWidth, _dstHeight,
                     _W0, _H0, Image_width, Image_height);

    return 0;
}


