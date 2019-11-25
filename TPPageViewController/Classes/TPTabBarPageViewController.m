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

static NSString *TPKeyFromIndex(NSUInteger index) {
    return @(index).stringValue;
}

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

@property (nonatomic, weak, readonly) TPTabBarPageViewController *tabBarPageViewController;

- (instancetype)initWithTabBarPageViewController:(TPTabBarPageViewController *)tabBarPageViewController;

@end

@interface TPTabBarPageViewController ()

@property (nonatomic, strong) TPPageViewController *pageViewController;
@property (nonatomic, assign) NSUInteger numberOfViewControllers;
@property (nonatomic, strong) NSCache<NSString *, UIViewController *> *viewControllerCache;
@property (nonatomic, strong) NSMutableDictionary<NSString *, NSString *> *viewControllerIdentifiers;

@property (nonatomic, strong) UIView *tabBar;

@property (nonatomic, strong) TPTabBarPageViewModel *tabBarPageViewModel;

@end

@implementation TPTabBarPageViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    if (@available(iOS 11, *)) {} else {
        self.automaticallyAdjustsScrollViewInsets = NO;
    }
    
    self.tabBarPageViewModel = [[TPTabBarPageViewModel alloc] initWithTabBarPageViewController:self];
    
    TPPageViewController *pageViewController = [[TPPageViewController alloc] initWithNavigationOrientation:TPPageViewControllerNavigationOrientationHorizontal];
    pageViewController.delegate = self.tabBarPageViewModel;
    pageViewController.dataSource = self.tabBarPageViewModel;
    [self addChildViewController:pageViewController];
    [self.view addSubview:pageViewController.view];
    [pageViewController didMoveToParentViewController:self];
    self.pageViewController = pageViewController;
    
    self.viewControllerCache = [NSCache new];
    self.viewControllerIdentifiers = [NSMutableDictionary new];
    
    NSUInteger defaultSelectedIndex = 0;
    if (self.defaultSelectedPageIndex) {
        defaultSelectedIndex = self.defaultSelectedPageIndex.unsignedIntegerValue;
    }
    [self reloadDataWithSelectedIndex:defaultSelectedIndex];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    self.tabBar.frame = self.tabBarRect;
    self.pageViewController.view.frame = self.pageContentRect;
}

- (void)selectPageAtIndex:(NSUInteger)index animated:(BOOL)animated {
    if (index >= self.numberOfViewControllers) {
        NSAssert(NO, @"The selectedIndex is invalid.");
        return;
    }
    
    NSUInteger currentSelectedIndex = self.selectedPageIndex.unsignedIntegerValue;
    if (self.selectedPageIndex && index == currentSelectedIndex) {
        return;
    }

    TPPageViewControllerNavigationDirection direction = TPPageViewControllerNavigationDirectionForward;
    if (index < currentSelectedIndex) {
        direction = TPPageViewControllerNavigationDirectionReverse;
    }

    [self.pageViewController selectViewController:[self viewControllerAtIndex:index]
                                        direction:direction
                                         animated:animated
                                       completion:nil];
}

- (void)reloadDataWithSelectedIndex:(NSUInteger)selectedIndex shouldMatchIdentifier:(BOOL)shouldMatchIdentifier {
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
    
    NSDictionary *viewControllerIdentifiers = self.viewControllerIdentifiers.copy;
    [self.viewControllerIdentifiers removeAllObjects];
    
    if ([self.dataSource respondsToSelector:@selector(pageViewController:identifierForViewControllerAtIndex:)]) {
        for (NSUInteger i = 0; i < self.numberOfViewControllers; i++) {
            self.viewControllerIdentifiers[TPKeyFromIndex(i)] = [self.dataSource pageViewController:self identifierForViewControllerAtIndex:i];
        }
        
        if (shouldMatchIdentifier) {
            NSNumber *currentSelectedPageIndex = self.selectedPageIndex;
               if (currentSelectedPageIndex) {
                   NSUInteger beforeIndex = currentSelectedPageIndex.unsignedIntegerValue;
                   NSString *beforeIdentifier = viewControllerIdentifiers[TPKeyFromIndex(beforeIndex)];
                   NSString *afterIdentifier = self.viewControllerIdentifiers[TPKeyFromIndex(selectedIndex)];
                   if (afterIdentifier && [afterIdentifier isEqualToString:beforeIdentifier]) {
                       [self.selectedViewController tp_setPageIndex:@(selectedIndex)];
                       [self.viewControllerCache setObject:self.selectedViewController forKey:TPKeyFromIndex(selectedIndex)];
                       
                       if ([self.delegate respondsToSelector:@selector(pageViewController:didMatchIdentifier:beforeIndex:afterIndex:)]) {
                           [self.delegate pageViewController:self didMatchIdentifier:afterIdentifier beforeIndex:beforeIndex afterIndex:selectedIndex];
                       }
                   }
               }
           }
    }
    
    if (self.numberOfViewControllers > 0) {
        [self selectPageAtIndex:selectedIndex animated:NO];
    }
}

