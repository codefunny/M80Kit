//
//  M80MulticastDelegate.m
//  M80Kit
//
//  Created by amao on 5/20/14.
//  Copyright (c) 2014 amao. All rights reserved.
//

#import "M80MulticastDelegate.h"

@interface M80DelegateNode : NSObject
@property (nonatomic,weak)  id  nodeDelegate;
+ (M80DelegateNode *)node:(id)delegate;
@end

@implementation M80DelegateNode
+ (M80DelegateNode *)node:(id)delegate
{
    M80DelegateNode *instance = [[M80DelegateNode alloc] init];
    instance.nodeDelegate = delegate;
    return instance;
}
@end


@interface M80MulticastDelegate ()
{
    NSMutableArray *_delegateNodes;
}

@end

@implementation M80MulticastDelegate

- (id)init
{
    if (self = [super init])
    {
        _delegateNodes = [[NSMutableArray alloc] init];
    }
    return self;
}

- (void)dealloc {}

#pragma mark - Delegate增/删
- (void)addDelegate:(id)delegate
{
    [self removeDelegate:delegate];
    M80DelegateNode *node = [M80DelegateNode node:delegate];
    [_delegateNodes addObject:node];
}

- (void)removeDelegate:(id)delegate
{
    NSMutableIndexSet *indexs = [NSMutableIndexSet indexSet];
    for (NSUInteger i = 0; i < [_delegateNodes count]; i ++)
    {
        M80DelegateNode *node = [_delegateNodes objectAtIndex:i];
        if (node.nodeDelegate == delegate)
        {
            [indexs addIndex:i];
        }
    }
    
    if ([indexs count])
    {
        [_delegateNodes removeObjectsAtIndexes:indexs];
    }
}

- (void)removeAllDelegates
{
    [_delegateNodes removeAllObjects];
}

#pragma mark - Selector相关方法
- (NSUInteger)count
{
    return [_delegateNodes count];
}

- (NSUInteger)countForSelector:(SEL)aSelector
{
    NSUInteger count = 0;
    for (M80DelegateNode *node in _delegateNodes)
    {
        if ([node.nodeDelegate respondsToSelector:aSelector])
        {
            count++;
        }
    }
    return count;
}

- (BOOL)hasDelegateThatRespondsToSelector:(SEL)aSelector
{
    BOOL hasSelector = NO;
    for (M80DelegateNode *node in _delegateNodes)
    {
        if ([node.nodeDelegate respondsToSelector:aSelector])
        {
            hasSelector = YES;
            break;
        }
    }
    return hasSelector;
}


#pragma mark - 消息转发
- (NSMethodSignature *)methodSignatureForSelector:(SEL)aSelector
{
	for (M80DelegateNode *node in _delegateNodes)
	{
		NSMethodSignature *method = [node.nodeDelegate methodSignatureForSelector:aSelector];
        if (method)
        {
            return method;
        }
	}
	//如果发现没有可以响应当前方法的Node,就返回一个空方法
    //否则会引起崩溃
	return [[self class] instanceMethodSignatureForSelector:@selector(doNothing)];
}

- (void)forwardInvocation:(NSInvocation *)invocation
{
    SEL selector = [invocation selector];
    BOOL hasNilDelegate = NO;
    
    NSMutableArray *nodeDelegates = [NSMutableArray array];
    
    for (M80DelegateNode *node in _delegateNodes)
    {
        id nodeDelegate = node.nodeDelegate;
        
        if (nodeDelegate == nil)
        {
            hasNilDelegate = YES;
        }
        else if ([nodeDelegate respondsToSelector:selector])
        {
            [nodeDelegates addObject:nodeDelegate];
        }
    }
    
    if (hasNilDelegate)
    {
        [self removeDelegate:nil];
    }
    for (id nodeDelegate in nodeDelegates)
    {
        [invocation invokeWithTarget:nodeDelegate];
    }
}

- (void)doesNotRecognizeSelector:(SEL)aSelector {}

- (void)doNothing {}



@end
