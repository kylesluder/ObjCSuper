// IMP _trampolineImp;
//
// args:
//   %rdi: pointer to ObjCSuper instance
.text
.globl __trampolineImp
__trampolineImp:
    movq _OBJC_IVAR_$_ObjCSuper._super(%rip), %r11
    leaq (%rdi, %r11), %rdi
    jmpq _objc_msgSendSuper
