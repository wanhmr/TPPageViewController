//
//  TPMagicCollectionView.m
//  TPPageViewController_Example
//
//  Created by Tpphha on 2018/11/21.
//  Copyright © 2018 tpx. All rights reserved.
//

#import "TPMagicScrollView.h"

static void * const kMXScrollViewKVOContext = (void*)&kMXScrollViewKVOContext;

@interface TPScrollViewDelegateForwarder : NSObject <UIScrollViewDelegate, UITableViewDelegate , UICollectionViewDelegate>
@property (nonatomic,weak) id<UIScrollViewDelegate> delegate;
@end

@interface TPMagicTableView () <UIGestureRecognizerDelegate> {
    BOOL _isObserving;
    BOOL _lock;
}

@property (nonatomic, strong) TPScrollViewDelegateForwarder *forwarder;
@property (nonatomic, strong) NSMutableArray<UIScrollView *> *observedViews;
@property (nonatomic, assign) CGFloat maximumContentOffsetY;
@end

@implementation TPMagicTableView

- (instancetype)initWithFrame:(CGRect)frame{
    self = [super initWithFrame:frame];
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
    _forwarder = [TPScrollViewDelegateForwarder new];
    super.delegate = self.forwarder;
    
    self.showsVerticalScrollIndicator = NO;
    self.directionalLockEnabled = YES;
    self.bounces = YES;
    
    if (@available(iOS 11.0, *)) {
        self.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
    }
    
    self.panGestureRecognizer.cancelsTouchesInView = NO;
    
    _observedViews = [NSMutableArray array];
    
    [self addObserver:self forKeyPath:NSStringFromSelector(@selector(contentOffset))
              options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld
              context:kMXScrollViewKVOContext];
    
    _isObserving = YES;
}

#pragma mark Properties

- (void)setDelegate:(id<UICollectionViewDelegate>)delegate {
    self.forwarder.delegate = delegate;
    // Scroll view delegate caches whether the delegate responds to some of the delegate
    // methods, so we need to force it to re-evaluate if the delegate responds to them
    super.delegate = nil;
    super.delegate = self.forwarder;
}

- (void)setContentSize:(CGSize)contentSize {
    [super setContentSize:contentSize];
    if (self.fetchMaximumContentOffsetYBlock) {
        self.maximumContentOffsetY = self.fetchMaximumContentOffsetYBlock(self);
    }
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
    
    // Tricky case: UITableViewWrapperView
    if ([scrollView.superview isKindOfClass:[UITableView class]]) {
        return NO;
    }
    //tableview on the MXScrollView
    if ([scrollView.superview isKindOfClass:NSClassFromString(@"UITableViewCellContentView")]) {
        return NO;
    }
    
    BOOL shouldScroll = YES;
    if ([self.magicDelegate respondsToSelector:@selector(scrollView:shouldScrollWithSubview:)]) {
        shouldScroll = [self.magicDelegate scrollView:self shouldScrollWithSubview:scrollView];;
    }
    
    if (shouldScroll) {
        [self addObservedView:scrollView];
    }
    
    return shouldScroll;
}

#pragma mark KVO

- (void)addObserverToView:(UIScrollView *)scrollView {
    _lock = (scrollView.contentOffset.y > -scrollView.contentInset.top);
    
    [scrollView addObserver:self
                 forKeyPath:NSStringFromSelector(@selector(contentOffset))
                    options:NSKeyValueObservingOptionOld|NSKeyValueObservingOptionNew
                    context:kMXScrollViewKVOContext];
}

- (void)removeObserverFromView:(UIScrollView *)scrollView {
    @try {
        [scrollView removeObserver:self
                        forKeyPath:NSStringFromSelector(@selector(contentOffset))
                           context:kMXScrollViewKVOContext];
    }
    @catch (NSException *exception) {}
}

