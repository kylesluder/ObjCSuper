ObjCSuper
===

A quick-and-dirty implementation of an Objective-C analogue to the Python `super` class.

Though Objective-C, lacking multiple inheritance, has less need than Python for something like this, it serves two purposes:

1. Making `[super respondsToSelector:]` behave as naïvely expected.

Beginning Objective-C programmers often try to use `[super respondsToSelector:]` to test if they should send a message to super. This doesn't do what they expect; since -respondsToSelector: is rarely overridden, `[super respondsToSelector:]` is exactly equivalent to `[self respondsToSelector:]`, and this method winds up returning `YES` when the programmer thinks it should return `NO`.

It's kind of weird that `[super foo]` and `[super respondsToSelector:@selector(foo)]` are out of step like this. This class harmonizes them.

2. Making it easy to invoke grandfather implementations.

The `super` keyword doesn't doesn't afford access to more than one level of ancestry. This class lets you invoke any superclass's implementation of a method. This is particularly useful when overriding a buggy superclass method implementation.
