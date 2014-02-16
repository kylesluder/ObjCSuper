// % clang -framework Foundation -o ObjCSuper main.m ObjCSuper.m SuperTrampoline.s
// % ./ObjCSuper
//
// -[Child someMethod] Overridden method
// b respondsToSelector:@selector(subclassMethod)? YES
// -[Parent someMethod] Subclass impl
// b_super respondsToSelector:@selector(subclassMethod)? YES
// -[Grandparent someMethod] Superclass impl
// b_super2 respondsToSelector:@selector(subclassMethod)? NO
// *** Assertion failure in -[ObjCSuper initWithTarget:superclass:], ObjCSuper.m:21
// Caught exception while trying to treat Unrelated as a superclass of Child: target <Child:0x7fbe28502ca0> is not an instance of class Unrelated

#import <Foundation/NSObject.h>
#import "ObjCSuper.h"

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
        
        Parent *b_super = (Parent *)[b super];
        [b_super someMethod];
        NSLog(@"b_super respondsToSelector:@selector(subclassMethod)? %@", [b_super respondsToSelector:@selector(subclassMethod)] ? @"YES" : @"NO");
        
        Grandparent *b_super2 = (Parent *)[b superOfClass:[Grandparent class]];
        [b_super2 someMethod];
        NSLog(@"b_super2 respondsToSelector:@selector(subclassMethod)? %@", [b_super2 respondsToSelector:@selector(subclassMethod)] ? @"YES" : @"NO");
        
        @try {
            Unrelated *u = (Unrelated *)[b superOfClass:[Unrelated class]];
            [u someMethod];
            NSLog(@"u respondsToSelector:@selector(subclassMethod)? %@", [u respondsToSelector:@selector(subclassMethod)] ? @"YES" : @"NO");
        } @catch (id exc) {
            NSLog(@"Caught exception while trying to treat Unrelated as a superclass of Child: %@", exc);
        }
        
        [b release];
    }
    
    return 0;
}
