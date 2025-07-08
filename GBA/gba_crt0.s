    .section .gba_crt0, "ax"
    .global _start
    .cpu arm7tdmi
    .extern _start_zig
    .arm

_start:

    // Disable interrupts
    mov r0, #0x4000000
    str r0, [r0, #0x208]

    // Setup IRQ mode stack
    mov r0, #0x12
    msr cpsr, r0
    ldr sp, _start_sp_irq_word

    // Setup system mode stack
    mov r0, #0x1f
    msr cpsr, r0
    ldr sp, _start_sp_usr_word
    
    // Call into zig code
    ldr r0, _start_zig_word
    bx r0

    // Ensure these constants are defined near enough
    // to the entry point to be referenced with `ldr` above.
    .align 4
    _start_sp_irq_word: .word __sp_irq
    _start_sp_usr_word: .word __sp_usr
    _start_zig_word: .word _start_zig
