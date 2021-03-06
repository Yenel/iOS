import UIKit

@objc protocol NodeActionViewControllerDelegate {
    func nodeAction(_ nodeAction: NodeActionViewController, didSelect action: MegaNodeActionType, for node: MEGANode, from sender: Any) ->  ()
}

class NodeActionViewController: ActionSheetViewController {
    
    private var node: MEGANode
    private var displayMode: DisplayMode
    private var delegate: NodeActionViewControllerDelegate
    private var sender: Any
    
    private let titleLabel = UILabel.newAutoLayout()
    private let subtitleLabel = UILabel.newAutoLayout()
    private let separatorLineView = UIView.newAutoLayout()

    // MARK: - NodeActionViewController initializers

    @objc init(node: MEGANode, delegate: NodeActionViewControllerDelegate, displayMode: DisplayMode, isIncoming: Bool = false, sender: Any) {
        self.node = node
        self.displayMode = displayMode
        self.delegate = delegate
        self.sender = sender
        
        super.init(nibName: nil, bundle: nil)
        
        configurePresentationStyle(from: sender)
        
        self.actions = NodeActionBuilder()
            .setDisplayMode(displayMode)
            .setAccessLevel(MEGASdkManager.sharedMEGASdk().accessLevel(for: node))
            .setIsMediaFile(node.isFile() && (node.name.mnz_isImagePathExtension || node.name.mnz_isVideoPathExtension && node.mnz_isPlayable()))
            .setIsFile(node.isFile())
            .setIsRestorable(node.mnz_isRestorable())
            .setIsPdf(NSString(string: node.name).pathExtension.lowercased() == "pdf")
            .setisIncomingShareChildView(isIncoming)
            .setIsExported(node.isExported())
            .setIsOutshare(node.isOutShare())
            .setIsChildVersion(MEGASdkManager.sharedMEGASdk().node(forHandle: node.parentHandle)?.isFile())
            .build()

    }
    
    @objc init(node: MEGANode, delegate: NodeActionViewControllerDelegate, isPageView: Bool = true, sender: Any) {
        self.node = node
        self.displayMode = .previewLink
        self.delegate = delegate
        self.sender = sender
        
        super.init(nibName: nil, bundle: nil)
        
        configurePresentationStyle(from: sender)
        
        self.actions = NodeActionBuilder()
            .setDisplayMode(self.displayMode)
            .setIsPdf(NSString(string: node.name).pathExtension.lowercased() == "pdf")
            .setIsPageView(isPageView)
            .build()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        configureNodeHeaderView()
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        
        if #available(iOS 13.0, *) {
            if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
                updateAppearance()
            }
        }
    }
    
    override func updateAppearance() {
        super.updateAppearance()
        
        headerView?.backgroundColor = UIColor.mnz_secondaryBackgroundElevated(traitCollection)
        titleLabel.textColor = UIColor.mnz_label()
        subtitleLabel.textColor = UIColor.mnz_subtitles(for: traitCollection)
        separatorLineView.backgroundColor = UIColor.mnz_separator(for: traitCollection)
    }
    
    // MARK: - UITableViewDelegate

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let action = actions[indexPath.row] as? NodeAction else {
            return
        }
        dismiss(animated: true, completion: {
            self.delegate.nodeAction(self, didSelect: action.type, for: self.node, from: self.sender)
        })
    }
    
    // MARK: - Private

    private func configureNodeHeaderView() {
        
        headerView?.frame = CGRect(x: 0, y: 0, width: tableView.frame.width, height: 80)

        let nodeImageView = UIImageView.newAutoLayout()
        headerView?.addSubview(nodeImageView)
        nodeImageView.autoSetDimensions(to: CGSize(width: 40, height: 40))
        nodeImageView.autoPinEdge(toSuperviewSafeArea: .leading, withInset: 8)
        nodeImageView.autoAlignAxis(toSuperviewAxis: .horizontal)
        nodeImageView.mnz_setThumbnail(by: node)

        headerView?.addSubview(titleLabel)
        titleLabel.autoPinEdge(.leading, to: .trailing, of: nodeImageView, withOffset: 8)
        titleLabel.autoPinEdge(.trailing, to: .trailing, of: headerView!, withOffset: -8)
        titleLabel.autoAlignAxis(.horizontal, toSameAxisOf: headerView!, withOffset: -10)
        titleLabel.text = node.name
        titleLabel.font = .systemFont(ofSize: 15)
        
        headerView?.addSubview(subtitleLabel)
        subtitleLabel.autoPinEdge(.leading, to: .trailing, of: nodeImageView, withOffset: 8)
        subtitleLabel.autoPinEdge(.trailing, to: .trailing, of: headerView!, withOffset: -8)
        subtitleLabel.autoAlignAxis(.horizontal, toSameAxisOf: headerView!, withOffset: 10)
        subtitleLabel.font = .systemFont(ofSize: 12)
        guard let sharedMEGASdk = displayMode == .folderLink || displayMode == .nodeInsideFolderLink ? MEGASdkManager.sharedMEGASdkFolder() : MEGASdkManager.sharedMEGASdk() else {
            return
        }
        if node.isFile() {
            subtitleLabel.text = Helper.sizeAndModicationDate(for: node, api: sharedMEGASdk)
        } else {
            subtitleLabel.text = Helper.filesAndFolders(inFolderNode: node, api: sharedMEGASdk)
        }
        
        headerView?.addSubview(separatorLineView)
        separatorLineView.autoPinEdge(toSuperviewEdge: .leading)
        separatorLineView.autoPinEdge(toSuperviewEdge: .trailing)
        separatorLineView.autoPinEdge(toSuperviewEdge: .bottom)
        separatorLineView.autoSetDimension(.height, toSize: 1/UIScreen.main.scale)
    }
}
