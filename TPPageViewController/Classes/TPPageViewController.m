//
//  TPPageViewController.m
//  Pods-TPPageViewController_Example
//
//  Created by Tpphha on 2018/7/3.
//

#import "TPPageViewController.h"

@interface TPPageViewController () <UIScrollViewDelegate>

@property (nonatomic, strong) UIScrollView *scrollView;
@property (nonatomic, assign) TPPageViewControllerNavigationDirection navigationDirection;
@property (nonatomic, assign) TPPageViewControllerNavigationOrientation navigationOrientation;
@property (nonatomic, readonly) BOOL isOrientationHorizontal;

@property (nonatomic, strong) UIViewController *beforeViewController;
@property (nonatomic, strong) UIViewController *selectedViewController;
@property (nonatomic, strong) UIViewController *afterViewController;

@property (nonatomic, assign, getter=isScrolling) BOOL scrolling;

// Flag used to prevent isScrolling delegate when shifting scrollView
@property (nonatomic, assign, getter=isAdjustingContentOffset) BOOL adjustingContentOffset;
@property (nonatomic, assign) BOOL loadNewAdjoiningViewControllersOnFinish;

// Used for accurate view appearance messages
@property (nonatomic, assign) BOOL transitionAnimated;

@property (nonatomic, copy) TPPageViewControllerTransitionCompletionHandler didFinishScrollingCompletionHandler;

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
    self.automaticallyAdjustsScrollViewInsets = NO;
    self.scrollView.delegate = self;
    [self.view addSubview:self.scrollView];
}

- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
    
    if (!CGRectEqualToRect(self.scrollView.frame, self.view.bounds)) {
        self.adjustingContentOffset = YES;
        self.scrollView.frame = self.view.bounds;
        if (self.isOrientationHorizontal) {
            self.scrollView.contentSize = CGSizeMake(CGRectGetWidth(self.view.bounds) * 3, CGRectGetHeight(self.view.bounds));
        } else {
            self.scrollView.contentSize = CGSizeMake(CGRectGetWidth(self.view.bounds), CGRectGetHeight(self.view.bounds) * 3);
        }
        self.adjustingContentOffset = NO;
    }
    
    [self layoutViews];
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
                  completion:(TPPageViewControllerTransitionCompletionHandler)completion {
    if (direction == TPPageViewControllerNavigationDirectionForward) {
        self.afterViewController = viewController;
        [self layoutViews];
        self.loadNewAdjoiningViewControllersOnFinish = YES;
        [self scrollForwardWithAnimated:animated completion:completion];
    } else if (direction == TPPageViewControllerNavigationDirectionReverse) {
        self.beforeViewController = viewController;
        [self layoutViews];
        self.loadNewAdjoiningViewControllersOnFinish = YES;
        [self scrollReverseWithAnimated:animated completion:completion];
    }
}

- (void)scrollForwardWithAnimated:(BOOL)animated completion:(TPPageViewControllerTransitionCompletionHandler)completion {
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
    
    self.didFinishScrollingCompletionHandler = completion;
    self.transitionAnimated = animated;
    
    if (self.isOrientationHorizontal) {
        [self.scrollView setContentOffset:CGPointMake(CGRectGetWidth(self.view.bounds) * 2, 0) animated:animated];
    } else {
        [self.scrollView setContentOffset:CGPointMake(0, CGRectGetHeight(self.view.bounds) * 2) animated:animated];
    }
}

- (void)scrollReverseWithAnimated:(BOOL)animated completion:(TPPageViewControllerTransitionCompletionHandler)completion {
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
    
    self.didFinishScrollingCompletionHandler = completion;
    self.transitionAnimated = animated;
    
    [self.scrollView setContentOffset:CGPointZero animated:animated];
}

#pragma mark - Private

- (void)cancelScrollingIfNeeded {
    if (!self.isScrolling) {
        return;
    }
    
    if (self.navigationDirection == TPPageViewControllerNavigationDirectionForward) {
        if (self.isOrientationHorizontal) {
            [self.scrollView setContentOffset:CGPointMake(CGRectGetWidth(self.view.bounds) * 2, 0) animated:NO];
        } else {
            [self.scrollView setContentOffset:CGPointMake(0, CGRectGetHeight(self.view.bounds) * 2) animated:NO];
        }
    } else if (self.navigationDirection == TPPageViewControllerNavigationDirectionReverse) {
        [self.scrollView setContentOffset:CGPointZero animated:NO];
    }
}