//This is where the magic happens...
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    
    if (context == kMXScrollViewKVOContext && [keyPath isEqualToString:NSStringFromSelector(@selector(contentOffset))]) {
        
        CGPoint new = [[change objectForKey:NSKeyValueChangeNewKey] CGPointValue];
        CGPoint old = [[change objectForKey:NSKeyValueChangeOldKey] CGPointValue];
        
        // lock 代表 self 需不需要滚动。
        // diff > 0 向下滑，diff < 0 向上滑。
        CGFloat diff = old.y - new.y;
        
        if (ABS(diff) < FLT_EPSILON || !_isObserving) return;
        
        CGFloat maximumContentOffsetY = _maximumContentOffsetY;
        if (object == self) {
            //Adjust self scroll offset when scroll down
            if (diff > 0 && _lock) {
                [self scrollView:self setContentOffset:old];
            } else if (self.contentOffset.y < -self.contentInset.top && !self.bounces) {
                [self scrollView:self setContentOffset:CGPointMake(self.contentOffset.x, -self.contentInset.top)];
            } else if (self.contentOffset.y > maximumContentOffsetY) {
                [self scrollView:self setContentOffset:CGPointMake(self.contentOffset.x, maximumContentOffsetY)];
            } else {
                // nothing
            }
            
        } else {
            //Adjust the observed scrollview's content offset
            UIScrollView *scrollView = object;
            _lock = (scrollView.contentOffset.y > -scrollView.contentInset.top);
            
            //Manage scroll up
            if (self.contentOffset.y < maximumContentOffsetY && _lock && diff < 0) {
                [self scrollView:scrollView setContentOffset:old];
            }
            //Disable bouncing when scroll down
            if (!_lock && ((self.contentOffset.y > -self.contentInset.top) || self.bounces)) {
                [self scrollView:scrollView setContentOffset:CGPointMake(scrollView.contentOffset.x, -scrollView.contentInset.top)];
            }
        }
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

#pragma mark Scrolling views handlers

- (void)addObservedView:(UIScrollView *)scrollView {
    if (![self.observedViews containsObject:scrollView]) {
        [self.observedViews addObject:scrollView];
        [self addObserverToView:scrollView];
    }
}

- (void)removeObservedViews {
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
    [self removeObserver:self forKeyPath:NSStringFromSelector(@selector(contentOffset)) context:kMXScrollViewKVOContext];
    [self removeObservedViews];
}

#pragma mark TPMagicScrollViewProtocol

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    _lock = NO;
    [self removeObservedViews];
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
    if (!decelerate) {
        _lock = NO;
        [self removeObservedViews];
    }
}

@end

@interface TPMagicCollectionView () <UIGestureRecognizerDelegate> {
    BOOL _isObserving;
    BOOL _lock;
}

@property (nonatomic, strong) TPScrollViewDelegateForwarder *forwarder;
@property (nonatomic, strong) NSMutableArray<UIScrollView *> *observedViews;
@property (nonatomic, assign) CGFloat maximumContentOffsetY;
@end

@implementation TPMagicCollectionView

- (instancetype)initWithFrame:(CGRect)frame collectionViewLayout:(nonnull UICollectionViewLayout *)layout{
    self = [super initWithFrame:frame collectionViewLayout:layout];
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
    _forwarder = [TPScrollViewDelegateForwarder new];
    super.delegate = self.forwarder;
    
    self.showsVerticalScrollIndicator = NO;
    self.directionalLockEnabled = YES;
    self.bounces = YES;
    
    if (@available(iOS 11.0, *)) {
        self.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
    }
    
    self.panGestureRecognizer.cancelsTouchesInView = NO;
    
    _observedViews = [NSMutableArray array];
    
    [self addObserver:self forKeyPath:NSStringFromSelector(@selector(contentOffset))
              options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld
              context:kMXScrollViewKVOContext];
    
    _isObserving = YES;
}

#pragma mark Properties

- (void)setDelegate:(id<UICollectionViewDelegate>)delegate {
    self.forwarder.delegate = delegate;
    // Scroll view delegate caches whether the delegate responds to some of the delegate
    // methods, so we need to force it to re-evaluate if the delegate responds to them
    super.delegate = nil;
    super.delegate = self.forwarder;
}

- (void)setContentSize:(CGSize)contentSize {
    [super setContentSize:contentSize];
    if (self.fetchMaximumContentOffsetYBlock) {
        self.maximumContentOffsetY = self.fetchMaximumContentOffsetYBlock(self);
    }
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
    
    // Tricky case: UITableViewWrapperView
    if ([scrollView.superview isKindOfClass:[UITableView class]]) {
        return NO;
    }
    //tableview on the MXScrollView
    if ([scrollView.superview isKindOfClass:NSClassFromString(@"UITableViewCellContentView")]) {
        return NO;
    }
    
    BOOL shouldScroll = YES;
    if ([self.magicDelegate respondsToSelector:@selector(scrollView:shouldScrollWithSubview:)]) {
        shouldScroll = [self.magicDelegate scrollView:self shouldScrollWithSubview:scrollView];;
    }
    
    if (shouldScroll) {
        [self addObservedView:scrollView];
    }
    
    return shouldScroll;
}

#pragma mark KVO

