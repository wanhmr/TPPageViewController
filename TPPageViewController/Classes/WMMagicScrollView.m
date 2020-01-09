// MXScrollView.m
//
// Copyright (c) 2017 Maxime Epain
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

#import "WMMagicScrollView.h"

static NSString * const MXContentOffsetKeyPath = @"contentOffset";

@interface MXScrollViewDelegateForwarder : NSObject <WMMagicScrollViewDelegate>
@property (nonatomic,weak) id<WMMagicScrollViewDelegate> delegate;
@end

@interface WMMagicScrollView () <UIGestureRecognizerDelegate>

@property (nonatomic, strong) MXScrollViewDelegateForwarder *forwarder;
@property (nonatomic, strong) NSMutableArray<UIScrollView *> *observedViews;

@end

@implementation WMMagicScrollView {
    BOOL _isObserving;
    __weak UIScrollView *_trackingSubview;
}

static void * const kMXScrollViewKVOContext = (void*)&kMXScrollViewKVOContext;

@synthesize delegate = _delegate;
@synthesize bounces = _bounces;

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame: frame];
    if (self) {
        [self initialize];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder {
    self = [super initWithCoder:coder];
    if (self) {
        [self initialize];
    }
    return self;
}

- (void)initialize {
    _forwarder = [MXScrollViewDelegateForwarder new];
    super.delegate = self.forwarder;
    
    self.showsVerticalScrollIndicator = NO;
    self.directionalLockEnabled = YES;
    self.bounces = YES;
    
    if (@available(iOS 11.0, *)) {
        self.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
    }
    
    self.panGestureRecognizer.cancelsTouchesInView = NO;
    
    _observedViews = [NSMutableArray array];
    
    [self addObserver:self forKeyPath:MXContentOffsetKeyPath
              options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld
              context:kMXScrollViewKVOContext];
    
    _isObserving = YES;
}

#pragma mark Properties

- (void)setDelegate:(id<WMMagicScrollViewDelegate>)delegate {
    self.forwarder.delegate = delegate;
    // Scroll view delegate caches whether the delegate responds to some of the delegate
    // methods, so we need to force it to re-evaluate if the delegate responds to them
    super.delegate = nil;
    super.delegate = self.forwarder;
}

- (id<WMMagicScrollViewDelegate>)delegate {
    return self.forwarder.delegate;
}

- (CGFloat)maximumContentOffsetY {
    CGFloat value = _headerViewMaximumHeight - _headerViewMinimumHeight;
    CGFloat scale = [UIScreen mainScreen].scale;
    return floor(value * scale) / scale;
}

#pragma mark <UIGestureRecognizerDelegate>

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    
    if (otherGestureRecognizer.view == self) {
        return NO;
    }
    
    // Ignore other gesture than pan
    if (![gestureRecognizer isKindOfClass:[UIPanGestureRecognizer class]]) {
        return NO;
    }
    
    // Lock horizontal pan gesture.
    CGPoint velocity = [(UIPanGestureRecognizer*)gestureRecognizer velocityInView:self];
    if (fabs(velocity.x) > fabs(velocity.y)) {
        return NO;
    }
    
    // Consider scroll view pan only
    if (![otherGestureRecognizer.view isKindOfClass:[UIScrollView class]]) {
        return NO;
    }
    
    UIScrollView *scrollView = (id)otherGestureRecognizer.view;
    
    BOOL shouldScroll = YES;
    if ([self.delegate respondsToSelector:@selector(scrollView:shouldScrollWithSubview:)]) {
        shouldScroll = [self.delegate scrollView:self shouldScrollWithSubview:scrollView];;
    }
    
    if (shouldScroll) {
        [self addObservedView:scrollView];
    }
    
    return shouldScroll;
}

#pragma mark KVO

- (void)addObserverToView:(UIScrollView *)scrollView {
    [scrollView addObserver:self
                 forKeyPath:MXContentOffsetKeyPath
                    options:NSKeyValueObservingOptionOld | NSKeyValueObservingOptionNew
                    context:kMXScrollViewKVOContext];
}

- (void)removeObserverFromView:(UIScrollView *)scrollView {
    @try {
        [scrollView removeObserver:self
                        forKeyPath:MXContentOffsetKeyPath
                           context:kMXScrollViewKVOContext];
    }
    @catch (NSException *exception) {}
}

