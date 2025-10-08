void boot() {
    extern unsigned int _dram_i_start;       // instruction start address in DRAM
    extern unsigned int _dram_i_end;         // instruction end   address in DRAM
    extern unsigned int _imem_start;         // instruction start address in IM

    extern unsigned int __sdata_start;       // main data start address in DM
    extern unsigned int __sdata_end;         // main data end   address in DM
    extern unsigned int __sdata_paddr_start; // main data start address in DRAM

    extern unsigned int __data_start;        // main data start address in DM
    extern unsigned int __data_end;          // main data end   address in DM
    extern unsigned int __data_paddr_start;  // main data start address in DRAM

    volatile unsigned int *dma_addr = (int*) 0x10020000;
    
    /*
        Booting step:
            1. write the source     address (dmasrc)
            2. write the desination address (dmadst)
            3. write the data length        (dmalen)
            4. enable dmaen
            5. enter WFI
    */
   
    // Enable Global Interrupt
    asm("csrsi mstatus, 0x8"); // MIE of mstatus

    // Enable Local Interrupt
    asm("li t6, 0x800");
    asm("csrs mie, t6"); // MEIE of mie


    // Booting 1. Move instruction from DRAM to IM
    dma_addr[0x200 >> 2] = (unsigned int)(&_dram_i_start);
    dma_addr[0x300 >> 2] = (unsigned int)(&_imem_start);
    dma_addr[0x400 >> 2] = ((unsigned int)(&_dram_i_end) - (unsigned int)(&_dram_i_start)) / 4 + 1;
    dma_addr[0x100 >> 2] = 1;
    asm("wfi");

    // Booting 2. Move sdata from DRAM to DM
    dma_addr[0x200 >> 2] = (unsigned int)(&__sdata_paddr_start);
    dma_addr[0x300 >> 2] = (unsigned int)(&__sdata_start);
    dma_addr[0x400 >> 2] = ((unsigned int)(&__sdata_end) - (unsigned int)(&__sdata_start)) / 4 + 1;
    dma_addr[0x100 >> 2] = 1;
    asm("wfi");

    // Booting 3. Move data from DRAM to DM
    dma_addr[0x200 >> 2] = (unsigned int)(&__data_paddr_start);
    dma_addr[0x300 >> 2] = (unsigned int)(&__data_start);
    dma_addr[0x400 >> 2] = ((unsigned int)(&__data_end) - (unsigned int)(&__data_start)) / 4 + 1;
    dma_addr[0x100 >> 2] = 1;
    asm("wfi");
}