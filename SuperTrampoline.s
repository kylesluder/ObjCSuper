// IMP _trampolineImp;
//
// args:
//   %rdi: pointer to ObjCSuper instance
__trampolineImp:
    .text
    .globl __trampolineImp

    movq _OBJC_IVAR_$_ObjCSuper._super(%rip), %r11
    leaq (%rdi, %r11), %rdi
    jmp _objc_msgSendSuper
