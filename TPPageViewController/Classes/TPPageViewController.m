//
//  TPPageViewController.m
//  Pods-TPPageViewController_Example
//
//  Created by Tpphha on 2018/7/3.
//

#import "TPPageViewController.h"

typedef NS_ENUM(NSInteger, TPAppearanceTransitionState) {
    TPAppearanceTransitionStateNone,
    TPAppearanceTransitionStateWillAppear,
    TPAppearanceTransitionStateDidAppear,
    TPAppearanceTransitionStateWillDisappear,
    TPAppearanceTransitionStateDidDisappear
};

@interface TPQueuedScrollView : UIScrollView

@property (nonatomic, assign, readonly) TPPageViewControllerNavigationOrientation navigationOrientation;

@end

@implementation TPQueuedScrollView

- (instancetype)initWithNavigationOrientation:(TPPageViewControllerNavigationOrientation)navigationOrientation {
    self = [super init];
    if (self) {
        _navigationOrientation = navigationOrientation;
    }
    return self;
}

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer {
    /**
       当 TPMagicTabBarPageViewController 嵌套 TPMagicTabBarPageViewController 的时候，被嵌套的 TPMagicTabBarPageViewController 当展示第一个或者最后一个的时候，外层的 TPMagicTabBarPageViewController 滑动手势并不能被响应。
       这是因为外层的手势被内层的 scrollview 阻止了。内层 scrollView pan 手势的 canPreventGestureRecognizer:（参数为外层层 scrollView pan 手势） 返回 YES。
       原因暂时未知，当嵌套的是 TPTabBarPageViewController 就没有问题。
    */
    BOOL result = [super gestureRecognizerShouldBegin:gestureRecognizer];
    if (result && !self.bounces && gestureRecognizer == self.panGestureRecognizer) {
        UIPanGestureRecognizer *panGestureRecoginser = (UIPanGestureRecognizer *)gestureRecognizer;
        CGFloat contentOffsetX = self.contentOffset.x;
        CGPoint velocity = [panGestureRecoginser velocityInView:self];
        CGFloat beforeInset = self.isOrientationHorizontal ? self.contentInset.left : self.contentInset.top;
        CGFloat afterInset = self.isOrientationHorizontal ? self.contentInset.right : self.contentInset.bottom;
        BOOL isScrollBefore = self.isOrientationHorizontal ? velocity.x > 0 : velocity.y > 0;
        if (isScrollBefore) {
            if (contentOffsetX + beforeInset < FLT_EPSILON) {
                return NO;
            }
        } else {
            if (contentOffsetX + afterInset < FLT_EPSILON) {
                return NO;
            }
        }
    }
    return result;
}

#pragma mark - Setter & Getter

- (BOOL)isOrientationHorizontal {
    return self.navigationOrientation == TPPageViewControllerNavigationOrientationHorizontal;
}

@end

@interface TPPageViewController () <UIScrollViewDelegate>

@property (nonatomic, strong) TPQueuedScrollView *scrollView;
@property (nonatomic, assign) TPPageViewControllerNavigationDirection navigationDirection;
@property (nonatomic, readonly) BOOL isOrientationHorizontal;

@property (nonatomic, strong) UIViewController *beforeViewController;
@property (nonatomic, strong) UIViewController *selectedViewController;
@property (nonatomic, strong) UIViewController *afterViewController;

@property (nonatomic, assign) BOOL scrolling;

// Flag used to prevent isScrolling delegate when shifting scrollView
@property (nonatomic, assign, getter=isAdjustingContentOffset) BOOL adjustingContentOffset;
@property (nonatomic, assign) BOOL loadNewAdjoiningViewControllersOnFinish;

// Used for accurate view appearance messages
@property (nonatomic, assign) BOOL transitionAnimated;

@property (nonatomic, copy) TPPageViewControllerTransitionCompletionBlock didFinishScrollingCompletionBlock;

@property (nonatomic, strong) NSMapTable *childTransitionStateMapTable;

@end

@implementation TPPageViewController

#pragma mark - Initialization

