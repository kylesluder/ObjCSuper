#import "ObjCSuper.h"

#import <Foundation/Foundation.h>
#import <Foundation/NSException.h>
#import <Foundation/NSInvocation.h>
#import <objc/runtime.h>
#import <objc/message.h>

@interface ObjCSuper : NSProxy
@end

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

#pragma mark - NSProxy<NSObject> subclass

- (Class)class;
{
    return [_super.receiver class];
}

- (Class)superclass;
{
    return [_super.receiver superclass];
}

- (BOOL)isEqual:(id)other;
{
    return [_super.receiver isEqual:other];
}

- (NSUInteger)hash;
{
    return [_super.receiver hash];
}

- (BOOL)isKindOfClass:(Class)cls;
{
    return [_super.receiver isKindOfClass:cls];
}

- (BOOL)isMemberOfClass:(Class)cls;
{
    return [_super.receiver isMemberOfClass:cls];
}

- (BOOL)conformsToProtocol:(Protocol *)proto;
{
    return [_super.receiver conformsToProtocol:proto];
}

- (NSString *)description;
{
    return [_super.receiver description];
}

- (NSString *)debugDescription;
{
    return [NSString stringWithFormat:@"<ObjCSuper proxy -- %@:%p>", [_super.receiver class], _super.receiver];
}

#pragma mark - Forwarding

- (BOOL)respondsToSelector:(SEL)sel;
{
    return [[super class] instancesRespondToSelector:sel] || class_getInstanceMethod(_super.super_class, sel) != NULL;
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
    
    class_addMethod([super class], sel, _trampolineImp, method_getTypeEncoding(targetMethod));
    [inv setTarget:self];
    [inv invoke];
}

@end

#pragma mark - API

@implementation NSObject (ObjCSuper)

- (id)super;
{
    return [[[ObjCSuper alloc] initWithTarget:self] autorelease];
}

- (id)superOfClass:(Class)superclass;
{
    return [[[ObjCSuper alloc] initWithTarget:self superclass:superclass] autorelease];
}

@end
