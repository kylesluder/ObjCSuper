#import "ObjCSuper.h"

#import <Foundation/NSException.h>
#import <Foundation/NSInvocation.h>
#import <objc/runtime.h>
#import <objc/message.h>

@implementation ObjCSuper
{
@package
    struct objc_super _super;
}

- (instancetype)initWithTarget:(id)target;
{
    return [self initWithTarget:target superclass:[target superclass]];
}

- (instancetype)initWithTarget:(id)target superclass:(Class)superclass;
{
    NSAssert([target isKindOfClass:superclass], @"target <%@:%p> is not an instance of class %@", [target class], target, superclass);
    
    _super.receiver = [target retain];
    _super.super_class = [superclass retain];
    
    return self;
}

- (void)dealloc;
{
    [_super.receiver release];
    [_super.super_class release];
    [super dealloc];
}

- (BOOL)respondsToSelector:(SEL)sel;
{
    return class_getInstanceMethod(_super.super_class, sel) != NULL || [[self class] instancesRespondToSelector:sel];
}

- (NSMethodSignature *)methodSignatureForSelector:(SEL)sel;
{
    return [_super.receiver methodSignatureForSelector:sel];
}

extern id _trampolineImp(id self, SEL _cmd, ...);

- (void)forwardInvocation:(NSInvocation *)inv;
{
    SEL sel = [inv selector];
    
    Class targetClass = [_super.receiver class];
    Method targetMethod = class_getInstanceMethod(targetClass, sel);
    NSAssert(targetMethod != nil, @"cannot find instance method for selector %@ of target <%@:%p>", NSStringFromSelector(sel), targetClass, _super.receiver);
    
    class_addMethod([self class], sel, _trampolineImp, method_getTypeEncoding(targetMethod));
    [inv setTarget:self];
    [inv invoke];
}

@end



#pragma mark - Test