- (instancetype)init {
    self = [super init];
    if (self) {
        _navigationOrientation = TPPageViewControllerNavigationOrientationHorizontal;
    }
    return self;
}

- (instancetype)initWithNavigationOrientation:(TPPageViewControllerNavigationOrientation)navigationOrientation {
    self = [self init];
    if (self) {
        _navigationOrientation = navigationOrientation;
    }
    return self;
}

#pragma mark - Life Cycle

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.childTransitionStateMapTable = [[NSMapTable alloc] initWithKeyOptions:NSPointerFunctionsWeakMemory
                                                                  valueOptions:NSPointerFunctionsStrongMemory
                                                                      capacity:1];
    self.automaticallyAdjustsScrollViewInsets = NO;
    self.scrollView.delegate = self;
    [self.view addSubview:self.scrollView];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self child:self.selectedViewController beginAppearanceTransitionIfPossible:YES animated:animated];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self childEndAppearanceTransitionIfPossible:self.selectedViewController];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self child:self.selectedViewController beginAppearanceTransitionIfPossible:NO animated:animated];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    [self childEndAppearanceTransitionIfPossible:self.selectedViewController];
}

- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
    
    [self adjustScrollView];
    [self layoutPageViews];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Override

- (BOOL)shouldAutomaticallyForwardAppearanceMethods {
    return NO;
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
    [self cancelScrollingIfNeeded];
}

#pragma mark - Public

- (void)selectViewController:(UIViewController *)viewController
                   direction:(TPPageViewControllerNavigationDirection)direction
                    animated:(BOOL)animated
                  completion:(TPPageViewControllerTransitionCompletionBlock)completion {
    if (self.selectedViewController == viewController) {
        [self cancelScrollingIfNeeded];
        [self loadBeforeViewControllerForShowingViewController:viewController];
        [self loadAfterViewControllerForShowingViewController:viewController];
        [self.view setNeedsLayout];
        [self.view layoutIfNeeded];
        if (completion) {
            completion(YES);
        }
        return;
    }
    
    if (direction == TPPageViewControllerNavigationDirectionForward) {
        self.afterViewController = viewController;
        self.loadNewAdjoiningViewControllersOnFinish = YES;
        [self layoutPageViews];
        [self scrollForwardWithAnimated:animated completion:completion];
    } else if (direction == TPPageViewControllerNavigationDirectionReverse) {
        self.beforeViewController = viewController;
        self.loadNewAdjoiningViewControllersOnFinish = YES;
        [self layoutPageViews];
        [self scrollReverseWithAnimated:animated completion:completion];
    }
}

- (void)scrollForwardWithAnimated:(BOOL)animated completion:(TPPageViewControllerTransitionCompletionBlock)completion {
    if (self.afterViewController == nil) {
        if (completion) {
            completion(NO);
        }
        return;
    }
    
    // Cancel current animation and move
    [self cancelScrollingIfNeeded];
    
    // check it again for canceled
    if (self.afterViewController == nil) {
        if (completion) {
            completion(NO);
        }
        return;
    }
    
    self.didFinishScrollingCompletionBlock = completion;
    self.transitionAnimated = animated;
    
    if (self.isOrientationHorizontal) {
        [self.scrollView setContentOffset:CGPointMake(CGRectGetWidth(self.view.bounds) * 2, 0) animated:animated];
    } else {
        [self.scrollView setContentOffset:CGPointMake(0, CGRectGetHeight(self.view.bounds) * 2) animated:animated];
    }
}

- (void)scrollReverseWithAnimated:(BOOL)animated completion:(TPPageViewControllerTransitionCompletionBlock)completion {
    if (self.beforeViewController == nil) {
        if (completion) {
            completion(NO);
        }
        return;
    }
    
    // Cancel current animation and move
    [self cancelScrollingIfNeeded];
    
    // check it again for canceled
    if (self.beforeViewController == nil) {
        if (completion) {
            completion(NO);
        }
        return;
    }
    
    self.didFinishScrollingCompletionBlock = completion;
    self.transitionAnimated = animated;
    
    [self.scrollView setContentOffset:CGPointZero animated:animated];
}

#pragma mark - Private

