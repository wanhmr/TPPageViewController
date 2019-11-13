//
//  TPTabPageViewController.m
//  TPPageViewController_Example
//
//  Created by Tpphha on 2018/11/21.
//  Copyright © 2018 tpx. All rights reserved.
//

#import "TPTabPageViewController.h"
#import <objc/runtime.h>
#import "TPPageViewController.h"

static NSNumber* TPKeyFromIndex(NSUInteger index) {
    return @(index);
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

- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
    self.tabBar.frame = self.tabBarRect;
    self.pageViewController.view.frame = self.pageContentRect;
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
    
    if (self.tabBar.superview) {
        [self.tabBar removeFromSuperview];
    }
    self.tabBar = nil;
    if ([self.dataSources respondsToSelector:@selector(tabBarInPageViewController:)]) {
        self.tabBar = [self.dataSources tabBarInPageViewController:self];
        [self.view addSubview:self.tabBar];
    }
    
    [self.pageViewController selectViewController:[self viewControllerAtIndex:self.selectedIndex]
                                        direction:TPPageViewControllerNavigationDirectionForward
                                         animated:NO
                                       completion:nil];
}

#pragma mark - Utils

- (UIViewController *)viewControllerAtIndex:(NSUInteger)index {
    NSParameterAssert(index < self.numberOfViewControllers);
    
    NSNumber *key = TPKeyFromIndex(index);
    UIViewController *viewController = [self.viewControllerCache objectForKey:key];
    if (!viewController) {
        viewController = [self.dataSources pageViewController:self viewControllerAtIndex:index];
        viewController.tp_pageIndex = key;
        [self.viewControllerCache setObject:viewController forKey:key];
    }
    
    return viewController;
}

- (NSUInteger)indexForViewController:(UIViewController *)viewController {
    return viewController.tp_pageIndex.unsignedIntegerValue;
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

- (CGFloat)tabBarHeight {
    if ([self.delegate respondsToSelector:@selector(heightForTabBarInPageViewController:)]) {
        return [self.delegate heightForTabBarInPageViewController:self];
    }
    return 0;
}

- (CGRect)tabBarRect {
    return CGRectMake(0,
                      0,
                      CGRectGetWidth(self.view.frame),
                      self.tabBarHeight);
}

- (CGRect)pageContentRect {
    return CGRectMake(0,
                      CGRectGetMaxY(self.tabBarRect),
                      CGRectGetWidth(self.view.frame),
                      CGRectGetHeight(self.view.frame) -
                      CGRectGetMaxY(self.tabBarRect));
}

@end
