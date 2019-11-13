//
//  GreetingViewController.m
//  Greetings-ObjC
//
//  Created by Erik Malyak on 9/20/16.
//  Copyright © 2016 Erik Malyak. All rights reserved.
//

#import "GreetingViewController.h"
#import "TPInfiniteViewController.h"
#import "TPMagicTabPageViewController.h"
#import "TPViewController.h"

@interface PageViewController : TPTabPageViewController

@property (nonatomic, assign) BOOL flag;

@end

@implementation PageViewController


@end

@interface GreetingViewController () <TPMagicTabPageViewControllerDataSource, TPMagicTabPageViewControllerDelegate>

@property (strong, nonatomic, nonnull) NSArray<NSString *> *greetings;
@property (strong, nonatomic, nonnull) NSArray<UIColor *> *greetingColors;

@end

@implementation GreetingViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    NSLog(@"viewDidLoad: %@", self.greeting);
    
    self.view.backgroundColor = self.color;
    self.label.text = self.greeting;
    
    UITapGestureRecognizer *tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapAction)];
    [self.view addGestureRecognizer:tapGestureRecognizer];
    
    [self setupGreetings];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    NSLog(@"viewWillAppear: %@", self.greeting);
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    NSLog(@"viewDidAppear: %@", self.greeting);
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    NSLog(@"viewWillDisappear: %@", self.greeting);
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    
    NSLog(@"viewDidDisappear: %@", self.greeting);
}

- (void)dealloc {
    NSLog(@"dealloc: %@", self.greeting);
}

- (void)tapAction {
    TPMagicTabPageViewController *pageViewController = [TPMagicTabPageViewController new];
    pageViewController.dataSource = self;
    pageViewController.delegate = self;
    pageViewController.modalPresentationStyle = UIModalPresentationFullScreen;
    [self presentViewController:pageViewController animated:YES completion:nil];
}

- (void)setupGreetings {
    self.greetings = @[@"Hello!", @"¡Hola!", @"Salut!", @"Hallo!", @"Ciao!"];
    self.greetingColors = @[
                            [UIColor colorWithRed:108.0/255.0 green:122.0/255.0 blue:137.0/255.0 alpha:1.0],
                            [UIColor colorWithRed:135.0/255.0 green:211.0/255.0 blue:124.0/255.0 alpha:1.0],
                            [UIColor colorWithRed:34.0/255.0 green:167.0/255.0 blue:240.0/255.0 alpha:1.0],
                            [UIColor colorWithRed:245.0/255.0 green:171.0/255.0 blue:53.0/255.0 alpha:1.0],
                            [UIColor colorWithRed:214.0/255.0 green:69.0/255.0 blue:65.0/255.0 alpha:1.0]
                            ];
}

#pragma mark - TPStickyPageViewControllerDataSource

- (NSUInteger)numberOfViewControllersInPageViewController:(TPTabPageViewController *)pageViewController {
    return self.greetings.count;
}

- (UIViewController *)pageViewController:(TPTabPageViewController *)pageViewController viewControllerAtIndex:(NSUInteger)index {
    if ([pageViewController isKindOfClass:PageViewController.class]) {
        TPViewController *viewController = [TPViewController new];
        viewController.greeting = self.greetings[index];
        viewController.color = self.greetingColors[index];
        return viewController;
    }
    
    PageViewController *viewController = [PageViewController new];
    viewController.delegate = self;
    viewController.dataSources = self;
    return viewController;
}

- (UIView *)tabBarInPageViewController:(TPTabPageViewController *)pageViewController {
    UIView *tabBar = [UIView new];
    if ([pageViewController isKindOfClass:PageViewController.class]) {
        tabBar.backgroundColor = [UIColor redColor];
    } else {
        tabBar.backgroundColor = [UIColor blueColor];
    }
    return tabBar;
}

- (CGFloat)heightForTabBarInPageViewController:(TPTabPageViewController *)pageViewController {
    return 40;
}

- (UIView *)headerViewInPageViewController:(TPTabPageViewController *)pageViewController {
    UIView *headerView = [UIView new];
    headerView.backgroundColor = [UIColor yellowColor];
    return headerView;
}

- (CGFloat)minimumHeightForHeaderViewInPageViewController:(TPTabPageViewController *)pageViewController {
    return 0;
}

- (CGFloat)maximumHeightForHeaderViewInPageViewController:(TPTabPageViewController *)pageViewController {
    return 80;
}

@end
