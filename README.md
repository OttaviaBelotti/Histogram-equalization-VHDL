# Histogram Equalization in VHDL

University project for Reti Logiche course at Politecnico di Milano, A.Y. 2020-2021.

The full specification can be found [here](https://github.com/OttaviaBelotti/histogram-equalization-VHDL/blob/main/project-specifications-italian.pdf) (italian only) and a brief introduction can be found in the [Specifications](##specifications) section below.

Devs: [Javin Barone](https://github.com/Javinyx), [Ottavia Belotti](https://github.com/OttaviaBelotti)

## Aim of the project
The project's aim is to experience a low-level programming style simulating the programming of a FPGA. The challenge is to write very efficient code taking advantage (but at the same time dealing with the limitations) of the hardware architecture, rather than using high-level operations non-natively supported by the hardware. In fact, the project has to work with a clock period of at least 100 ns.

## Specifications
The project consists in a VHDL (_VHSIC Hardware Description Language_) implementation of a simplified image equalization algorithm. It supports 8-bit grayscale images and the maximum size for an image is 128x128 _px_. 

An image is fed to the algorithm by storing sequentially each pixel value in the program memory starting from address 2, while cells 0 and 1 are reserved for the image size which has to be specified. Each pixel value (`current_pixel_value`) is analyzed and its new value is computed as follow:
```pseudo
delta_value = max_pixel_value - min_pixel_value
shift_level = (8 - floor(log2(delta_value + 1))
temp_pixel = (current_pixel_value - min_pixel_value) << shift_level
new_pixel_value = min(255, temp_pixel)
```

The programm processes all the values and writes the equalized version of the image right after the original image in memory, in a sequential order as well.

## Software
* XILINX Vivado WebPack (with target FPGA: xc7a200tfbg484-1)
