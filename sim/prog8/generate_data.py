#!/usr/bin/env python3
import sys
import random

def generate_arrays(n, seed=None):
    """
    產生向量 x 和 y，各有 n 筆亂數資料 (範圍: 0x00 ~ 0xFF)。
    如果需要固定隨機數，提供 seed。
    """
    if seed is not None:
        random.seed(seed)
    x = [random.randint(0, 255) for _ in range(n)]
    y = [random.randint(0, 255) for _ in range(n)]
    alpha = random.randint(0, 255)  # 產生 alpha 值
    return x, y, alpha

def calc_golden(x, y, alpha):
    """
    計算 AXPY (y = alpha * x + y) 的結果，取低 8 位。
    """
    golden = [((alpha * xi) + yi) & 0xFF for xi, yi in zip(x, y)]
    lines = []
    # 每 4 筆一組
    for i in range(0, len(golden), 4):
        chunk = golden[i:i+4]
        # 倒序 (reversed) 後，用 2 位 16 進位轉成字串
        chunk_str = "".join(f"{val:02x}" for val in reversed(chunk))
        lines.append(chunk_str)
    return lines

def to_asm_bytes(arr):
    """
    將 Python list (如 [0x01, 0x02, ...]) 轉成組合語言 .byte 格式的多行字串。
    * 每行最多 8 筆，不在行尾多加逗號或反斜線 *
    """
    lines = []
    line_elems = []
    for i, val in enumerate(arr, start=1):
        line_elems.append(f"0x{val:02x}")
        # 每 8 筆就輸出一行
        if i % 8 == 0:
            lines.append("  .byte " + ", ".join(line_elems))
            line_elems = []
    # 如果還有剩餘的資料，最後再輸出一行
    if line_elems:
        lines.append("  .byte " + ", ".join(line_elems))
    return "\n".join(lines)

def generate_data_s(x, y, alpha):
    """
    產生 data.S 的完整字串內容，包括：
      .section, .align, .global ...
      x_size, x_addr, y_addr, alpha
    """
    n = len(x)
    lines = []
    lines.append(".section .rodata")
    lines.append(".align 2")
    lines.append(".global x_size")
    lines.append(".global x_addr")
    lines.append(".global y_addr")
    lines.append(".global alpha\n")

    # x_size
    lines.append("x_size:")
    lines.append(f"  .word 0x{n:08x}")

    # x_addr
    lines.append("x_addr:")
    lines.append(to_asm_bytes(x))
    lines.append("")  # 空行

    # y_addr
    lines.append("y_addr:")
    lines.append(to_asm_bytes(y))
    lines.append("")  # 空行

    # alpha
    lines.append("alpha:")
    lines.append(f"  .byte 0x{alpha:02x}")

    return "\n".join(lines)

def write_to_file(filename, content):
    """
    將內容寫入檔案。
    """
    with open(filename, "w") as f:
        f.write(content)

def main():
    if len(sys.argv) < 2:
        print("Usage: python gen_axpy_data.py <num_of_data> [seed]")
        sys.exit(1)

    n = int(sys.argv[1])
    seed = int(sys.argv[2]) if len(sys.argv) > 2 else None

    # 產生向量 x, y 和 alpha
    x, y, alpha = generate_arrays(n, seed)

    # 產生 data.S 文件
    data_s_content = generate_data_s(x, y, alpha)
    write_to_file("data.S", data_s_content)

    # 計算 golden
    golden_lines = calc_golden(x, y, alpha)
    write_to_file("golden.hex", "\n".join(golden_lines))

    print(f"Files generated successfully:")
    print(f"  - Assembly file: data.S")
    print(f"  - Golden file: golden.hex")

if __name__ == "__main__":
    main()