- (void)performCompletionHanderIfNeeded:(BOOL)completed {
    if (self.didFinishScrollingCompletionHandler) {
        self.didFinishScrollingCompletionHandler(completed);
        self.didFinishScrollingCompletionHandler = nil;
    }
}

- (void)layoutViews {
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
    self.scrollView.contentOffset = CGPointMake(self.isOrientationHorizontal ? viewWidth : 0, self.isOrientationHorizontal ? 0 : viewHeight);
    if (self.isOrientationHorizontal) {
        self.scrollView.contentInset = UIEdgeInsetsMake(0, beforeInset, 0, afterInset);
    } else {
        self.scrollView.contentInset = UIEdgeInsetsMake(beforeInset, 0, afterInset, 0);
    }
    self.adjustingContentOffset = NO;
    
    if (self.isOrientationHorizontal) {
        self.beforeViewController.view.frame = CGRectMake(0, 0, viewWidth, viewHeight);
        self.selectedViewController.view.frame = CGRectMake(viewWidth, 0, viewWidth, viewHeight);
        self.afterViewController.view.frame = CGRectMake(viewWidth * 2, 0, viewWidth, viewHeight);
    } else {
        self.beforeViewController.view.frame = CGRectMake(0, 0, viewWidth, viewHeight);
        self.selectedViewController.view.frame = CGRectMake(0, viewHeight, viewWidth, viewHeight);
        self.afterViewController.view.frame = CGRectMake(0, viewHeight * 2, viewWidth, viewHeight);
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

- (void)addChildIfNeeded:(UIViewController *)childViewController {
    if ([self.childViewControllers containsObject:childViewController]) {
        return;
    }
    [self addChildViewController:childViewController];
    [self.scrollView addSubview:childViewController.view];
    [childViewController didMoveToParentViewController:self];
}

- (void)removeChildIfNeeded:(UIViewController *)childViewController {
    if (![self.childViewControllers containsObject:childViewController]) {
        return;
    }
    [childViewController willMoveToParentViewController:nil];
    [childViewController.view removeFromSuperview];
    [childViewController removeFromParentViewController];
    // if it's remove, we can safe called
    [childViewController endAppearanceTransition];
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
        
        [self removeChildIfNeeded:self.beforeViewController];
        [self.selectedViewController endAppearanceTransition];
        
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
        
        [self removeChildIfNeeded:self.afterViewController];
        [self.selectedViewController endAppearanceTransition];
        
        [self delegateDidFinishScrollingFromViewController:self.afterViewController destinationViewController:self.selectedViewController transitionCompleted:YES];
        
        
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
            [self.afterViewController beginAppearanceTransition:NO animated:self.transitionAnimated];
        } else if (self.navigationDirection == TPPageViewControllerNavigationDirectionReverse) {
            [self.beforeViewController beginAppearanceTransition:NO animated:self.transitionAnimated];
        }
        
        [self.selectedViewController beginAppearanceTransition:YES animated:self.transitionAnimated];
        
        // Remove hidden view controllers
        [self removeChildIfNeeded:self.beforeViewController];
        [self removeChildIfNeeded:self.afterViewController];
        
        [self.selectedViewController endAppearanceTransition];
        
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
    
    [startingViewController beginAppearanceTransition:NO animated:self.transitionAnimated];
    [destinationViewController beginAppearanceTransition:YES animated:self.transitionAnimated];
    [self addChildIfNeeded:destinationViewController];
}

- (void)didFinishScrollingWithShowingViewController:(UIViewController *)showingViewController {
    [self updateViewControllersWithShowingViewController:showingViewController];
    [self layoutViews];
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
    } else if (progress < FLT_EPSILON) {
        if (self.beforeViewController != nil) {
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

- (UIScrollView *)scrollView {
    if (!_scrollView) {
        _scrollView = [UIScrollView new];
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
