#import <Foundation/Foundation.h>
#import <objc/runtime.h>
#import <objc/message.h>

@interface ObjCSuper : NSProxy
- (id)initWithTarget:(id)target;
- (id)initWithTarget:(id)target superclass:(Class)superclass;
@end

@implementation ObjCSuper
{
    id _target;
    Class _superclass;
}

- (instancetype)initWithTarget:(id)target;
{
    return [self initWithTarget:target superclass:[target superclass]];
}

- (instancetype)initWithTarget:(id)target superclass:(Class)superclass;
{
    _target = [target retain];
    _superclass = [superclass retain];
    
    return self;
}

- (void)dealloc;
{
    [_target release];
    [_superclass release];
    [super dealloc];
}

- (BOOL)respondsToSelector:(SEL)sel;
{
    return [_target respondsToSelector:sel] || [super respondsToSelector:sel];
}

- (NSMethodSignature *)methodSignatureForSelector:(SEL)sel;
{
    return [_target methodSignatureForSelector:sel];
}

- (void)forwardInvocation:(NSInvocation *)inv;
{
    SEL sel = [inv selector];
    
    Class targetClass = [_target class];
    Method targetMethod = class_getInstanceMethod(targetClass, sel);
    NSAssert(targetMethod != nil, @"cannot find instance method for selector %@ of target <%@:%p>", NSStringFromSelector(sel), targetClass, _target);
    
    IMP trampolineImp = imp_implementationWithBlock(^(ObjCSuper *proxy1, ObjCSuper *proxy2, ...) {
        static void *objc_msgSendSuper_fp = &objc_msgSendSuper;
        struct objc_super proxySuper = (struct objc_super){proxy1->_target, proxy1->_superclass};
        struct objc_super *pProxySuper = &proxySuper;
        __asm__("movq %0, %%rdi;"
                "movq %1, %%rsi;"
                "callq *%2;"
                : /* No outputs */
                : "m" (pProxySuper), "r" (sel), "m" (objc_msgSendSuper_fp)
                : /* No clobber */);
    });
    
    class_addMethod([self class], sel, trampolineImp, method_getTypeEncoding(targetMethod));
    [inv setTarget:self];
    [inv invoke];
}

@end



#pragma mark - Test

@interface Foo : NSObject
- (void)someMethod;
@end

@implementation Foo

- (void)someMethod;
{
    NSLog(@"Superclass impl");
}

@end

@interface Bar : Foo
@end

@implementation Bar

- (void)someMethod;
{
    NSLog(@"Subclass impl");
}

@end

int main(int argc, char **argv)
{
    @autoreleasepool {
        Bar *b = [Bar new];
        [b someMethod];
        
        Foo *b_super = (Foo *)[[ObjCSuper alloc] initWithTarget:b];
        [b_super someMethod];
        
        [b_super release];
        [b release];
    }
    
    return 0;
}
