
#import "CloudDriveTableViewController.h"

#import "NSDate+DateTools.h"

#import "UIImageView+MNZCategory.h"
#import "NSDate+MNZCategory.h"
#import "NSString+MNZCategory.h"

#import "Helper.h"
#import "MEGAReachabilityManager.h"
#import "MEGASdkManager.h"
#import "MEGA-Swift.h"
#import "MEGANode+MNZCategory.h"

#import "CloudDriveViewController.h"
#import "NodeTableViewCell.h"

@interface CloudDriveTableViewController () <UITableViewDelegate, UITableViewDataSource, MGSwipeTableCellDelegate>

@property (weak, nonatomic) IBOutlet UIView *bucketHeaderView;
@property (weak, nonatomic) IBOutlet UILabel *bucketHeaderParentFolderNameLabel;
@property (weak, nonatomic) IBOutlet UIImageView *bucketHeaderUploadOrVersionImageView;
@property (weak, nonatomic) IBOutlet UILabel *bucketHeaderHourLabel;

@end

@implementation CloudDriveTableViewController

#pragma mark - Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];

    //White background for the view behind the table view
    self.tableView.backgroundView = UIView.alloc.init;
    
    [self updateAppearance];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    if (self.cloudDrive.recentActionBucket) {
        NSString *dateString;
        if (self.cloudDrive.recentActionBucket.timestamp.isToday) {
            dateString = AMLocalizedString(@"Today", @"").uppercaseString;
        } else if (self.cloudDrive.recentActionBucket.timestamp.isYesterday) {
            dateString = AMLocalizedString(@"Yesterday", @"").uppercaseString;
        } else {
            dateString = self.cloudDrive.recentActionBucket.timestamp.mnz_formattedDateMediumStyle;
        }
        
        MEGANode *parentNode = [MEGASdkManager.sharedMEGASdk nodeForHandle:self.cloudDrive.recentActionBucket.parentHandle];
        self.bucketHeaderParentFolderNameLabel.text = [NSString stringWithFormat:@"%@ •", parentNode.name.uppercaseString];
        self.bucketHeaderUploadOrVersionImageView.image = self.cloudDrive.recentActionBucket.isUpdate ? [UIImage imageNamed:@"versioned"] : [UIImage imageNamed:@"recentUpload"];
        self.bucketHeaderHourLabel.text = dateString.uppercaseString;
    }
}

- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection {
    [super traitCollectionDidChange:previousTraitCollection];
    
    if (@available(iOS 13.0, *)) {
        if ([self.traitCollection hasDifferentColorAppearanceComparedToTraitCollection:previousTraitCollection]) {
            [self updateAppearance];
            
            [self.tableView reloadData];
        }
    }
}

#pragma mark - Private

- (void)updateAppearance {
    self.tableView.separatorColor = [UIColor mnz_separatorForTraitCollection:self.traitCollection];
}

#pragma mark - Public

- (void)reloadRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath) {
        [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
    }
}

- (void)setTableViewEditing:(BOOL)editing animated:(BOOL)animated {
    [self.tableView setEditing:editing animated:animated];
    
    [self.cloudDrive setViewEditing:editing];
    
    if (editing) {
        for (NodeTableViewCell *cell in self.tableView.visibleCells) {
            UIView *view = [[UIView alloc] init];
            view.backgroundColor = UIColor.clearColor;
            cell.selectedBackgroundView = view;
        }
    } else {
        for (NodeTableViewCell *cell in self.tableView.visibleCells){
            cell.selectedBackgroundView = nil;
        }
    }
}

- (void)tableViewSelectIndexPath:(NSIndexPath *)indexPath {
    [self tableView:self.tableView didSelectRowAtIndexPath:indexPath];
}

#pragma mark - Actions

