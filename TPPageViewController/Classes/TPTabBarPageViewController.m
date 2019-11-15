//
//  TPTabBarPageViewController.m
//  TPPageViewController_Example
//
//  Created by Tpphha on 2018/11/21.
//  Copyright © 2018 tpx. All rights reserved.
//

#import "TPTabBarPageViewController.h"
#import <objc/runtime.h>
#import "TPPageViewController.h"

@implementation UIViewController (TPTabBarPageViewController)

- (NSNumber *)tp_pageIndex {
    return objc_getAssociatedObject(self, _cmd);
}

- (void)tp_setPageIndex:(NSNumber *)pageIndex {
    objc_setAssociatedObject(self, @selector(tp_pageIndex), pageIndex, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

@end

@interface TPTabBarPageViewModel : NSObject <
    TPPageViewControllerDataSource,
    TPPageViewControllerDelegate
>

@property (nonatomic, weak, readonly) TPTabBarPageViewController *tabPageViewController;

- (instancetype)initWithTabPageViewController:(TPTabBarPageViewController *)tabPageViewController;

@end

@interface TPTabBarPageViewController ()

@property (nonatomic, strong) TPPageViewController *pageViewController;
@property (nonatomic, assign) NSUInteger numberOfViewControllers;
@property (nonatomic, strong) NSCache<NSNumber *, UIViewController *> *viewControllerCache;

@property (nonatomic, strong) UIView *tabBar;

@property (nonatomic, strong) TPTabBarPageViewModel *tabBarPageViewModel;

@end

@implementation TPTabBarPageViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    if (@available(iOS 11, *)) {} else {
        self.automaticallyAdjustsScrollViewInsets = NO;
    }
    
    self.tabBarPageViewModel = [[TPTabBarPageViewModel alloc] initWithTabPageViewController:self];
    
    TPPageViewController *pageViewController = [[TPPageViewController alloc] initWithNavigationOrientation:TPPageViewControllerNavigationOrientationHorizontal];
    pageViewController.delegate = self.tabBarPageViewModel;
    pageViewController.dataSource = self.tabBarPageViewModel;
    [self addChildViewController:pageViewController];
    [self.view addSubview:pageViewController.view];
    [pageViewController didMoveToParentViewController:self];
    self.pageViewController = pageViewController;
    
    self.viewControllerCache = [NSCache new];
    
    [self reloadDataWithSelectedIndex:self.defaultSelectedIndex];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    self.tabBar.frame = self.tabBarRect;
    self.pageViewController.view.frame = self.pageContentRect;
}

- (void)setSelectedIndex:(NSUInteger)selectedIndex animated:(BOOL)animated {
    if (selectedIndex >= self.numberOfViewControllers) {
        NSAssert(NO, @"The selectedIndex is invalid.");
        return;
    }
    
    NSUInteger currentSelectedIndex = self.selectedIndex;
    if (self.selectedViewController && selectedIndex == currentSelectedIndex) {
        return;
    }
    
    TPPageViewControllerNavigationDirection direction = TPPageViewControllerNavigationDirectionForward;
    if (selectedIndex < currentSelectedIndex) {
        direction = TPPageViewControllerNavigationDirectionReverse;
    }
    
    [self.pageViewController selectViewController:[self viewControllerAtIndex:selectedIndex]
                                        direction:direction
                                         animated:animated
                                       completion:nil];
}

- (void)reloadDataWithSelectedIndex:(NSUInteger)selectedIndex {
    [self.viewControllerCache removeAllObjects];
    
    self.numberOfViewControllers = [self.dataSource numberOfViewControllersInPageViewController:self];
    
    if (self.tabBar.superview) {
        [self.tabBar removeFromSuperview];
    }
    self.tabBar = nil;
    if ([self.dataSource respondsToSelector:@selector(tabBarInPageViewController:)]) {
        self.tabBar = [self.dataSource tabBarInPageViewController:self];
        [self.view addSubview:self.tabBar];
    }
    
    [self setSelectedIndex:selectedIndex animated:NO];
}

- (void)reloadData {
    [self reloadDataWithSelectedIndex:self.selectedIndex];
}

- (UIViewController *)viewControllerAtIndex:(NSUInteger)index {
    NSParameterAssert(index < self.numberOfViewControllers);
    
    NSNumber *indexNumber = @(index);
    UIViewController *viewController = [self.viewControllerCache objectForKey:indexNumber];
    if (!viewController) {
        viewController = [self.dataSource pageViewController:self viewControllerAtIndex:index];
        [viewController tp_setPageIndex:indexNumber];
        [self.viewControllerCache setObject:viewController forKey:indexNumber];
    }
    
    return viewController;
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

@implementation TPTabBarPageViewModel

- (instancetype)initWithTabPageViewController:(TPTabBarPageViewController *)tabPageViewController {
    self = [super init];
    if (self) {
        _tabPageViewController = tabPageViewController;
    }
    return self;
}

#pragma mark - TPPageViewControllerDataSource

- (nullable UIViewController *)pageViewController:(nonnull TPPageViewController *)pageViewController viewControllerBeforeViewController:(UIViewController *)viewController {
    NSUInteger index = viewController.tp_pageIndex.unsignedIntegerValue;
    if (index >= 1 && index < self.tabPageViewController.numberOfViewControllers) {
        NSUInteger beforeIndex = index - 1;
        return [self.tabPageViewController viewControllerAtIndex:beforeIndex];
    }
    
    return nil;
}

- (nullable UIViewController *)pageViewController:(nonnull TPPageViewController *)pageViewController viewControllerAfterViewController:(UIViewController *)viewController {
    NSUInteger index = viewController.tp_pageIndex.unsignedIntegerValue;
    if (index >= 0 && index < self.tabPageViewController.numberOfViewControllers) {
        NSUInteger afterIndex = index + 1;
        if (afterIndex < self.tabPageViewController.numberOfViewControllers) {
            return [self.tabPageViewController viewControllerAtIndex:afterIndex];
        }
    }
    
    return nil;
}

#pragma mark - TPPageViewControllerDelegate

- (void)pageViewController:(nonnull TPPageViewController *)pageViewController willStartScrollingFromViewController:(nonnull UIViewController *)startingViewController destinationViewController:(nonnull UIViewController *)destinationViewController {
    if ([self.tabPageViewController.delegate respondsToSelector:@selector(pageViewController:willStartScrollingFromViewController:destinationViewController:)]) {
        [self.tabPageViewController.delegate pageViewController:self.tabPageViewController
                           willStartScrollingFromViewController:startingViewController
                                      destinationViewController:destinationViewController];
    }
}

- (void)pageViewController:(nonnull TPPageViewController *)pageViewController isScrollingFromViewController:(nonnull UIViewController *)startingViewController destinationViewController:(nonnull UIViewController *)destinationViewController progress:(CGFloat)progress {
    if ([self.tabPageViewController.delegate respondsToSelector:@selector(pageViewController:isScrollingFromViewController:destinationViewController:progress:)]) {
        [self.tabPageViewController.delegate pageViewController:self.tabPageViewController
                                  isScrollingFromViewController:startingViewController
                                      destinationViewController:destinationViewController
                                                       progress:progress];
    }
}

- (void)pageViewController:(nonnull TPPageViewController *)pageViewController didFinishScrollingFromViewController:(nonnull UIViewController *)startingViewController destinationViewController:(nonnull UIViewController *)destinationViewController transitionCompleted:(BOOL)completed {
    if ([self.tabPageViewController.delegate respondsToSelector:@selector(pageViewController:didFinishScrollingFromViewController:destinationViewController:transitionCompleted:)]) {
        [self.tabPageViewController.delegate pageViewController:self.tabPageViewController
                           didFinishScrollingFromViewController:startingViewController
                                      destinationViewController:destinationViewController
                                            transitionCompleted:completed];
    }
}

@end
