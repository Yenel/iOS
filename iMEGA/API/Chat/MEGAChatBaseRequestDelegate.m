
#import "MEGAChatBaseRequestDelegate.h"

#import "SVProgressHUD.h"
#import "LocalizationSystem.h"

@implementation MEGAChatBaseRequestDelegate

- (void)onChatRequestStart:(MEGAChatSdk *)api request:(MEGAChatRequest *)request {
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
}

- (void)onChatRequestFinish:(MEGAChatSdk *)api request:(MEGAChatRequest *)request error:(MEGAChatError *)error {
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
        
    if (error.type) {
        if (request.type == MEGAChatRequestTypeChatLinkHandle && error.type == MEGAErrorTypeApiENoent) {
            return;
        }
        if (request.type == MEGAChatRequestTypeLoadPreview && (error.type == MEGAErrorTypeApiEExist || request.userHandle == MEGAInvalidHandle)) {
            return;
        }
        if ((request.type == MEGAChatRequestTypeAnswerChatCall || request.type == MEGAChatRequestTypeStartChatCall) && error.type == MEGAChatErrorTooMany) {
            [SVProgressHUD showErrorWithStatus:AMLocalizedString(@"Error. No more participants are allowed in this group call.", @"Message show when a call cannot be established because there are too many participants in the group call")];
            return;
        }

        [SVProgressHUD setDefaultMaskType:SVProgressHUDMaskTypeNone];
        [SVProgressHUD showErrorWithStatus:[NSString stringWithFormat:@"%@ %@", request.requestString, AMLocalizedString(error.name, nil)]];
    }
}

@end