- (void)cancelScrollingIfNeeded {
    if (!self.isScrolling) {
        return;
    }
    
    CGFloat const viewWidth = CGRectGetWidth(self.view.bounds);
    CGFloat const viewHeight = CGRectGetHeight(self.view.bounds);
    self.scrollView.contentOffset = CGPointMake(self.isOrientationHorizontal ? viewWidth : 0, self.isOrientationHorizontal ? 0 : viewHeight);
}

- (void)performCompletionHanderIfNeeded:(BOOL)completed {
    if (self.didFinishScrollingCompletionBlock) {
        self.didFinishScrollingCompletionBlock(completed);
        self.didFinishScrollingCompletionBlock = nil;
    }
}

- (void)adjustScrollView {
    UIScrollView *scrollView = self.scrollView;
    
    CGFloat const viewWidth = CGRectGetWidth(self.view.bounds);
    CGFloat const viewHeight = CGRectGetHeight(self.view.bounds);
    
    CGFloat beforeInset = 0;
    CGFloat afterInset = 0;
    
    if (self.beforeViewController == nil) {
        beforeInset = self.isOrientationHorizontal ? -viewWidth : -viewHeight;
    }
    
    if (self.afterViewController == nil) {
        afterInset = self.isOrientationHorizontal ? -viewWidth : -viewHeight;
    }
    
    self.adjustingContentOffset = YES;
    if (!CGRectEqualToRect(scrollView.frame, self.view.bounds)) {
        scrollView.frame = self.view.bounds;
        if (self.isOrientationHorizontal) {
            scrollView.contentSize = CGSizeMake(viewWidth * 3, viewHeight);
        } else {
            scrollView.contentSize = CGSizeMake(viewWidth, viewHeight * 3);
        }
    }
    scrollView.contentOffset = CGPointMake(self.isOrientationHorizontal ? viewWidth : 0, self.isOrientationHorizontal ? 0 : viewHeight);
    if (self.isOrientationHorizontal) {
        scrollView.contentInset = UIEdgeInsetsMake(0, beforeInset, 0, afterInset);
    } else {
        scrollView.contentInset = UIEdgeInsetsMake(beforeInset, 0, afterInset, 0);
    }
    self.adjustingContentOffset = NO;
}

- (void)layoutPageViews {
    CGFloat const viewWidth = CGRectGetWidth(self.view.bounds);
    CGFloat const viewHeight = CGRectGetHeight(self.view.bounds);
    
    CGRect beforeViewControllerFrame;
    CGRect selectedViewControllerFrame;
    CGRect afterViewControllerFrame;
    if (self.isOrientationHorizontal) {
        beforeViewControllerFrame = CGRectMake(0, 0, viewWidth, viewHeight);
        selectedViewControllerFrame = CGRectMake(viewWidth, 0, viewWidth, viewHeight);
        afterViewControllerFrame = CGRectMake(viewWidth * 2, 0, viewWidth, viewHeight);
    } else {
        beforeViewControllerFrame = CGRectMake(0, 0, viewWidth, viewHeight);
        selectedViewControllerFrame = CGRectMake(0, viewHeight, viewWidth, viewHeight);
        afterViewControllerFrame = CGRectMake(0, viewHeight * 2, viewWidth, viewHeight);
    }
    
    if ([self.beforeViewController isViewLoaded]) {
        self.beforeViewController.view.frame = beforeViewControllerFrame;
    }
    if ([self.selectedViewController isViewLoaded]) {
        self.selectedViewController.view.frame = selectedViewControllerFrame;
    }
    if ([self.afterViewController isViewLoaded]) {
        self.afterViewController.view.frame = afterViewControllerFrame;
    }
}

- (void)loadBeforeViewControllerForShowingViewController:(UIViewController *)showingViewController {
    // Retreive the new before controller from the data source if available, otherwise set as nil
    self.beforeViewController = [self.dataSource pageViewController:self viewControllerBeforeViewController:showingViewController];
}

- (void)loadAfterViewControllerForShowingViewController:(UIViewController *)showingViewController {
    // Retreive the new after controller from the data source if available, otherwise set as nil
    self.afterViewController = [self.dataSource pageViewController:self viewControllerAfterViewController:showingViewController];
}

