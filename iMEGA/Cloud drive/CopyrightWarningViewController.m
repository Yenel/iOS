
#import "CopyrightWarningViewController.h"

#import "GetLinkTableViewController.h"
#import "MEGASdkManager.h"
#ifdef MNZ_SHARE_EXTENSION
#import "MEGAShare-Swift.h"
#elif MNZ_PICKER_EXTENSION
#import "MEGAPicker-Swift.h"
#else
#import "MEGA-Swift.h"
#endif
#import "UIApplication+MNZCategory.h"

@interface CopyrightWarningViewController ()

@property (weak, nonatomic) IBOutlet UINavigationItem *copyrightWarningNavigationItem;
@property (weak, nonatomic) IBOutlet UILabel *copyrightWarningLabel;
@property (weak, nonatomic) IBOutlet UILabel *copyrightMessageLabel;

@property (weak, nonatomic) IBOutlet UIToolbar *toolbar;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *disagreeBarButtonItem;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *agreeBarButtonItem;

@end

@implementation CopyrightWarningViewController

#pragma mark - Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.copyrightWarningNavigationItem.title = AMLocalizedString(@"copyrightWarning", @"A title for the Copyright Warning");
    self.copyrightWarningLabel.text = AMLocalizedString(@"copyrightWarningToAll", @"A title for the Copyright Warning dialog. Designed to make the user feel as though this is not targeting them, but is a warning for everybody who uses our service.");
    self.copyrightMessageLabel.text = [NSString stringWithFormat:@"%@\n\n%@", AMLocalizedString(@"copyrightMessagePart1", nil), AMLocalizedString(@"copyrightMessagePart2", nil)];
    self.agreeBarButtonItem.title = AMLocalizedString(@"agree", @"button caption text that the user clicks when he agrees");
    self.disagreeBarButtonItem.title = AMLocalizedString(@"disagree", @"button caption text that the user clicks when he disagrees");
    
    [self updateAppearance];
}

- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection {
    [super traitCollectionDidChange:previousTraitCollection];
    
    if (@available(iOS 13.0, *)) {
        if ([self.traitCollection hasDifferentColorAppearanceComparedToTraitCollection:previousTraitCollection]) {
            #ifdef MNZ_SHARE_EXTENSION
            [ExtensionAppearanceManager forceToolbarUpdate:self.toolbar traitCollection:self.traitCollection];
            #elif MNZ_PICKER_EXTENSION
            
            #else
            [AppearanceManager forceToolbarUpdate:self.toolbar traitCollection:self.traitCollection];
            #endif
            
            [self updateAppearance];
        }
    }
}

#pragma mark - Private

- (void)updateAppearance {
    self.view.backgroundColor = UIColor.mnz_background;
}

#pragma mark - Public

+ (void)presentGetLinkViewControllerForNodes:(NSArray<MEGANode *> *)nodes inViewController:(UIViewController *)viewController {
    if (nodes != nil) {
        if (![[NSUserDefaults standardUserDefaults] boolForKey:@"agreedCopywriteWarning"]) {
            if ([MEGASdkManager.sharedMEGASdk publicLinks:MEGASortOrderTypeNone].size.intValue > 0) {
                [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"agreedCopywriteWarning"];
            }
        }
        if ([[NSUserDefaults standardUserDefaults] boolForKey:@"agreedCopywriteWarning"]) {
            UINavigationController *getLinkNC = [[UIStoryboard storyboardWithName:@"Cloud" bundle:nil] instantiateViewControllerWithIdentifier:@"GetLinkNavigationControllerID"];
            GetLinkTableViewController *getLinkTVC = getLinkNC.childViewControllers.firstObject;
            getLinkTVC.nodesToExport = nodes;
            [viewController presentViewController:getLinkNC animated:YES completion:nil];
        } else {
            UINavigationController *copyrightWarningNC = [[UIStoryboard storyboardWithName:@"Cloud" bundle:nil] instantiateViewControllerWithIdentifier:@"CopywriteWarningNavigationControllerID"];
            CopyrightWarningViewController *copyrightWarningVC = copyrightWarningNC.childViewControllers.firstObject;
            copyrightWarningVC.nodesToExport = nodes;
            [viewController presentViewController:copyrightWarningNC animated:YES completion:nil];
        }
    }
}

#pragma mark - IBActions

- (IBAction)disagreeTapped:(UIBarButtonItem *)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)agreeTapped:(UIBarButtonItem *)sender {
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"agreedCopywriteWarning"];
    [self dismissViewControllerAnimated:YES completion:^{
        UINavigationController *getLinkNavigationController = [[UIStoryboard storyboardWithName:@"Cloud" bundle:nil] instantiateViewControllerWithIdentifier:@"GetLinkNavigationControllerID"];
        GetLinkTableViewController *getLinkTVC = getLinkNavigationController.childViewControllers.firstObject;
        getLinkTVC.nodesToExport = self.nodesToExport;
        [UIApplication.mnz_presentingViewController presentViewController:getLinkNavigationController animated:YES completion:nil];
    }];
}

@end
