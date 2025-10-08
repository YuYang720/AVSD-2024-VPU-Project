#!/usr/bin/env python3
import os

def read_unit_test(file_path):
    """
    Reads the content of a single test file.
    """
    try:
        with open(file_path, "r") as f:
            return f.read()
    except FileNotFoundError:
        print(f"Error: Unit test file '{file_path}' not found.")
        return ""

def extract_golden_data(test_code):
    """
    Extracts golden data from the test code and returns the modified test code and golden data.
    """
    golden_data = []
    lines = test_code.splitlines()
    new_test_code = []

    for line in lines:
        if line.strip().startswith("golden:"):
            index = lines.index(line)
            golden_data = [l.strip() for l in lines[index + 1:]]  # Everything after 'golden:', with leading spaces removed
            break
        else:
            new_test_code.append(line)

    return "\n".join(new_test_code), "\n".join(golden_data)

def generate_main_s(test_files, golden_file="golden.hex", output_file="main.S"):
    """
    Reads test code from specified test files, extracts golden data,
    and generates main.S and golden.data files.
    """
    lines = []
    golden_lines = []

    # Header section
    lines.append(".section .text")
    lines.append(".align  2")
    lines.append(".globl  main\n")

    # Main function
    lines.append("main:")
    lines.append("    addi    sp, sp, -4")
    lines.append("    sw      s0, 0(sp)")
    lines.append("    la      s0, _test_start")

    # Insert test code dynamically
    for file_path in test_files:
        test_code = read_unit_test(file_path)
        if test_code:
            test_code, golden_data = extract_golden_data(test_code)
            if golden_data:
                golden_lines.append(golden_data)

            lines.append(f"    # Include test from {file_path}")
            lines.append(test_code)
        else:
            print(f"Warning: Skipping test file '{file_path}' due to errors.")

    # Footer section
    lines.append("\n")
    lines.append("main_exit:")
    lines.append("    lw      s0, 0(sp)")
    lines.append("    addi    sp, sp, 4")
    lines.append("    ret")

    # Write to output file
    with open(output_file, "w") as f:
        f.write("\n".join(lines))

    # Write golden data to separate file
    if golden_lines:
        with open(golden_file, "w") as f:
            f.write("\n".join(golden_lines))
        print(f"Golden data has been extracted to {golden_file}")

# Example usage
if __name__ == "__main__":
    test_files = [
        "../unit_test/alu/vadd8.S" ,
        "../unit_test/alu/vadd16.S",
        "../unit_test/alu/vadd32.S",
        "../unit_test/alu/vadd64.S",
        "../unit_test/alu/vsub8.S",
        "../unit_test/alu/vsub16.S",
        "../unit_test/alu/vsub32.S",
        "../unit_test/alu/vsub64.S",
        "../unit_test/alu/vrsub8.S",
        "../unit_test/alu/vrsub16.S",
        "../unit_test/alu/vrsub32.S",
        "../unit_test/alu/vrsub64.S",
        "../unit_test/alu/vand8.S",
        "../unit_test/alu/vand16.S",
        "../unit_test/alu/vand32.S",
        "../unit_test/alu/vand64.S",
        "../unit_test/alu/vor8.S",
        "../unit_test/alu/vor16.S",
        "../unit_test/alu/vor32.S",
        "../unit_test/alu/vor64.S",
        "../unit_test/alu/vxor8.S",
        "../unit_test/alu/vxor16.S",
        "../unit_test/alu/vxor32.S",
        "../unit_test/alu/vxor64.S",
        "../unit_test/alu/vmin8.S",
        "../unit_test/alu/vmin16.S",
        "../unit_test/alu/vmin32.S",
        "../unit_test/alu/vmin64.S",
        "../unit_test/alu/vmax8.S",
        "../unit_test/alu/vmax16.S",
        "../unit_test/alu/vmax32.S",
        "../unit_test/alu/vmax64.S",
        "../unit_test/elem/vredsum.S"
        "../unit_test/mul/mul8.S",
        "../unit_test/mul/mul16.S",
        "../unit_test/mul/mul32.S",
        "../unit_test/mul/mul64.S",
        "../unit_test/mul/mulh8.S",
        "../unit_test/mul/mulh16.S",
        "../unit_test/mul/mulh32.S",
        "../unit_test/mul/mulh64.S",
        "../unit_test/sld/vslidedown.S",
        "../unit_test/sld/vslideup.S",
        "../unit_test/alu/vsll.S",
        "../unit_test/alu/vsra.S",
        "../unit_test/alu/vsrl.S",
        "../unit_test/lsu/vse8.S",
        "../unit_test/lsu/vse16.S",
        "../unit_test/lsu/vse32.S",
        "../unit_test/lsu/vse64.S",
        "../unit_test/lsu/vsse8.S",
        "../unit_test/lsu/vsse16.S",
        "../unit_test/lsu/vsse32.S",
        "../unit_test/lsu/vsse64.S",
        "../unit_test/lsu/vle.S",
        "../unit_test/lsu/vlse.S",
    ]

    generate_main_s(test_files)