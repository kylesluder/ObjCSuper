#import <Foundation/NSProxy.h>

@interface ObjCSuper : NSProxy
- (id)initWithTarget:(id)target;
- (id)initWithTarget:(id)target superclass:(Class)superclass;
@end