- (BOOL)addChildIfNeeded:(UIViewController *)childViewController {
    if (!childViewController) {
        return NO;
    }
    if ([self.childViewControllers containsObject:childViewController]) {
        return NO;
    }
    [self addChildViewController:childViewController];
    [self.scrollView addSubview:childViewController.view];
    [childViewController didMoveToParentViewController:self];
    return YES;
}

- (BOOL)removeChildIfNeeded:(UIViewController *)childViewController {
    if (!childViewController) {
        return NO;
    }
    if (![self.childViewControllers containsObject:childViewController]) {
        return NO;
    }
    [childViewController willMoveToParentViewController:nil];
    [childViewController.view removeFromSuperview];
    [childViewController removeFromParentViewController];
    return YES;
}

- (void)delegateDidFinishScrollingFromViewController:(UIViewController *)startingViewController
                           destinationViewController:(UIViewController *)destinationViewController
                                 transitionCompleted:(BOOL)completed {
    if ([self.delegate respondsToSelector:@selector(pageViewController:didFinishScrollingFromViewController:destinationViewController:transitionCompleted:)]) {
        [self.delegate pageViewController:self didFinishScrollingFromViewController:startingViewController destinationViewController:destinationViewController transitionCompleted:completed];
    }
}

- (void)delegateIsScrollingFromViewController:(nonnull UIViewController *)startingViewController
                    destinationViewController:(nonnull UIViewController *)destinationViewController
                                     progress:(CGFloat)progress {
    if ([self.delegate respondsToSelector:@selector(pageViewController:isScrollingFromViewController:destinationViewController:progress:)]) {
        [self.delegate pageViewController:self isScrollingFromViewController:startingViewController destinationViewController:destinationViewController progress:progress];
    }
}

- (void)updateViewControllersWithShowingViewController:(UIViewController *)showingViewController {
    // Scrolled forward
    if (showingViewController == self.afterViewController) {
        
        // Shift view controllers forward
        self.beforeViewController = self.selectedViewController;
        self.selectedViewController = self.afterViewController;
        
        if ([self removeChildIfNeeded:self.beforeViewController]) {
            [self childEndAppearanceTransitionIfPossible:self.beforeViewController];
        }
        [self childEndAppearanceTransitionIfPossible:self.selectedViewController];
        
        [self delegateDidFinishScrollingFromViewController:self.beforeViewController
                                 destinationViewController:self.selectedViewController
                                       transitionCompleted:YES];
        
        
        [self performCompletionHanderIfNeeded:YES];
        
        // Load new before view controller if required
        if (self.loadNewAdjoiningViewControllersOnFinish) {
            [self loadBeforeViewControllerForShowingViewController:showingViewController];
            self.loadNewAdjoiningViewControllersOnFinish = NO;
        }
        
        // Load new after view controller
        [self loadAfterViewControllerForShowingViewController:showingViewController];
        
        
        // Scrolled reverse
    } else if (showingViewController == self.beforeViewController) {
        
        // Shift view controllers reverse
        self.afterViewController = self.selectedViewController;
        self.selectedViewController = self.beforeViewController;
        
        if ([self removeChildIfNeeded:self.afterViewController]) {
            [self childEndAppearanceTransitionIfPossible:self.afterViewController];
        }
        [self childEndAppearanceTransitionIfPossible:self.selectedViewController];
        
        [self delegateDidFinishScrollingFromViewController:self.afterViewController
                                 destinationViewController:self.selectedViewController
                                       transitionCompleted:YES];
        
        [self performCompletionHanderIfNeeded:YES];
        
        // Load new after view controller if required
        if (self.loadNewAdjoiningViewControllersOnFinish) {
            [self loadAfterViewControllerForShowingViewController:showingViewController];
            self.loadNewAdjoiningViewControllersOnFinish = NO;
        }
        
        // Load new before view controller
        [self loadBeforeViewControllerForShowingViewController:showingViewController];
        
        // Scrolled but ended up where started
    } else if (showingViewController == self.selectedViewController) {
        if (self.navigationDirection == TPPageViewControllerNavigationDirectionForward) {
            [self child:self.afterViewController beginAppearanceTransitionIfPossible:NO animated:self.transitionAnimated];
        } else if (self.navigationDirection == TPPageViewControllerNavigationDirectionReverse) {
            [self child:self.beforeViewController beginAppearanceTransitionIfPossible:NO animated:self.transitionAnimated];
        }
        
        [self child:self.selectedViewController beginAppearanceTransitionIfPossible:YES animated:self.transitionAnimated];
        
        // Remove hidden view controllers
        if ([self removeChildIfNeeded:self.beforeViewController]) {
            [self childEndAppearanceTransitionIfPossible:self.beforeViewController];
        }
        if ([self removeChildIfNeeded:self.afterViewController]) {
            [self childEndAppearanceTransitionIfPossible:self.afterViewController];
        }
        
        [self childEndAppearanceTransitionIfPossible:self.selectedViewController];
        
        if (self.navigationDirection == TPPageViewControllerNavigationDirectionForward) {
            [self delegateDidFinishScrollingFromViewController:self.selectedViewController
                                     destinationViewController:self.afterViewController
                                           transitionCompleted:NO];
            
        } else if (self.navigationDirection == TPPageViewControllerNavigationDirectionReverse) {
            [self delegateDidFinishScrollingFromViewController:self.selectedViewController
                                     destinationViewController:self.beforeViewController
                                           transitionCompleted:NO];
        }
        
        [self performCompletionHanderIfNeeded:NO];
        
        if (self.loadNewAdjoiningViewControllersOnFinish) {
            if (self.navigationDirection == TPPageViewControllerNavigationDirectionForward) {
                [self loadAfterViewControllerForShowingViewController:showingViewController];
            } else if (self.navigationDirection == TPPageViewControllerNavigationDirectionReverse) {
                [self loadBeforeViewControllerForShowingViewController:showingViewController];
            }
            self.loadNewAdjoiningViewControllersOnFinish = NO;
        }
    }
    
    self.navigationDirection = TPPageViewControllerNavigationDirectionNone;
    self.scrolling = NO;
}

