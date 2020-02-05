
#import "LaunchViewController.h"

#import "MEGASdkManager.h"

#import "UIColor+MNZCategory.h"

@interface LaunchViewController () <MEGARequestDelegate>

@property (nonatomic) NSTimer *timerAPI_EAGAIN;

@end

@implementation LaunchViewController

#pragma mark - Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.circularShapeLayer = [CAShapeLayer layer];
    self.circularShapeLayer.bounds = self.logoImageView.bounds;
    CGFloat radiusLogoImageView = self.logoImageView.bounds.size.width/2.0f;
    self.circularShapeLayer.position = CGPointMake(radiusLogoImageView, radiusLogoImageView);
    UIBezierPath *path = [UIBezierPath bezierPathWithArcCenter:CGPointMake(radiusLogoImageView, radiusLogoImageView) radius:(radiusLogoImageView + 4.0f) startAngle:-M_PI_2 endAngle:3*M_PI_2 clockwise:YES];
    self.circularShapeLayer.path = [path CGPath];
    self.circularShapeLayer.strokeColor = UIColor.mnz_redMain.CGColor;
    self.circularShapeLayer.fillColor = UIColor.clearColor.CGColor;
    self.circularShapeLayer.lineWidth = 2.0f;
    self.circularShapeLayer.strokeStart = 0.0f;
    self.circularShapeLayer.strokeEnd = 0.0f;
    [self.logoImageView.layer addSublayer:self.circularShapeLayer];
    
    [self.activityIndicatorView startAnimating];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [MEGASdkManager.sharedMEGASdk addMEGARequestDelegate:self];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    [MEGASdkManager.sharedMEGASdk removeMEGARequestDelegate:self];
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    if ([[UIDevice currentDevice] iPhone4X] || [[UIDevice currentDevice] iPhone5X]) {
        return UIInterfaceOrientationMaskPortrait | UIInterfaceOrientationMaskPortraitUpsideDown;
    }
    
    return UIInterfaceOrientationMaskAll;
}

- (BOOL)prefersStatusBarHidden {
    return YES;
}

#pragma mark - Private

- (void)startTimerAPI_EAGAIN {
    //Check if the SDK is waiting to complete a request and get the reason
    self.timerAPI_EAGAIN = [NSTimer scheduledTimerWithTimeInterval:10 target:self selector:@selector(showWaitingReason) userInfo:nil repeats:NO];
}

- (void)invalidateTimerAPI_EAGAIN {
    [self.timerAPI_EAGAIN invalidate];
    
    self.label.text = @"";
}

- (void)showWaitingReason {
    NSString *message;
    switch (MEGASdkManager.sharedMEGASdk.waiting) {
        case RetryNone:
            break;
            
        case RetryConnectivity:
            message = AMLocalizedString(@"unableToReachMega", @"Message shown when the app is waiting for the server to complete a request due to connectivity issue.");
            break;
            
        case RetryServersBusy:
            message = AMLocalizedString(@"serversAreTooBusy", @"Message shown when the app is waiting for the server to complete a request due to a HTTP error 500.");
            break;
            
        case RetryApiLock:
            message = AMLocalizedString(@"takingLongerThanExpected", @"Message shown when the app is waiting for the server to complete a request due to an API lock (error -3).");
            break;
            
        case RetryRateLimit:
            message = AMLocalizedString(@"tooManyRequest", @"Message shown when the app is waiting for the server to complete a request due to a rate limit (error -4).");
            break;
            
        case RetryLocalLock:
            break;
            
        case RetryUnknown:
            break;
            
        default:
            break;
    }
    self.label.text = message;
    
    MEGALogDebug(@"The SDK is waiting to complete a request, reason: %lu", (unsigned long)MEGASdkManager.sharedMEGASdk.waiting);
}

#pragma mark - MEGARequestDelegate

- (void)onRequestUpdate:(MEGASdk *)api request:(MEGARequest *)request {
    if (request.type == MEGARequestTypeFetchNodes) {
        [self invalidateTimerAPI_EAGAIN];
        
        float progress = request.transferredBytes.floatValue / request.totalBytes.floatValue;
        if (progress > 0 && progress <= 1.0) {
            //Avoid that the stroke goes back and forward.
            if (progress < self.circularShapeLayer.strokeEnd) {
                return;
            }
            
            //Wait to stop the activity indicator until the beginning of the circular shape has been drawn.
            if (self.activityIndicatorView.isAnimating && progress > 0.1) {
                [self.activityIndicatorView stopAnimating];
            }
            self.circularShapeLayer.strokeEnd = progress;
        }
    }
}

- (void)onRequestFinish:(MEGASdk *)api request:(MEGARequest *)request error:(MEGAError *)error {
    if (error.type) {
        return;
    } else {
        switch (request.type) {
            case MEGARequestTypeLogin:
                [self invalidateTimerAPI_EAGAIN];
                break;
                
            case MEGARequestTypeFetchNodes: {
                [self invalidateTimerAPI_EAGAIN];
                
                [self.delegate setupFinished];
                [self.delegate readyToShowRecommendations];
                break;
            }
                
            default:
                break;
        }
    }
}

- (void)onRequestTemporaryError:(MEGASdk *)api request:(MEGARequest *)request error:(MEGAError *)error {
    switch (request.type) {
        case MEGARequestTypeLogin:
        case MEGARequestTypeFetchNodes: {
            if (!self.timerAPI_EAGAIN.isValid) {
                [self startTimerAPI_EAGAIN];
            }
            break;
        }
            
        default:
            break;
    }
}

@end
