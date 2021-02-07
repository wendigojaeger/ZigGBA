MEMORY {
    rom	: ORIGIN = 0x08000000, LENGTH = 32M
    iwram	: ORIGIN = 0x03000000, LENGTH = 32K
    ewram	: ORIGIN = 0x02000000, LENGTH = 256K
}

ENTRY(__text_start)

OUTPUT_FORMAT("elf32-littlearm", "elf32-bigarm", "elf32-littlearm")
OUTPUT_ARCH(arm)

__text_start = ORIGIN(rom);
__eheap_end = ORIGIN(ewram) + LENGTH(ewram);
__iwram_start = ORIGIN(iwram);
__iwram_top = ORIGIN(iwram) + LENGTH(iwram);
__sp_irq = __iwram_top - 0x060;
__sp_usr = __sp_irq - 0x0a0;
__irq_flags = 0x03007ff8;

SECTIONS
{
    . = __text_start;

    .text :
    {
        KEEP(*(.gbaheader))
        KEEP(*(.gbamain))
        *(EXCLUDE_FILE (*.iwram*) .text*)
        . ALIGN(4);
    } >rom = 0xff

    __text_end = .;
    .fini :
    {
        KEEP (*(.fini))
        . = ALIGN(4);
    } >rom =0

    .rodata : {
        *(.rodata*)
        . = ALIGN(4);
    } >rom = 0xff

    .ARM.extab   : { *(.ARM.extab* .gnu.linkonce.armextab.*) } >rom
    __exidx_start = .;
    .ARM.exidx   : { *(.ARM.exidx* .gnu.linkonce.armexidx.*) } >rom
    __exidx_end = .;

    __data_lma = .;
    .data : AT(__data_lma) {
        __data_start__ = ABSOLUTE(.);
        *(.data)
        . = ALIGN(4);
        __data_end__ = ABSOLUTE(.);
    } >ewram = 0xff

    __bss_lma = .;
    .bss ALIGN(4) (NOLOAD): AT(__bss_lma) {
        __bss_start__ = ABSOLUTE(.);
        *(.dynbss)
        *(.gnu.linkonce.b*)
        *(.bss)
        *(COMMON)
        . = ALIGN(4);
        __bss_end__ = ABSOLUTE(.);
    } >ewram
}