- (void)reloadDataWithSelectedIndex:(NSUInteger)selectedIndex {
    [self reloadDataWithSelectedIndex:selectedIndex shouldMatchIdentifier:YES];
}

- (void)reloadData {
    [self reloadDataWithSelectedIndex:self.selectedPageIndex.unsignedIntegerValue];
}

- (UIViewController *)viewControllerAtIndex:(NSUInteger)index {
    NSParameterAssert(index < self.numberOfViewControllers);
    
    NSString *key = TPKeyFromIndex(index);
    UIViewController *viewController = [self.viewControllerCache objectForKey:key];
    if (!viewController) {
        viewController = [self.dataSource pageViewController:self viewControllerAtIndex:index];
        [viewController tp_setPageIndex:@(index)];
        [self.viewControllerCache setObject:viewController forKey:key];
    }
    
    return viewController;
}

#pragma mark - Accessors

- (NSNumber *)selectedPageIndex {
    return self.selectedViewController.tp_pageIndex;
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

- (instancetype)initWithTabBarPageViewController:(TPTabBarPageViewController *)tabBarPageViewController {
    self = [super init];
    if (self) {
        _tabBarPageViewController = tabBarPageViewController;
    }
    return self;
}

#pragma mark - TPPageViewControllerDataSource

- (nullable UIViewController *)pageViewController:(nonnull TPPageViewController *)pageViewController viewControllerBeforeViewController:(UIViewController *)viewController {
    NSUInteger index = viewController.tp_pageIndex.unsignedIntegerValue;
    if (index >= 1 && index < self.tabBarPageViewController.numberOfViewControllers) {
        NSUInteger beforeIndex = index - 1;
        return [self.tabBarPageViewController viewControllerAtIndex:beforeIndex];
    }
    
    return nil;
}

- (nullable UIViewController *)pageViewController:(nonnull TPPageViewController *)pageViewController viewControllerAfterViewController:(UIViewController *)viewController {
    NSUInteger index = viewController.tp_pageIndex.unsignedIntegerValue;
    if (index >= 0 && index < self.tabBarPageViewController.numberOfViewControllers) {
        NSUInteger afterIndex = index + 1;
        if (afterIndex < self.tabBarPageViewController.numberOfViewControllers) {
            return [self.tabBarPageViewController viewControllerAtIndex:afterIndex];
        }
    }
    
    return nil;
}

#pragma mark - TPPageViewControllerDelegate

- (void)pageViewController:(nonnull TPPageViewController *)pageViewController willStartScrollingFromViewController:(nonnull UIViewController *)startingViewController destinationViewController:(nonnull UIViewController *)destinationViewController {
    if ([self.tabBarPageViewController.delegate respondsToSelector:@selector(pageViewController:willStartScrollingFromViewController:destinationViewController:)]) {
        [self.tabBarPageViewController.delegate pageViewController:self.tabBarPageViewController
                           willStartScrollingFromViewController:startingViewController
                                      destinationViewController:destinationViewController];
    }
}

- (void)pageViewController:(nonnull TPPageViewController *)pageViewController isScrollingFromViewController:(nonnull UIViewController *)startingViewController destinationViewController:(nonnull UIViewController *)destinationViewController progress:(CGFloat)progress {
    if ([self.tabBarPageViewController.delegate respondsToSelector:@selector(pageViewController:isScrollingFromViewController:destinationViewController:progress:)]) {
        [self.tabBarPageViewController.delegate pageViewController:self.tabBarPageViewController
                                  isScrollingFromViewController:startingViewController
                                      destinationViewController:destinationViewController
                                                       progress:progress];
    }
}

- (void)pageViewController:(nonnull TPPageViewController *)pageViewController didFinishScrollingFromViewController:(nonnull UIViewController *)startingViewController destinationViewController:(nonnull UIViewController *)destinationViewController transitionCompleted:(BOOL)completed {
    if ([self.tabBarPageViewController.delegate respondsToSelector:@selector(pageViewController:didFinishScrollingFromViewController:destinationViewController:transitionCompleted:)]) {
        [self.tabBarPageViewController.delegate pageViewController:self.tabBarPageViewController
                           didFinishScrollingFromViewController:startingViewController
                                      destinationViewController:destinationViewController
                                            transitionCompleted:completed];
    }
}

@end