- (IBAction)infoTouchUpInside:(UIButton *)sender {
    if (self.tableView.isEditing) {
        return;
    }
    
    CGPoint buttonPosition = [sender convertPoint:CGPointZero toView:self.tableView];
    NSIndexPath *indexPath = [self.tableView indexPathForRowAtPoint:buttonPosition];
    
    MEGANode *node = self.cloudDrive.searchController.searchBar.text.length >= kMinimumLettersToStartTheSearch ? [self.cloudDrive.searchNodesArray objectAtIndex:indexPath.row] : [self.cloudDrive.nodes nodeAtIndex:indexPath.row];
    
    [self.cloudDrive showCustomActionsForNode:node sender:sender];
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSInteger numberOfRows = 0;
    if ([MEGAReachabilityManager isReachable]) {
        if (self.cloudDrive.searchController.searchBar.text.length >= kMinimumLettersToStartTheSearch) {
            numberOfRows = self.cloudDrive.searchNodesArray.count;
        } else {
            numberOfRows = self.cloudDrive.nodes.size.integerValue;
        }
    }
    
    return numberOfRows;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    MEGANode *node = self.cloudDrive.searchController.searchBar.text.length >= kMinimumLettersToStartTheSearch ? [self.cloudDrive.searchNodesArray objectAtIndex:indexPath.row] : [self.cloudDrive.nodes nodeAtIndex:indexPath.row];

    [self.cloudDrive.nodesIndexPathMutableDictionary setObject:indexPath forKey:node.base64Handle];
    
    NodeTableViewCell *cell;
    if ([Helper.downloadingNodes objectForKey:node.base64Handle]) {
        cell = [self.tableView dequeueReusableCellWithIdentifier:@"downloadingNodeCell" forIndexPath:indexPath];
        if (cell == nil) {
            cell = [[NodeTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"downloadingNodeCell"];
        }
    } else {
        cell = [self.tableView dequeueReusableCellWithIdentifier:@"nodeCell" forIndexPath:indexPath];
        if (cell == nil) {
            cell = [[NodeTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"nodeCell"];
        }
    }
    
    cell.recentActionBucket = self.cloudDrive.recentActionBucket ?: nil;
    cell.cellFlavor = NodeTableViewCellFlavorCloudDrive;
    [cell configureCellForNode:node delegate:self api:[MEGASdkManager sharedMEGASdk]];
 
    if (self.tableView.isEditing) {
        // Check if selectedNodesArray contains the current node in the tableView
        for (MEGANode *tempNode in self.cloudDrive.selectedNodesArray) {
            if (tempNode.handle == node.handle) {
                [self.tableView selectRowAtIndexPath:indexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
            }
        }
        
        UIView *view = [[UIView alloc] init];
        view.backgroundColor = UIColor.clearColor;
        cell.selectedBackgroundView = view;
    }
    
    return cell;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    if (self.cloudDrive.recentActionBucket) {
        self.bucketHeaderView.backgroundColor = [UIColor mnz_secondaryBackgroundGrouped:self.traitCollection];
        self.bucketHeaderParentFolderNameLabel.textColor = self.bucketHeaderHourLabel.textColor = [UIColor mnz_secondaryGrayForTraitCollection:self.traitCollection];
    }
    
    return self.cloudDrive.recentActionBucket ? self.bucketHeaderView : nil;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return self.cloudDrive.recentActionBucket ? 45.0f : 0;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    MEGANode *node = self.cloudDrive.searchController.searchBar.text.length >= kMinimumLettersToStartTheSearch ? [self.cloudDrive.searchNodesArray objectAtIndex:indexPath.row] : [self.cloudDrive.nodes nodeAtIndex:indexPath.row];

    if (tableView.isEditing) {
        [self.cloudDrive.selectedNodesArray addObject:node];
        
        [self.cloudDrive updateNavigationBarTitle];

        [self.cloudDrive toolbarActionsForNodeArray:self.cloudDrive.selectedNodesArray];

        [self.cloudDrive setToolbarActionsEnabled:YES];
        
        if (self.cloudDrive.selectedNodesArray.count == self.cloudDrive.nodes.size.integerValue) {
            self.cloudDrive.allNodesSelected = YES;
        } else {
            self.cloudDrive.allNodesSelected = NO;
        }
        
        return;
    }
    
    [self.cloudDrive didSelectNode:node];
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row > self.cloudDrive.nodes.size.integerValue) {
        return;
    }
    MEGANode *node = [self.cloudDrive.nodes nodeAtIndex:indexPath.row];
    
    if (tableView.isEditing) {
        
        NSMutableArray *tempArray = self.cloudDrive.selectedNodesArray.copy;
        for (MEGANode *tempNode in tempArray) {
            if (tempNode.handle == node.handle) {
                [self.cloudDrive.selectedNodesArray removeObject:tempNode];
            }
        }
        
        [self.cloudDrive updateNavigationBarTitle];
        
        [self.cloudDrive toolbarActionsForNodeArray:self.cloudDrive.selectedNodesArray];
        
        if (self.cloudDrive.selectedNodesArray.count == 0) {
            [self.cloudDrive setToolbarActionsEnabled:NO];
        } else {
            if ([[MEGASdkManager sharedMEGASdk] isNodeInRubbish:node]) {
                [self.cloudDrive setToolbarActionsEnabled:YES];
            }
        }
        
        self.cloudDrive.allNodesSelected = NO;
        
        return;
    }
}

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wunguarded-availability"

- (UISwipeActionsConfiguration *)tableView:(UITableView *)tableView trailingSwipeActionsConfigurationForRowAtIndexPath:(NSIndexPath *)indexPath {
    MEGANode *node = self.cloudDrive.searchController.searchBar.text.length >= kMinimumLettersToStartTheSearch ? [self.cloudDrive.searchNodesArray objectAtIndex:indexPath.row] : [self.cloudDrive.nodes nodeAtIndex:indexPath.row];
    if ([[MEGASdkManager sharedMEGASdk] accessLevelForNode:node] != MEGAShareTypeAccessOwner) {
        return [UISwipeActionsConfiguration configurationWithActions:@[]];
    }
    
    if ([[MEGASdkManager sharedMEGASdk] isNodeInRubbish:node]) {
        MEGANode *restoreNode = [[MEGASdkManager sharedMEGASdk] nodeForHandle:node.restoreHandle];
        if (restoreNode && ![[MEGASdkManager sharedMEGASdk] isNodeInRubbish:restoreNode]) {
            UIContextualAction *restoreAction = [UIContextualAction contextualActionWithStyle:UIContextualActionStyleNormal title:nil handler:^(UIContextualAction * _Nonnull action, __kindof UIView * _Nonnull sourceView, void (^ _Nonnull completionHandler)(BOOL)) {
                [node mnz_restore];
                [self setTableViewEditing:NO animated:YES];
            }];
            if (@available(iOS 13.0, *)) {
                restoreAction.image = [[UIImage imageNamed:@"restore"] imageWithTintColor:UIColor.whiteColor];
            } else {
                restoreAction.image = [UIImage imageNamed:@"restore"];
            }
            restoreAction.backgroundColor = [UIColor mnz_turquoiseForTraitCollection:self.traitCollection] ;
            
            return [UISwipeActionsConfiguration configurationWithActions:@[restoreAction]];
        }
    } else {
        UIContextualAction *shareAction = [UIContextualAction contextualActionWithStyle:UIContextualActionStyleNormal title:nil handler:^(UIContextualAction * _Nonnull action, __kindof UIView * _Nonnull sourceView, void (^ _Nonnull completionHandler)(BOOL)) {
            UIActivityViewController *activityVC = [Helper activityViewControllerForNodes:@[node] sender:[self.tableView cellForRowAtIndexPath:indexPath]];
            [self presentViewController:activityVC animated:YES completion:nil];
            [self setTableViewEditing:NO animated:YES];
        }];
        if (@available(iOS 13.0, *)) {
            shareAction.image = [[UIImage imageNamed:@"share"] imageWithTintColor:UIColor.whiteColor];
        } else {
            shareAction.image = [UIImage imageNamed:@"share"];
        }
        shareAction.backgroundColor = UIColor.systemOrangeColor;
        
        UIContextualAction *rubbishBinAction = [UIContextualAction contextualActionWithStyle:UIContextualActionStyleNormal title:nil handler:^(UIContextualAction * _Nonnull action, __kindof UIView * _Nonnull sourceView, void (^ _Nonnull completionHandler)(BOOL)) {
            [node mnz_moveToTheRubbishBinWithCompletion:^{
                [self setTableViewEditing:NO animated:YES];
            }];
        }];
        if (@available(iOS 13.0, *)) {
            rubbishBinAction.image = [[UIImage imageNamed:@"rubbishBin"] imageWithTintColor:UIColor.whiteColor];
        } else {
            rubbishBinAction.image = [UIImage imageNamed:@"rubbishBin"];
        }
        rubbishBinAction.backgroundColor = UIColor.mnz_redError;
        
        if ([[Helper downloadingNodes] objectForKey:node.base64Handle] == nil) {
            
            UIContextualAction *downloadAction = [UIContextualAction contextualActionWithStyle:UIContextualActionStyleNormal title:nil handler:^(UIContextualAction * _Nonnull action, __kindof UIView * _Nonnull sourceView, void (^ _Nonnull completionHandler)(BOOL)) {
                if ([node mnz_downloadNodeOverwriting:NO]) {
                    [self reloadRowAtIndexPath:[self.cloudDrive.nodesIndexPathMutableDictionary objectForKey:node.base64Handle]];
                }
                
                [self setTableViewEditing:NO animated:YES];
            }];
            downloadAction.image = [UIImage imageNamed:@"infoDownload"];
            downloadAction.backgroundColor = [UIColor mnz_turquoiseForTraitCollection:self.traitCollection];
            
            return [UISwipeActionsConfiguration configurationWithActions:@[rubbishBinAction, shareAction, downloadAction]];
        } else {
            return [UISwipeActionsConfiguration configurationWithActions:@[rubbishBinAction, shareAction]];
        }

        return [UISwipeActionsConfiguration configurationWithActions:@[rubbishBinAction, shareAction]];
    }
    
    return [UISwipeActionsConfiguration configurationWithActions:@[]];
}

#pragma clang diagnostic pop

#pragma mark - MGSwipeTableCellDelegate

- (BOOL)swipeTableCell:(MGSwipeTableCell *)cell canSwipe:(MGSwipeDirection)direction fromPoint:(CGPoint)point {
    if (direction == MGSwipeDirectionLeftToRight) {
        return NO;
    }
    return !self.tableView.isEditing;
}

- (void)swipeTableCellWillBeginSwiping:(nonnull MGSwipeTableCell *)cell {
    NodeTableViewCell *nodeCell = (NodeTableViewCell *)cell;
    nodeCell.moreButton.hidden = YES;
}

- (void)swipeTableCellWillEndSwiping:(nonnull MGSwipeTableCell *)cell {
    NodeTableViewCell *nodeCell = (NodeTableViewCell *)cell;
    nodeCell.moreButton.hidden = NO;
}

- (NSArray *)swipeTableCell:(MGSwipeTableCell *)cell swipeButtonsForDirection:(MGSwipeDirection)direction swipeSettings:(MGSwipeSettings *)swipeSettings expansionSettings:(MGSwipeExpansionSettings *)expansionSettings {
    
    swipeSettings.transition = MGSwipeTransitionDrag;
    expansionSettings.buttonIndex = 0;
    expansionSettings.expansionLayout = MGSwipeExpansionLayoutCenter;
    expansionSettings.fillOnTrigger = NO;
    expansionSettings.threshold = 2;
    
    NSIndexPath *indexPath = [self.tableView indexPathForCell:cell];
    MEGANode *node = self.cloudDrive.searchController.searchBar.text.length >= kMinimumLettersToStartTheSearch ? [self.cloudDrive.searchNodesArray objectAtIndex:indexPath.row] : [self.cloudDrive.nodes nodeAtIndex:indexPath.row];
    if (direction == MGSwipeDirectionRightToLeft) {
        if ([[MEGASdkManager sharedMEGASdk] accessLevelForNode:node] != MEGAShareTypeAccessOwner) {
            return nil;
        }
        
        if ([[MEGASdkManager sharedMEGASdk] isNodeInRubbish:node]) {
            MEGANode *restoreNode = [[MEGASdkManager sharedMEGASdk] nodeForHandle:node.restoreHandle];
            if (restoreNode && ![[MEGASdkManager sharedMEGASdk] isNodeInRubbish:restoreNode]) {
                MGSwipeButton *restoreButton = [MGSwipeButton buttonWithTitle:@"" icon:[UIImage imageNamed:@"restore"] backgroundColor:[UIColor mnz_primaryGrayForTraitCollection:self.traitCollection] padding:25 callback:^BOOL(MGSwipeTableCell *sender) {
                    [node mnz_restore];
                    return YES;
                }];
                [restoreButton iconTintColor:[UIColor whiteColor]];
                
                return @[restoreButton];
            }
        } else {
            MGSwipeButton *shareButton = [MGSwipeButton buttonWithTitle:@"" icon:[UIImage imageNamed:@"share"] backgroundColor:UIColor.systemOrangeColor padding:25 callback:^BOOL(MGSwipeTableCell *sender) {
                UIActivityViewController *activityVC = [Helper activityViewControllerForNodes:@[node] sender:[self.tableView cellForRowAtIndexPath:indexPath]];
                [self presentViewController:activityVC animated:YES completion:nil];
                return YES;
            }];
            [shareButton iconTintColor:[UIColor whiteColor]];
            
            MGSwipeButton *rubbishBinButton = [MGSwipeButton buttonWithTitle:@"" icon:[UIImage imageNamed:@"rubbishBin"] backgroundColor:UIColor.mnz_redError padding:25 callback:^BOOL(MGSwipeTableCell *sender) {
                [node mnz_moveToTheRubbishBinWithCompletion:^{
                    [self setTableViewEditing:NO animated:YES];
                }];
                
                return YES;
            }];
            [rubbishBinButton iconTintColor:UIColor.whiteColor];
            if ([[Helper downloadingNodes] objectForKey:node.base64Handle] == nil) {
                
                MGSwipeButton *downloadButton = [MGSwipeButton buttonWithTitle:@"" icon:[UIImage imageNamed:@"infoDownload"] backgroundColor:[UIColor mnz_turquoiseForTraitCollection:self.traitCollection] padding:25 callback:^BOOL(MGSwipeTableCell *sender) {
                    [node mnz_downloadNodeOverwriting:NO];
                    return YES;
                }];
                [downloadButton iconTintColor:[UIColor whiteColor]];
                
                return @[rubbishBinButton, shareButton, downloadButton];
            } else {
                return @[rubbishBinButton, shareButton];
            }
        }
    }
    
    return nil;
}

@end
