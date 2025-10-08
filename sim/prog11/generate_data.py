#!/usr/bin/env python3
import sys
import random

def generate_arrays(n, seed=None):
    """
    Generate one array with n random signed integers (range: -128 to 127).
    If a seed is provided, use it for reproducibility.
    """
    if seed is not None:
        random.seed(seed)
    array = [random.randint(-128, 127) for _ in range(n)]
    return array

def calc_golden_relu(array):
    """
    Apply ReLU to each element in the array.
    ReLU(x) = max(0, x).
    Return a list of 4-element chunks in reversed order as hexadecimal strings.
    """
    relu_result = [max(0, x) for x in array]
    lines = []
    # Every 4 elements form a group
    for i in range(0, len(relu_result), 4):
        chunk = relu_result[i:i+4]
        # Reverse the order of the chunk and format as hex
        chunk_str = "".join(f"{val:02x}" for val in reversed(chunk))
        lines.append(chunk_str)
    return lines

def to_asm_bytes(arr):
    """
    Convert a Python list (e.g., [0x01, 0x02, ...]) into .byte format for assembly.
    Each line has a maximum of 8 values, without a trailing comma or backslash.
    """
    lines = []
    line_elems = []
    for i, val in enumerate(arr, start=1):
        line_elems.append(f"0x{val & 0xFF:02x}")
        # Every 8 elements form a line
        if i % 8 == 0:
            lines.append("  .byte " + ", ".join(line_elems))
            line_elems = []
    # Handle remaining elements
    if line_elems:
        lines.append("  .byte " + ", ".join(line_elems))
    return "\n".join(lines)

def generate_data_s(array):
    """
    Generate the content for the data.S file, including:
    - Input array
    - Size and address metadata
    """
    n = len(array)
    lines = []
    lines.append(".section .rodata")
    lines.append(".align 2")
    lines.append(".global input_array_size")
    lines.append(".global input_array_addr\n")

    # input_array_size
    lines.append("input_array_size:")
    lines.append(f"  .word 0x{n:08x}")

    # input_array_addr
    lines.append("input_array_addr:")
    lines.append(to_asm_bytes(array))
    lines.append("")  # Empty line for readability

    return "\n".join(lines)

def write_to_file(filename, content):
    """
    Write the given content to a file.
    """
    with open(filename, "w") as f:
        f.write(content)

def main():
    if len(sys.argv) < 2:
        print("Usage: python gen_relu.py <num_of_data> [seed]")
        sys.exit(1)

    n = int(sys.argv[1])
    seed = int(sys.argv[2]) if len(sys.argv) > 2 else None

    # Generate the input array
    input_array = generate_arrays(n, seed)

    # Generate data.S content
    data_s_content = generate_data_s(input_array)
    write_to_file("data.S", data_s_content)

    # Compute golden ReLU results
    golden_lines = calc_golden_relu(input_array)
    write_to_file("golden.hex", "\n".join(golden_lines))

    print(f"Files generated successfully:")
    print(f"  - Assembly file: data.S")
    print(f"  - Golden file: golden.hex")

if __name__ == "__main__":
    main()
