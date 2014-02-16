// % clang -framework Foundation -o ObjCSuper ObjCSuper.m
// % ./ObjCSuper
//
// 2014-02-14 15:47:14.715 ObjCSuper[1571:507] Subclass impl
// 2014-02-14 15:47:14.717 ObjCSuper[1571:507] Superclass impl


#import <Foundation/Foundation.h>
#import <objc/runtime.h>
#import <objc/message.h>

@interface ObjCSuper : NSProxy
- (id)initWithTarget:(id)target;
- (id)initWithTarget:(id)target superclass:(Class)superclass;
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
- (void)subclassMethod;
@end

@implementation Bar

- (void)someMethod;
{
    NSLog(@"Subclass impl");
}

- (void)subclassMethod;
{
    NSLog(@"Subclass only method");
}

@end

int main(int argc, char **argv)
{
    @autoreleasepool {
        Bar *b = [Bar new];
        [b someMethod];
        NSLog(@"b respondsToSelector:@selector(retain)? %@", [b respondsToSelector:@selector(retain)] ? @"YES" : @"NO");
        NSLog(@"b respondsToSelector:@selector(subclassMethod)? %@", [b respondsToSelector:@selector(subclassMethod)] ? @"YES" : @"NO");
        
        Foo *b_super = (Foo *)[[ObjCSuper alloc] initWithTarget:b];
        [b_super someMethod];
        NSLog(@"b_super respondsToSelector:@selector(retain)? %@", [b respondsToSelector:@selector(retain)] ? @"YES" : @"NO");
        NSLog(@"b_super respondsToSelector:@selector(subclassMethod)? %@", [b_super respondsToSelector:@selector(subclassMethod)] ? @"YES" : @"NO");
        
        [b_super release];
        [b release];
    }
    
    return 0;
}