- (void)willScrollFromViewController:(UIViewController *)startingViewController toViewController:(UIViewController *)destinationViewController {
    if (startingViewController != nil) {
        if ([self.delegate respondsToSelector:@selector(pageViewController:willStartScrollingFromViewController:destinationViewController:)]) {
            [self.delegate pageViewController:self willStartScrollingFromViewController:startingViewController destinationViewController:destinationViewController];
        }
    }

    [self child:startingViewController beginAppearanceTransitionIfPossible:NO animated:self.transitionAnimated];
    [self child:destinationViewController beginAppearanceTransitionIfPossible:YES animated:self.transitionAnimated];
    [self addChildIfNeeded:destinationViewController];
}

- (void)didFinishScrollingWithShowingViewController:(UIViewController *)showingViewController {
    [self updateViewControllersWithShowingViewController:showingViewController];
    [self adjustScrollView];
    [self layoutPageViews];
}

#pragma mark - Appearance Transition

- (BOOL)child:(UIViewController *)child canBeginAppearanceTransition:(BOOL)isAppearing {
    if (!child) {
        return NO;
    }
    NSNumber *stateNumber = [self.childTransitionStateMapTable objectForKey:child];
    if (!stateNumber) {
        return YES;
    }
    TPAppearanceTransitionState state = stateNumber.integerValue;
    if (isAppearing) {
        if (state == TPAppearanceTransitionStateWillDisappear ||
            state == TPAppearanceTransitionStateDidDisappear) {
            return YES;
        }
    } else {
        if (state == TPAppearanceTransitionStateWillAppear ||
            state == TPAppearanceTransitionStateDidAppear) {
            return YES;
        }
    }
    return NO;
}

- (void)child:(UIViewController *)child beginAppearanceTransition:(BOOL)isAppearing animated:(BOOL)animated {
    TPAppearanceTransitionState toState = isAppearing ? TPAppearanceTransitionStateWillAppear : TPAppearanceTransitionStateWillDisappear;
    [self.childTransitionStateMapTable setObject:@(toState) forKey:child];
    [child beginAppearanceTransition:isAppearing animated:animated];
}

