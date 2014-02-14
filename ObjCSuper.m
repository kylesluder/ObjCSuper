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

- (id)forwardingTargetForSelector:(SEL)sel;
{
    if ([_target respondsToSelector:sel]) {
        [self __objc_super_addTrampolineForSelector:sel];
        return self;
    } else {
        return nil;
    }
}

- (void)__objc_super_addTrampolineForSelector:(SEL)sel;
{
    Class targetClass = [_target class];
    Method targetMethod = class_getInstanceMethod(targetClass, sel);
    NSAssert(targetMethod != nil, @"target <%@:%p> to respond to instance method selector %@, but could not find an instance method for it", targetClass, _target, NSStringFromSelector(sel));
    
    IMP trampolineImp = _generateTrampoline(sel, _target, _superclass);
    
    class_addMethod([self class], sel, trampolineImp, method_getTypeEncoding(targetMethod));
}

static IMP _generateTrampoline(SEL sel, id target, Class superclass)
{
    static void *objc_msgSendSuper_fp = &objc_msgSendSuper;
    
    return imp_implementationWithBlock(^(id self1, id self2, ...) {
        struct objc_super ourSuper = (struct objc_super){target, superclass};
        struct objc_super *pOurSuper = &ourSuper;
        __asm__("movq %0, %%rdi;"
                "movq %1, %%rsi;"
                "jmpq *%2;"
                :
                : "m" (pOurSuper), "r" (sel), "m" (objc_msgSendSuper_fp)
                :);
    });
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
