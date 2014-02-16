// IMP _trampolineImp;
//
// args:
//   %rdi: pointer to ObjCSuper instance
.text
.globl __trampolineImp
.align 4, 0x90
__trampolineImp:
    movq _OBJC_IVAR_$_ObjCSuper._super(%rip), %r11
    leaq (%rdi, %r11), %rdi
    jmpq *_objc_msgSendSuper@GOTPCREL(%rip)
