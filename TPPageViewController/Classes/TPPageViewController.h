//
//  TPPageViewController.h
//  Pods-TPPageViewController_Example
//
//  Created by Tpphha on 2018/7/3.
//

#import <UIKit/UIKit.h>
@protocol TPPageViewControllerDataSource, TPPageViewControllerDelegate;

typedef NS_ENUM(NSInteger, TPPageViewControllerNavigationDirection) {
    TPPageViewControllerNavigationDirectionNone,
    /// Forward direction. Can be right in a horizontal orientation or down in a vertical orientation.
    TPPageViewControllerNavigationDirectionForward,
    /// Reverse direction. Can be left in a horizontal orientation or up in a vertical orientation.
    TPPageViewControllerNavigationDirectionReverse
};

typedef NS_ENUM(NSInteger, TPPageViewControllerNavigationOrientation) {
    /// Horiziontal orientation. Scrolls left and right.
    TPPageViewControllerNavigationOrientationHorizontal,
    /// Vertical orientation. Scrolls up and down.
    TPPageViewControllerNavigationOrientationVertical
};

typedef void(^TPPageViewControllerTransitionCompletionHandler)(BOOL transitionCompleted);

NS_ASSUME_NONNULL_BEGIN

@interface TPPageViewController : UIViewController

@property (nonatomic, weak) id<TPPageViewControllerDataSource> dataSource;
@property (nonatomic, weak) id<TPPageViewControllerDelegate> delegate;

@property (nonatomic, assign, readonly) TPPageViewControllerNavigationOrientation navigationOrientation;
@property (nonatomic, assign, readonly, getter=isScrolling) BOOL scrolling;
@property (nullable, nonatomic, strong, readonly) __kindof UIViewController *selectedViewController;

- (instancetype)initWithNavigationOrientation:(TPPageViewControllerNavigationOrientation)navigationOrientation;

- (void)selectViewController:(UIViewController *)viewController
                   direction:(TPPageViewControllerNavigationDirection)direction
                    animated:(BOOL)animated
                  completion:(nullable TPPageViewControllerTransitionCompletionHandler)completion;

- (void)scrollForwardWithAnimated:(BOOL)animated completion:(nullable TPPageViewControllerTransitionCompletionHandler)completion;

- (void)scrollReverseWithAnimated:(BOOL)animated completion:(nullable TPPageViewControllerTransitionCompletionHandler)completion;

@end


/**
 The `TPPageViewControllerDataSource` protocol is adopted to provide the view controllers that are displayed when the user scrolls through pages. Methods are called on an as-needed basis.
 
 Each method returns a `UIViewController` object or `nil` if there are no view controllers to be displayed.
 
 - note: If the data source is `nil`, gesture based scrolling will be disabled and all view controllers must be provided through `selectViewController:direction:animated:completion:`.
 */
@protocol TPPageViewControllerDataSource <NSObject>

/**
 Called to optionally return a view controller that is to the left of a given view controller in a horizontal orientation, or above a given view controller in a vertical orientation.
 
 - parameter pageViewController: The page view controller
 - parameter viewController: The point of reference view controller
 
 - returns: The view controller that is to the left of the given `viewController` in a horizontal orientation, or above the given `viewController` in a vertical orientation, or `nil` if there is no view controller to be displayed.
 */
- (nullable __kindof UIViewController *)pageViewController:(TPPageViewController *)pageViewController viewControllerBeforeViewController:(__kindof UIViewController *)viewController;


/**
 Called to optionally return a view controller that is to the right of a given view controller.
 
 - parameter pageViewController: The page view controller
 - parameter viewController: The point of reference view controller
 
 - returns: The view controller that is to the right of the given `viewController` in a horizontal orientation, or below the given `viewController` in a vertical orientation, or `nil` if there is no view controller to be displayed.
 */
- (nullable __kindof UIViewController *)pageViewController:(TPPageViewController *)pageViewController viewControllerAfterViewController:(__kindof UIViewController *)viewController;

@end


/**
 The TPPageViewControllerDelegate protocol is adopted to receive messages for all important events of the page transition process.
 */
@protocol TPPageViewControllerDelegate <NSObject>

/**
 Called before scrolling to a new view controller.
 
 - note: This method will not be called if the starting view controller is `nil`. A common scenario where this will occur is when you initialize the page view controller and use `selectViewController:direction:animated:completion:` to load the first selected view controller.
 
 - important: If bouncing is enabled, it is possible this method will be called more than once for one page transition. It can be called before the initial scroll to the destination view controller (which is when it is usually called), and it can also be called when the scroll momentum carries over slightly to the view controller after the original destination view controller.
 
 - parameter pageViewController: The page view controller
 - parameter startingViewController: The currently selected view controller the transition is starting from
 - parameter destinationViewController: The view controller that will be scrolled to, where the transition should end
 */
- (void)pageViewController:(TPPageViewController *)pageViewController willStartScrollingFromViewController:(__kindof UIViewController *)startingViewController destinationViewController:(__kindof UIViewController *)destinationViewController;

/**
 Called whenever there has been a scroll position change in a page transition. This method is very useful if you need to know the exact progress of the page transition animation.
 
 - note: This method will not be called if the starting view controller is `nil`. A common scenario where this will occur is when you initialize the page view controller and use `selectViewController:direction:animated:completion:` to load the first selected view controller.
 
 - parameter pageViewController: The page view controller
 - parameter startingViewController: The currently selected view controller the transition is starting from
 - parameter destinationViewController: The view controller being scrolled to where the transition should end
 - parameter progress: The progress of the transition, where 0 is a neutral scroll position, >= 1 is a complete transition to the right view controller in a horizontal orientation, or the below view controller in a vertical orientation, and <= -1 is a complete transition to the left view controller in a horizontal orientation, or the above view controller in a vertical orientation. Values may be greater than 1 or less than -1 if bouncing is enabled and the scroll velocity is quick enough.
 */
- (void)pageViewController:(TPPageViewController *)pageViewController isScrollingFromViewController:(__kindof UIViewController *)startingViewController destinationViewController:(__kindof UIViewController *)destinationViewController progress:(CGFloat)progress;

/**
 Called after a page transition attempt has completed.
 
 - important: If bouncing is enabled, it is possible this method will be called more than once for one page transition. It can be called after the scroll transition to the intended destination view controller (which is when it is usually called), and it can also be called when the scroll momentum carries over slightly to the view controller after the intended destination view controller. In the latter scenario, `transitionCompleted` will return `false` the second time it's called because the scroll view will bounce back to the intended destination view controller.
 
 - parameter pageViewController: The page view controller
 - parameter startingViewController: The currently selected view controller the transition is starting from
 - parameter destinationViewController: The view controller that has been attempted to be selected
 - parameter transitionSuccessful: A Boolean whether the transition to the destination view controller was successful or not. If `true`, the new selected view controller is `destinationViewController`. If `false`, the transition returned to the view controller it started from, so the selected view controller is still `startingViewController`.
 */
- (void)pageViewController:(TPPageViewController *)pageViewController didFinishScrollingFromViewController:(__kindof UIViewController *)startingViewController destinationViewController:(__kindof UIViewController *)destinationViewController transitionCompleted:(BOOL)completed;

@end

NS_ASSUME_NONNULL_END
