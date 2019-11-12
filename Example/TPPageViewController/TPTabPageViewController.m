//
//  TPTabPageViewController.m
//  TPPageViewController_Example
//
//  Created by Tpphha on 2018/11/21.
//  Copyright © 2018 tpx. All rights reserved.
//

#import "TPTabPageViewController.h"
#import <objc/runtime.h>
#import <TPPageViewController/TPPageViewController.h>
#import <KVOController/KVOController.h>

static NSString* const TPContentOffsetKeyPath = @"contentOffset";

static NSUInteger TPIndexFromView(UIView *view) {
    return view.tag;
}

@implementation UIViewController (TPTabPageViewController)

- (void)setTp_pageIndex:(NSNumber *)tp_pageIndex {
    objc_setAssociatedObject(self, @selector(tp_pageIndex), tp_pageIndex, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

- (NSNumber *)tp_pageIndex {
    return objc_getAssociatedObject(self, _cmd);
}

@end

@interface TPTabPageViewController () <
    TPPageViewControllerDataSource,
    TPPageViewControllerDelegate
>

@property (nonatomic, strong) TPPageViewController *pageViewController;
@property (nonatomic, assign) NSUInteger numberOfViewControllers;
@property (nonatomic, strong) NSCache<NSNumber *, UIViewController *> *viewControllerCache;

@property (nonatomic, strong) UIView *tabBar;
@property (nonatomic, assign) CGFloat tabBarHeight;

@property (nonatomic, strong) UIView *headerView;
@property (nonatomic, assign) CGFloat headerViewMinimumHeight;
@property (nonatomic, assign) CGFloat headerViewMaximumHeight;

@end

@implementation TPTabPageViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    TPPageViewController *pageViewController = [[TPPageViewController alloc] initWithNavigationOrientation:TPPageViewControllerNavigationOrientationHorizontal];
    pageViewController.delegate = self;
    pageViewController.dataSource = self;
    [self addChildViewController:pageViewController];
    [self.view addSubview:pageViewController.view];
    [pageViewController didMoveToParentViewController:self];
    self.pageViewController = pageViewController;
    
    self.viewControllerCache = [NSCache new];
    
    [self reloadData];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    self.pageViewController.view.frame = self.view.bounds;
}

- (void)setSelectedIndex:(NSUInteger)selectedIndex animated:(BOOL)animated {
    TPPageViewControllerNavigationDirection direction = TPPageViewControllerNavigationDirectionForward;
    if (selectedIndex < self.selectedIndex) {
        direction = TPPageViewControllerNavigationDirectionReverse;
    }
    
    [self.pageViewController selectViewController:[self viewControllerAtIndex:selectedIndex]
                                        direction:direction
                                         animated:animated
                                       completion:nil];
}

- (void)reloadData {
    [self.viewControllerCache removeAllObjects];
    
    self.numberOfViewControllers = [self.dataSources numberOfViewControllersInPageViewController:self];
    
    if (self.headerView.superview) {
        [self.headerView removeFromSuperview];
    }
    if (self.tabBar.superview) {
        [self.tabBar removeFromSuperview];
    }
    
    self.headerView = nil;
    self.tabBar = nil;
    
    if ([self.dataSources respondsToSelector:@selector(headerViewInPageViewController:)]) {
        self.headerView = [self.dataSources headerViewInPageViewController:self];
        self.headerViewMinimumHeight = [self.delegate pageViewController:self minimumHeightForHeaderView:self.headerView];
        self.headerViewMaximumHeight = [self.delegate pageViewController:self maximumHeightForHeaderView:self.headerView];
    }

    if ([self.dataSources respondsToSelector:@selector(tabBarInPageViewController:)]) {
        self.tabBar = [self.dataSources tabBarInPageViewController:self];
        self.tabBarHeight = [self.delegate pageViewController:self heightForTabBar:self.tabBar];
    }
    
    if (self.headerView) {
        [self.view addSubview:self.headerView];
    }
    if (self.tabBar) {
        [self.view addSubview:self.tabBar];
    }
    
    [self.pageViewController selectViewController:[self viewControllerAtIndex:self.selectedIndex]
                                        direction:TPPageViewControllerNavigationDirectionForward
                                         animated:NO
                                       completion:nil];
}

#pragma mark - Utils

- (UIViewController *)viewControllerAtIndex:(NSUInteger)index {
    NSAssert(index < self.numberOfViewControllers, @"");
    
    UIViewController *viewController = [self.viewControllerCache objectForKey:@(index)];
    if (!viewController) {
        viewController = [self.dataSources pageViewController:self viewControllerAtIndex:index];
        viewController.tp_pageIndex = @(index);
        [self bindViewControllerIfNeeded:viewController atIndex:index];
        [self.viewControllerCache setObject:viewController forKey:@(index)];
    }
    
    return viewController;
}

- (NSUInteger)indexForViewController:(UIViewController *)viewController {
    return viewController.tp_pageIndex.unsignedIntegerValue;
}

- (CGFloat)pageContentMinimumTopInsetAtIndex:(NSUInteger)index {
    return self.headerViewMinimumHeight + self.tabBarHeight;
}

- (CGFloat)pageContentMaximumTopInsetAtIndex:(NSUInteger)index {
    return self.headerViewMaximumHeight + self.tabBarHeight;
}

- (UIScrollView *)contentScrollViewForViewController:(UIViewController *)viewController {
    UIScrollView *scrollView = nil;
    if ([viewController conformsToProtocol:@protocol(TPTabPageContentProtocol)]) {
        scrollView = [(id<TPTabPageContentProtocol>)viewController preferredContentScrollView];
    }
    return scrollView;
}

- (void)configureContentScrollViewWithViewController:(UIViewController *)viewController {
    UIScrollView *scrollView = [self contentScrollViewForViewController:viewController];
    if (!scrollView) {
        return;
    }
    CGFloat contentOffsetX = scrollView.contentOffset.x;
    CGFloat contentOffsetY = scrollView.contentOffset.y;
    
    NSUInteger index = TPIndexFromView(scrollView);
    CGFloat pageContentMinimumTopInset = [self pageContentMinimumTopInsetAtIndex:index];
    CGFloat pageContentMaximumTopInset = [self pageContentMaximumTopInsetAtIndex:index];
    
    CGFloat tabBarMaxY = CGRectGetMaxY(self.tabBar.frame);
    
    if (ABS(tabBarMaxY - pageContentMinimumTopInset) < FLT_EPSILON) { // top
        if (contentOffsetY < -pageContentMinimumTopInset) {
            scrollView.contentOffset = CGPointMake(contentOffsetX, -pageContentMinimumTopInset);
        }
    } else if (ABS(tabBarMaxY - pageContentMaximumTopInset) < FLT_EPSILON) { // bottom
        if (contentOffsetY > -pageContentMaximumTopInset) {
            scrollView.contentOffset = CGPointMake(contentOffsetX, -pageContentMaximumTopInset);
        }
    } else { // other
        scrollView.contentOffset = CGPointMake(contentOffsetX, -tabBarMaxY);
    }
}

- (void)bindViewControllerIfNeeded:(UIViewController *)viewController atIndex:(NSUInteger)index {
    UIScrollView *scrollView = [self contentScrollViewForViewController:viewController];
    if (!scrollView) {
        return;
    }
    
    scrollView.tag = index;
    
    if (@available(iOS 11, *)) {
        scrollView.contentInsetAdjustmentBehavior =  UIScrollViewContentInsetAdjustmentNever;
    } else {
        viewController.automaticallyAdjustsScrollViewInsets = NO;
    }
    
    UIEdgeInsets contentInset = scrollView.contentInset;
    
    scrollView.contentInset = UIEdgeInsetsMake([self pageContentMaximumTopInsetAtIndex:index],
                                               contentInset.left,
                                               contentInset.bottom,
                                               contentInset.right);
    scrollView.scrollIndicatorInsets = scrollView.contentInset;
    
    __weak __typeof(self) weakSelf = self;
    [self.KVOController observe:scrollView
                        keyPath:NSStringFromSelector(@selector(contentOffset))
                        options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew
                          block:^(id  _Nullable observer, id  _Nonnull object, NSDictionary<NSString *,id> * _Nonnull change) {
        __strong __typeof(weakSelf) strongSelf = weakSelf;
        [strongSelf contentScrollViewDidScroll:object];
    }];

    scrollView.contentOffset = CGPointMake(0, -scrollView.contentInset.top);
}

- (void)contentScrollViewDidScroll:(UIScrollView *)scrollView {
    NSInteger index = TPIndexFromView(scrollView);
    
    if (index != self.selectedIndex) {
        return;
    }
    
    [self layoutHeaderViewAndTabBarByScrollView:scrollView];
}

#pragma mark - Layout

- (void)layoutHeaderViewAndTabBarByScrollView:(UIScrollView *)scrollView {
    CGRect frame = self.view.frame;
    
    NSUInteger index = TPIndexFromView(scrollView);
    CGFloat contentOffsetY = scrollView.contentOffset.y;
    CGFloat pageContentMinimumTopInset = [self pageContentMinimumTopInsetAtIndex:index];
    CGFloat pageContentMaximumTopInset = [self pageContentMaximumTopInsetAtIndex:index];
    
    CGFloat tabBarMinimumMinY = pageContentMinimumTopInset - self.tabBarHeight;
    CGFloat tabBarMaximumMinY = pageContentMaximumTopInset - self.tabBarHeight;
    CGFloat tabBarMinY = -contentOffsetY - self.tabBarHeight;
    
    CGFloat fixedTarBarMinY = MIN(MAX(tabBarMinY, tabBarMinimumMinY), tabBarMaximumMinY);
    CGFloat headerViewHeight = fixedTarBarMinY;
    
    self.tabBar.frame = CGRectMake(CGRectGetMinX(frame), fixedTarBarMinY, CGRectGetWidth(frame), self.tabBarHeight);
    self.headerView.frame = CGRectMake(CGRectGetMinX(frame), CGRectGetMinY(frame), CGRectGetWidth(frame), headerViewHeight);
}

#pragma mark - TPPageViewControllerDataSource

- (nullable UIViewController *)pageViewController:(nonnull TPPageViewController *)pageViewController viewControllerBeforeViewController:(UIViewController *)viewController {
    NSUInteger index = [self indexForViewController:viewController];
    if (index >= 1 && index < self.numberOfViewControllers) {
        NSUInteger beforeIndex = index - 1;
        return [self viewControllerAtIndex:beforeIndex];
    }
    
    return nil;
}

- (nullable UIViewController *)pageViewController:(nonnull TPPageViewController *)pageViewController viewControllerAfterViewController:(UIViewController *)viewController {
    NSUInteger index = [self indexForViewController:viewController];
    if (index >= 0 && index < self.numberOfViewControllers) {
        NSUInteger afterIndex = index + 1;
        if (afterIndex < self.numberOfViewControllers) {
            return [self viewControllerAtIndex:afterIndex];
        }
    }
    
    return nil;
}

#pragma mark - TPPageViewControllerDelegate

- (void)pageViewController:(nonnull TPPageViewController *)pageViewController willStartScrollingFromViewController:(nonnull UIViewController *)startingViewController destinationViewController:(nonnull UIViewController *)destinationViewController {
    [self configureContentScrollViewWithViewController:destinationViewController];
    
    if ([self.delegate respondsToSelector:@selector(pageViewController:willStartScrollingFromViewController:destinationViewController:)]) {
        [self.delegate pageViewController:self
     willStartScrollingFromViewController:startingViewController
                destinationViewController:destinationViewController];
    }
}

- (void)pageViewController:(nonnull TPPageViewController *)pageViewController isScrollingFromViewController:(nonnull UIViewController *)startingViewController destinationViewController:(nonnull UIViewController *)destinationViewController progress:(CGFloat)progress {
    if ([self.delegate respondsToSelector:@selector(pageViewController:isScrollingFromViewController:destinationViewController:progress:)]) {
        [self.delegate pageViewController:self
            isScrollingFromViewController:startingViewController
                destinationViewController:destinationViewController
                                 progress:progress];
    }
}

- (void)pageViewController:(nonnull TPPageViewController *)pageViewController didFinishScrollingFromViewController:(nonnull UIViewController *)startingViewController destinationViewController:(nonnull UIViewController *)destinationViewController transitionCompleted:(BOOL)completed {
    if ([self.delegate respondsToSelector:@selector(pageViewController:didFinishScrollingFromViewController:destinationViewController:transitionCompleted:)]) {
        [self.delegate pageViewController:self
     didFinishScrollingFromViewController:startingViewController
                destinationViewController:destinationViewController
                      transitionCompleted:completed];
    }
}

#pragma mark - Accessors

- (void)setSelectedIndex:(NSUInteger)selectedIndex {
    [self setSelectedIndex:selectedIndex animated:NO];
}

- (NSUInteger)selectedIndex {
    return self.selectedViewController.tp_pageIndex.unsignedIntegerValue;
}

- (UIViewController *)selectedViewController {
    return self.pageViewController.selectedViewController;
}

@end
