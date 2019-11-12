//
//  GreetingViewController.m
//  Greetings-ObjC
//
//  Created by Erik Malyak on 9/20/16.
//  Copyright © 2016 Erik Malyak. All rights reserved.
//

#import "GreetingViewController.h"
#import "TPInfiniteViewController.h"
#import "TPTabPageViewController.h"
#import "TPViewController.h"

@interface GreetingViewController () <TPTabPageViewControllerDataSource, TPTabPageViewControllerDelegate>

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
    TPTabPageViewController *pageViewController = [TPTabPageViewController new];
    pageViewController.dataSources = self;
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
//    GreetingViewController *viewController = [self.storyboard instantiateViewControllerWithIdentifier:@"GreetingViewController"];
//    viewController.greeting = self.greetings[index];
//    viewController.color = self.greetingColors[index];
    UIViewController *viewController = [TPViewController new];
    return viewController;
}

- (UIView *)tabBarInPageViewController:(TPTabPageViewController *)pageViewController {
    UIView *tabBar = [UIView new];
    tabBar.backgroundColor = [UIColor redColor];
    return tabBar;
}

- (UIView *)headerViewInPageViewController:(TPTabPageViewController *)pageViewController {
    UIView *headerView = [UIView new];
    headerView.backgroundColor = [UIColor yellowColor];
    return headerView;
}

- (CGFloat)pageViewController:(TPTabPageViewController *)pageViewController heightForTabBar:(__kindof UIView *)tabBar {
    return 40;
}

- (CGFloat)pageViewController:(TPTabPageViewController *)pageViewController minimumHeightForHeaderView:(__kindof UIView *)headerView {
    return 64;
}

- (CGFloat)pageViewController:(TPTabPageViewController *)pageViewController maximumHeightForHeaderView:(__kindof UIView *)headerView {
    return 120;
}

@end
