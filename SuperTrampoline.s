// IMP _trampolineImp;
//
// args:
//   %rdi: pointer to ObjCSuper instance:
//
//   @interface ObjCSuper {
//       id _target;
//       Class _superclass;
//   }
__trampolineImp:
    .text
    .globl __trampolineImp

    push %rbp
    mov %rsp, %rbp

    // create an objc_super structure
    //
    // struct objc_super {
    //   id receiver;
    //   Class superclass;
    // }
    sub $16, %rsp

    // objc_super.receiver = self->_target
    movq _OBJC_IVAR_$_ObjCSuper._target(%rip), %r11
    movq (%rdi, %r11), %rdi
    movq %rdi, -8(%rbp)

    // objc_super.superclass = self->_superclass
    movq _OBJC_IVAR_$_ObjCSuper._superclass(%rip), %r11
    movq (%rdi, %r11), %rdi
    movq %rdi, -16(%rbp)

    // objc_msgSendSuper takes pointer to objc_super as first arg
    leaq -16(%rbp), %rdi

    // return objc_msgSendSuper(...)
    jmpq _objc_msgSendSuper