- (void)child:(UIViewController *)child beginAppearanceTransitionIfPossible:(BOOL)isAppearing animated:(BOOL)animated {
    if ([self child:child canBeginAppearanceTransition:isAppearing]) {
        [self child:child beginAppearanceTransition:isAppearing animated:animated];
    }
}

- (BOOL)childCanEndAppearanceTransition:(UIViewController *)child {
    if (!child) {
        return NO;
    }
    NSNumber *stateNumber = [self.childTransitionStateMapTable objectForKey:child];
    TPAppearanceTransitionState state = stateNumber.integerValue;
    if (state == TPAppearanceTransitionStateWillAppear ||
        state == TPAppearanceTransitionStateWillDisappear) {
        return YES;
    }
    return NO;
}

- (void)childEndAppearanceTransition:(UIViewController *)child {
    NSNumber *stateNumber = [self.childTransitionStateMapTable objectForKey:child];
    TPAppearanceTransitionState state = stateNumber.integerValue;
    TPAppearanceTransitionState toState = TPAppearanceTransitionStateNone;
    if (state == TPAppearanceTransitionStateWillAppear) {
        toState = TPAppearanceTransitionStateDidAppear;
    } else if (state == TPAppearanceTransitionStateWillDisappear) {
        toState = TPAppearanceTransitionStateDidDisappear;
    } else {
        NSAssert(NO, @"The state is error.");
    }
    [self.childTransitionStateMapTable setObject:@(toState) forKey:child];
    [child endAppearanceTransition];
}

- (void)childEndAppearanceTransitionIfPossible:(UIViewController *)child {
    if ([self childCanEndAppearanceTransition:child]) {
        [self childEndAppearanceTransition:child];
    }
}