- (void)addObserverToView:(UIScrollView *)scrollView {
    _lock = (scrollView.contentOffset.y > -scrollView.contentInset.top);
    
    [scrollView addObserver:self
                 forKeyPath:NSStringFromSelector(@selector(contentOffset))
                    options:NSKeyValueObservingOptionOld|NSKeyValueObservingOptionNew
                    context:kMXScrollViewKVOContext];
}

- (void)removeObserverFromView:(UIScrollView *)scrollView {
    @try {
        [scrollView removeObserver:self
                        forKeyPath:NSStringFromSelector(@selector(contentOffset))
                           context:kMXScrollViewKVOContext];
    }
    @catch (NSException *exception) {}
}

//This is where the magic happens...
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    
    if (context == kMXScrollViewKVOContext && [keyPath isEqualToString:NSStringFromSelector(@selector(contentOffset))]) {
        
        CGPoint new = [[change objectForKey:NSKeyValueChangeNewKey] CGPointValue];
        CGPoint old = [[change objectForKey:NSKeyValueChangeOldKey] CGPointValue];
        
        // lock 代表 self 需不需要滚动。
        // diff > 0 向下滑，diff < 0 向上滑。
        CGFloat diff = old.y - new.y;
        
        if (ABS(diff) < FLT_EPSILON || !_isObserving) return;
        
        CGFloat maximumContentOffsetY = _maximumContentOffsetY;
        if (object == self) {
            //Adjust self scroll offset when scroll down
            if (diff > 0 && _lock) {
                [self scrollView:self setContentOffset:old];
            } else if (self.contentOffset.y < -self.contentInset.top && !self.bounces) {
                [self scrollView:self setContentOffset:CGPointMake(self.contentOffset.x, -self.contentInset.top)];
            } else if (self.contentOffset.y > maximumContentOffsetY) {
                [self scrollView:self setContentOffset:CGPointMake(self.contentOffset.x, maximumContentOffsetY)];
            } else {
                // nothing
            }
            
        } else {
            //Adjust the observed scrollview's content offset
            UIScrollView *scrollView = object;
            _lock = (scrollView.contentOffset.y > -scrollView.contentInset.top);
            
            //Manage scroll up
            if (self.contentOffset.y < maximumContentOffsetY && _lock && diff < 0) {
                [self scrollView:scrollView setContentOffset:old];
            }
            //Disable bouncing when scroll down
            if (!_lock && ((self.contentOffset.y > -self.contentInset.top) || self.bounces)) {
                [self scrollView:scrollView setContentOffset:CGPointMake(scrollView.contentOffset.x, -scrollView.contentInset.top)];
            }
        }
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

#pragma mark Scrolling views handlers

- (void)addObservedView:(UIScrollView *)scrollView {
    if (![self.observedViews containsObject:scrollView]) {
        [self.observedViews addObject:scrollView];
        [self addObserverToView:scrollView];
    }
}

- (void)removeObservedViews {
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
    [self removeObserver:self forKeyPath:NSStringFromSelector(@selector(contentOffset)) context:kMXScrollViewKVOContext];
    [self removeObservedViews];
}

#pragma mark TPMagicScrollViewProtocol

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    _lock = NO;
    [self removeObservedViews];
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
    if (!decelerate) {
        _lock = NO;
        [self removeObservedViews];
    }
}

@end

@implementation TPScrollViewDelegateForwarder

- (BOOL)respondsToSelector:(SEL)selector {
    return [self.delegate respondsToSelector:selector] || [super respondsToSelector:selector];
}

- (NSMethodSignature *)methodSignatureForSelector:(SEL)aSelector {
    NSMethodSignature *signature = [[self.delegate class] instanceMethodSignatureForSelector:aSelector];
    if (signature) {
        return signature;
    }
    return [NSMethodSignature signatureWithObjCTypes:"@^v^c"];
}

- (void)forwardInvocation:(NSInvocation *)anInvocation {
    [anInvocation invokeWithTarget:self.delegate];
}

#pragma mark <UIScrollViewDelegate>

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    [(id<TPMagicScrollViewProtocol>)scrollView scrollViewDidEndDecelerating:scrollView];
    if ([self.delegate respondsToSelector:_cmd]) {
        [self.delegate scrollViewDidEndDecelerating:scrollView];
    }
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
    [(id<TPMagicScrollViewProtocol>)scrollView scrollViewDidEndDragging:scrollView willDecelerate:decelerate];
    if ([self.delegate respondsToSelector:_cmd]) {
        [self.delegate scrollViewDidEndDragging:scrollView willDecelerate:decelerate];
    }
}

@end
