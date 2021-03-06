
#import "MEGAShareRequestDelegate.h"

#import "SVProgressHUD.h"

@interface MEGAShareRequestDelegate ()

@property (nonatomic) NSUInteger numberOfRequests;
@property (nonatomic) NSUInteger totalRequests;
@property (nonatomic, getter=isChangingPermissions) BOOL changingPermissions;
@property (nonatomic, copy) void (^completion)(void);

@end

@implementation MEGAShareRequestDelegate

#pragma mark - Initialization

- (instancetype)initWithNumberOfRequests:(NSUInteger)numberOfRequests completion:(void (^)(void))completion {
    self = [super init];
    if (self) {
        _numberOfRequests = numberOfRequests;
        _totalRequests = numberOfRequests;
        _changingPermissions = NO;
        _completion = completion;
    }
    
    return self;
}

- (instancetype)initToChangePermissionsWithNumberOfRequests:(NSUInteger)numberOfRequests completion:(void (^)(void))completion {
    self = [super init];
    if (self) {
        _numberOfRequests = numberOfRequests;
        _totalRequests = numberOfRequests;
        _changingPermissions = YES;
        _completion = completion;
    }
    
    return self;
}

#pragma mark - MEGARequestDelegate

- (void)onRequestStart:(MEGASdk *)api request:(MEGARequest *)request {
    [super onRequestStart:api request:request];
}

- (void)onRequestFinish:(MEGASdk *)api request:(MEGARequest *)request error:(MEGAError *)error {
    [super onRequestFinish:api request:request error:error];
    
    self.numberOfRequests--;
    
    if (error.type) {
        if (error.type != MEGAErrorTypeApiEBusinessPastDue) {
            [SVProgressHUD setDefaultMaskType:SVProgressHUDMaskTypeNone];
            [SVProgressHUD showErrorWithStatus:[NSString stringWithFormat:@"%@ %@", request.requestString, AMLocalizedString(error.name, nil)]];
        } else {
            [SVProgressHUD dismiss];
        }
        return;
    }
    
    if (self.numberOfRequests == 0) {
        [SVProgressHUD setDefaultMaskType:SVProgressHUDMaskTypeNone];
        
        if (self.isChangingPermissions) {
            if (request.access == MEGAShareTypeAccessUnknown) {
                if (self.totalRequests > 1) {
                    [SVProgressHUD showImage:[UIImage imageNamed:@"hudForbidden"] status:AMLocalizedString(@"sharesRemoved", @"Message shown when some shares have been removed")];
                } else {
                    [SVProgressHUD showImage:[UIImage imageNamed:@"hudForbidden"] status:AMLocalizedString(@"shareRemoved", @"Message shown when a share have been removed")];
                }
            } else {
                [SVProgressHUD showSuccessWithStatus:AMLocalizedString(@"permissionsChanged", @"Message shown when you have changed the permissions of a shared folder")];
            }
        } else {
            if (self.totalRequests > 1) {
                NSString *sharedFolders = [NSString stringWithFormat:AMLocalizedString(@"sharedFolders_success", @"Success message for sharing multiple files."), self.totalRequests];
                [SVProgressHUD showImage:[UIImage imageNamed:@"hudSharedFolder"] status:sharedFolders];
            } else {
                [SVProgressHUD showImage:[UIImage imageNamed:@"hudSharedFolder"] status:AMLocalizedString(@"sharedFolder_success", @"Message shown when a folder have been shared")];
            }
        }
        
        if (self.completion) {
            self.completion();
        }
    }
}

@end
