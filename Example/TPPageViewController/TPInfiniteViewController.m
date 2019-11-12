//
//  TPInfiniteViewController.m
//  TPPageViewController_Example
//
//  Created by Tpphha on 2018/7/4.
//  Copyright © 2018年 tpx. All rights reserved.
//

#import "TPInfiniteViewController.h"
#import <TPPageViewController/TPPageViewController.h>
#import "TPViewController.h"

@interface TPInfiniteViewController () <TPPageViewControllerDataSource>

@property (nonatomic, strong) TPPageViewController *pageViewController;
@property (nonatomic, strong) NSNumberFormatter *numberFormatter;

@end

@implementation TPInfiniteViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    self.numberFormatter = [[NSNumberFormatter alloc] init];
    self.numberFormatter.numberStyle = NSNumberFormatterDecimalStyle;
    
    // Do any additional setup after loading the view.
    // Instantiate EMPageViewController and set the data source and delegate to 'self'
    TPPageViewController *pageViewController = [[TPPageViewController alloc] init];
    
    // Or, for a vertical orientation
//    TPPageViewController *pageViewController = [[TPPageViewController alloc] initWithNavigationOrientation:TPPageViewControllerNavigationOrientationVertical];
    
    pageViewController.dataSource = self;
    
    // Set the initially selected view controller
    // IMPORTANT: If you are using a dataSource, make sure you set it BEFORE calling selectViewController:direction:animated:completion
    TPViewController *currentViewController = [self viewControllerAtIndex:100000000];
    [pageViewController selectViewController:currentViewController
                                   direction:TPPageViewControllerNavigationDirectionForward
                                    animated:NO
                                  completion:nil];
    
    // Add EMPageViewController to the root view controller
    [self addChildViewController:pageViewController];
    [self.view insertSubview:pageViewController.view atIndex:0]; // Insert the page controller view below the navigation buttons
    [pageViewController didMoveToParentViewController:self];
    
    self.pageViewController = pageViewController;
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    self.pageViewController.view.frame = self.view.bounds;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}

- (TPViewController * _Nullable)viewControllerAtIndex:(NSUInteger)index {
    TPViewController *viewController = [[UIStoryboard storyboardWithName:@"Main" bundle:nil] instantiateViewControllerWithIdentifier:@"TPViewController"];
    viewController.greeting = @(index).stringValue;
    return viewController;
}

#pragma mark - TPPageViewControllerDataSource

- (UIViewController *)pageViewController:(TPPageViewController *)pageViewController viewControllerAfterViewController:(TPViewController *)viewController {
    NSNumber *myNumber = [self.numberFormatter numberFromString:viewController.greeting];
    NSUInteger index = myNumber.unsignedIntegerValue;
    return [self viewControllerAtIndex:index + 1];
}

- (UIViewController *)pageViewController:(TPViewController *)pageViewController viewControllerBeforeViewController:(nonnull TPViewController *)viewController {
    NSNumber *myNumber = [self.numberFormatter numberFromString:viewController.greeting];
    NSUInteger index = myNumber.unsignedIntegerValue;
    return [self viewControllerAtIndex:index - 1];
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
