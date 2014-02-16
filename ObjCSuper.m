// % clang -framework Foundation -o ObjCSuper ObjCSuper.m SuperTrampoline.s
// % ./ObjCSuper
//
// 2014-02-15 23:03:32.498 ObjCSuper[1296:507] Subclass impl
// 2012014-02-15 23:03:32.498 ObjCSuper[1296:507] Subclass impl4-02-15 23:03:32.500 ObjCSuper[1296:507] b respondsToSelector:@selector(retain)? YES
// 2014-02-15 23:03:32.500 ObjCSuper[1296:507] b respondsToSelector:@selector(subclassMethod)? YES
// 2014-02-15 23:03:32.501 ObjCSuper[1296:507] Superclass impl
// 2014-02-15 23:03:32.501 ObjCSuper[1296:507] b_super respondsToSelector:@selector(retain)? YES
// 2014-02-15 23:03:32.501 ObjCSuper[1296:507] b_super respondsToSelector:@selector(subclassMethod)? NO

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

@interface Grandparent : NSObject
- (void)someMethod;
@end

@implementation Grandparent

- (void)someMethod;
{
    NSLog(@"%s Superclass impl", __PRETTY_FUNCTION__);
}

@end

@interface Parent : Grandparent
- (void)subclassMethod;
@end

@interface Child : Parent
@end

@interface Unrelated : Grandparent
@end

@implementation Parent

- (void)someMethod;
{
    NSLog(@"%s Subclass impl", __PRETTY_FUNCTION__);
}

- (void)subclassMethod;
{
    NSLog(@"%s Subclass only method", __PRETTY_FUNCTION__);
}

@end

@implementation Child

- (void)someMethod;
{
    NSLog(@"%s Overridden method", __PRETTY_FUNCTION__);
}

@end

@implementation Unrelated
@end

int main(int argc, char **argv)
{
    @autoreleasepool {
        Child *b = [Child new];
        [b someMethod];
        NSLog(@"b respondsToSelector:@selector(subclassMethod)? %@", [b respondsToSelector:@selector(subclassMethod)] ? @"YES" : @"NO");
        
        Parent *b_super = (Parent *)[[ObjCSuper alloc] initWithTarget:b];
        [b_super someMethod];
        NSLog(@"b_super respondsToSelector:@selector(subclassMethod)? %@", [b_super respondsToSelector:@selector(subclassMethod)] ? @"YES" : @"NO");
        
        Grandparent *b_super2 = (Parent *)[[ObjCSuper alloc] initWithTarget:b superclass:[Grandparent class]];
        [b_super2 someMethod];
        NSLog(@"b_super2 respondsToSelector:@selector(subclassMethod)? %@", [b_super2 respondsToSelector:@selector(subclassMethod)] ? @"YES" : @"NO");
        
        @try {
            Unrelated *u = (Unrelated *)[[ObjCSuper alloc] initWithTarget:b superclass:[Unrelated class]];
            [u someMethod];
            NSLog(@"u respondsToSelector:@selector(subclassMethod)? %@", [u respondsToSelector:@selector(subclassMethod)] ? @"YES" : @"NO");
        } @catch (id exc) {
            NSLog(@"Caught exception while trying to treat Unrelated as a superclass of Child: %@", exc);
        }
        
        [b_super2 release];
        [b_super release];
        [b release];
    }
    
    return 0;
}