//This is where the magic happens...
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    
    if (context == kMXScrollViewKVOContext && [keyPath isEqualToString:MXContentOffsetKeyPath]) {

        CGPoint new = [[change objectForKey:NSKeyValueChangeNewKey] CGPointValue];
        CGPoint old = [[change objectForKey:NSKeyValueChangeOldKey] CGPointValue];
        CGFloat diff = old.y - new.y;
        
        if (ABS(diff) < FLT_EPSILON || !_isObserving) return;
        
        BOOL isScrollUp = diff < 0;
        
        CGFloat maximumContentOffsetY = self.maximumContentOffsetY;
        if (object == self) {
            if (!isScrollUp && [self shouldLock]) {
                //Adjust self scroll offset when scroll down
                [self scrollView:self setContentOffset:old];
            } else if (self.contentOffset.y < -self.contentInset.top && !self.bounces) {
                [self scrollView:self setContentOffset:CGPointMake(self.contentOffset.x, -self.contentInset.top)];
            } else if (self.contentOffset.y > maximumContentOffsetY) {
                [self scrollView:self setContentOffset:CGPointMake(self.contentOffset.x, maximumContentOffsetY)];
            } else {
            }
        } else {
            UIScrollView *scrollView = object;
            //Adjust the observed scrollview's content offset
            [self trackSubview:scrollView];
            BOOL shouldLock = [self shouldLock];
            if (isScrollUp) {
                //Manage scroll up
                if (shouldLock && self.contentOffset.y < maximumContentOffsetY) {
                    [self scrollView:scrollView setContentOffset:old];
                }
            } else {
                //Disable bouncing when scroll down
                if (!shouldLock && ((self.contentOffset.y > -self.contentInset.top) || self.bounces)) {
                    [self scrollView:scrollView setContentOffset:CGPointMake(scrollView.contentOffset.x, -scrollView.contentInset.top)];
                }
            }
        }
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

- (void)trackSubview:(UIScrollView *)subview {
    _trackingSubview = subview;
}

- (BOOL)shouldLock {
    return _trackingSubview.contentOffset.y > -_trackingSubview.contentInset.top;
}

#pragma mark Scrolling views handlers

- (void)addObservedView:(UIScrollView *)scrollView {
    [self trackSubview:scrollView];
    
    if (![self.observedViews containsObject:scrollView]) {
        [self.observedViews addObject:scrollView];
        [self addObserverToView:scrollView];
    }
}

- (void)removeObservedViews {
    [self trackSubview:nil];
    
    for (UIScrollView *scrollView in self.observedViews) {
        [self removeObserverFromView:scrollView];
    }
    [self.observedViews removeAllObjects];
}

- (void)scrollView:(UIScrollView *)scrollView setContentOffset:(CGPoint)offset {
    _isObserving = NO;
    scrollView.contentOffset = offset;
    _isObserving = YES;
}

- (void)dealloc {
    [self removeObserver:self forKeyPath:MXContentOffsetKeyPath context:kMXScrollViewKVOContext];
    [self removeObservedViews];
}

#pragma mark <UIScrollViewDelegate>

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    [self removeObservedViews];
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
    if (!decelerate) {
        [self removeObservedViews];
    }
}

@end

@implementation MXScrollViewDelegateForwarder

- (BOOL)respondsToSelector:(SEL)selector {
    return [self.delegate respondsToSelector:selector] || [super respondsToSelector:selector];
}

- (void)forwardInvocation:(NSInvocation *)invocation {
    [invocation invokeWithTarget:self.delegate];
}

#pragma mark <UIScrollViewDelegate>

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    [(WMMagicScrollView *)scrollView scrollViewDidEndDecelerating:scrollView];
    if ([self.delegate respondsToSelector:_cmd]) {
        [self.delegate scrollViewDidEndDecelerating:scrollView];
    }
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
    [(WMMagicScrollView *)scrollView scrollViewDidEndDragging:scrollView willDecelerate:decelerate];
    if ([self.delegate respondsToSelector:_cmd]) {
        [self.delegate scrollViewDidEndDragging:scrollView willDecelerate:decelerate];
    }
}

@end
