#!/usr/bin/env python3
import sys
import random

def generate_arrays(n, seed=None):
    """
    產生兩組 n 筆亂數資料 (範圍: 0x00 ~ 0xFF)。
    如果想要固定重現，設定 seed。
    """
    if seed is not None:
        random.seed(seed)
    array1 = [random.randint(0, 255) for _ in range(n)]
    array2 = [random.randint(0, 255) for _ in range(n)]
    return array1, array2

def calc_golden(a1, a2):
    """
    對應元素相乘 (只取 1 byte)，回傳每 4 筆翻轉組合的字串清單。
    """
    products = [(x * y) & 0xFF for x, y in zip(a1, a2)]
    lines = []
    # 每 4 筆一組
    for i in range(0, len(products), 4):
        chunk = products[i:i+4]
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

def generate_data_s(array1, array2):
    """
    產生 data.S 的完整字串內容，包括：
      .section, .align, .global ...
      array1_size, array1_addr
      array2_size, array2_addr
    """
    n = len(array1)
    lines = []
    lines.append(".section .rodata")
    lines.append(".align 2")
    lines.append(".global array1_size")
    lines.append(".global array1_addr")
    lines.append(".global array2_size")
    lines.append(".global array2_addr\n")

    # array1_size
    lines.append("array1_size:")
    lines.append(f"  .word 0x{n:08x}")

    # array1_addr
    lines.append("array1_addr:")
    lines.append(to_asm_bytes(array1))
    lines.append("")  # 空行

    # array2_size
    lines.append("array2_size:")
    lines.append(f"  .word 0x{n:08x}")

    # array2_addr
    lines.append("array2_addr:")
    lines.append(to_asm_bytes(array2))
    lines.append("")  # 空行

    return "\n".join(lines)

def write_to_file(filename, content):
    """
    將內容寫入檔案。
    """
    with open(filename, "w") as f:
        f.write(content)

def main():
    if len(sys.argv) < 2:
        print("Usage: python gen_data.py <num_of_data> [seed]")
        sys.exit(1)

    n = int(sys.argv[1])
    seed = int(sys.argv[2]) if len(sys.argv) > 2 else None

    # 產生兩組 array
    array1, array2 = generate_arrays(n, seed)

    # 產生 data.S
    data_s_content = generate_data_s(array1, array2)
    write_to_file("data.S", data_s_content)

    # 計算 golden
    golden_lines = calc_golden(array1, array2)
    write_to_file("golden.hex", "\n".join(golden_lines))

    print(f"Files generated successfully:")
    print(f"  - Assembly file: data.S")
    print(f"  - Golden file: golden.hex")

if __name__ == "__main__":
    main()