#pragma mark - UIScrollViewDelegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    if (self.isAdjustingContentOffset) {
        return;
    }
    
    CGFloat distance = self.isOrientationHorizontal ? CGRectGetWidth(self.view.bounds) : CGRectGetHeight(self.view.bounds);
    CGFloat progress = ((self.isOrientationHorizontal ? scrollView.contentOffset.x : scrollView.contentOffset.y) - distance) / distance;
    if (progress > FLT_EPSILON) { // Scrolling forward / after
        if (self.afterViewController != nil) {
            if (![self.afterViewController isViewLoaded]) {
                [self.afterViewController view];
                [self layoutPageViews];
            }
            
            if (!self.isScrolling) { // call willScroll once
                [self willScrollFromViewController:self.selectedViewController toViewController:self.afterViewController];
                self.scrolling = YES;
            }
            
            // check if direction changed
            if (self.navigationDirection == TPPageViewControllerNavigationDirectionReverse) {
                [self didFinishScrollingWithShowingViewController:self.selectedViewController];
                [self willScrollFromViewController:self.selectedViewController toViewController:self.afterViewController];
            }
            
            self.navigationDirection = TPPageViewControllerNavigationDirectionForward;
            
            if (self.selectedViewController != nil) {
                [self delegateIsScrollingFromViewController:self.selectedViewController
                                  destinationViewController:self.afterViewController
                                                   progress:progress];
            }
        }
    } else if (progress < -FLT_EPSILON) {
        if (self.beforeViewController != nil) {
            if (![self.beforeViewController isViewLoaded]) {
                [self.beforeViewController view];
                [self layoutPageViews];
            }
            
            if (!self.isScrolling) { // call willScroll once
                [self willScrollFromViewController:self.selectedViewController toViewController:self.beforeViewController];
                self.scrolling = YES;
            }
            
            // check if direction changed
            if (self.navigationDirection == TPPageViewControllerNavigationDirectionForward) {
                [self didFinishScrollingWithShowingViewController:self.selectedViewController];
                [self willScrollFromViewController:self.selectedViewController toViewController:self.beforeViewController];
            }
            
            self.navigationDirection = TPPageViewControllerNavigationDirectionReverse;
            
            if (self.selectedViewController != nil) {
                [self delegateIsScrollingFromViewController:self.selectedViewController
                                  destinationViewController:self.beforeViewController
                                                   progress:progress];
            }
        }
    } else { // At zero
        if (self.navigationDirection == TPPageViewControllerNavigationDirectionForward) {
            [self delegateIsScrollingFromViewController:self.selectedViewController
                              destinationViewController:self.afterViewController
                                               progress:progress];
            
        } else if (self.navigationDirection == TPPageViewControllerNavigationDirectionReverse) {
            [self delegateIsScrollingFromViewController:self.selectedViewController
                              destinationViewController:self.beforeViewController
                                               progress:progress];
        }
    }
    
    // Thresholds to update view layouts call delegates
    if (progress > 1 - FLT_EPSILON && self.afterViewController != nil) {
        [self didFinishScrollingWithShowingViewController:self.afterViewController];
    } else if (progress < -(1 - FLT_EPSILON)  && self.beforeViewController != nil) {
        [self didFinishScrollingWithShowingViewController:self.beforeViewController];
    } else if (ABS(progress) < FLT_EPSILON  && self.selectedViewController != nil) {
        [self didFinishScrollingWithShowingViewController:self.selectedViewController];
    }
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    self.transitionAnimated = YES;
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    // setContentOffset is called to center the selected view after bounces
    // This prevents yucky behavior at the beginning and end of the page collection by making sure setContentOffset is called only if...
    
    if (self.isOrientationHorizontal) {
        if  ((self.beforeViewController != nil && self.afterViewController != nil) || // It isn't at the beginning or end of the page collection
            (self.afterViewController != nil && self.beforeViewController == nil && scrollView.contentOffset.x > fabs(scrollView.contentInset.left)) || // If it's at the beginning of the collection, the decelleration can't be triggered by scrolling away from, than torwards the inset
            (self.beforeViewController != nil && self.afterViewController == nil && scrollView.contentOffset.x < fabs(scrollView.contentInset.right))) { // Same as the last condition, but at the end of the collection
            [scrollView setContentOffset:CGPointMake(CGRectGetWidth(self.view.bounds), 0) animated:YES];
            }
    } else {
        if  ((self.beforeViewController != nil && self.afterViewController != nil) || // It isn't at the beginning or end of the page collection
            (self.afterViewController != nil && self.beforeViewController == nil && scrollView.contentOffset.y > fabs(scrollView.contentInset.top)) || // If it's at the beginning of the collection, the decelleration can't be triggered by scrolling away from, than torwards the inset
            (self.beforeViewController != nil && self.afterViewController == nil && scrollView.contentOffset.y < fabs(scrollView.contentInset.bottom))) { // Same as the last condition, but at the end of the collection
            [scrollView setContentOffset:CGPointMake(0, CGRectGetHeight(self.view.bounds)) animated:YES];
            }
    }
}

#pragma mark - Setter & Getter

- (TPQueuedScrollView *)scrollView {
    if (!_scrollView) {
        _scrollView = [[TPQueuedScrollView alloc] initWithNavigationOrientation:self.navigationOrientation];
        _scrollView.pagingEnabled = YES;
        _scrollView.scrollsToTop = NO;
        _scrollView.autoresizingMask =
        UIViewAutoresizingFlexibleTopMargin |
        UIViewAutoresizingFlexibleLeftMargin |
        UIViewAutoresizingFlexibleBottomMargin |
        UIViewAutoresizingFlexibleRightMargin;
        _scrollView.bounces = NO;
        _scrollView.alwaysBounceHorizontal = NO; // self.isOrientationHorizontal;
        _scrollView.alwaysBounceVertical = NO; // !self.isOrientationHorizontal;
        _scrollView.translatesAutoresizingMaskIntoConstraints = YES;
        _scrollView.showsHorizontalScrollIndicator = NO;
        _scrollView.showsVerticalScrollIndicator = NO;
        if (@available(iOS 11, *)) {
            _scrollView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
        }
    }
    return _scrollView;
}

- (BOOL)isOrientationHorizontal {
    return self.navigationOrientation == TPPageViewControllerNavigationOrientationHorizontal;
}

@end
