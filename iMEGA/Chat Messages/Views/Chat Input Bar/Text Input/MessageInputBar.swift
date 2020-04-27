

import UIKit

protocol MessageInputBarDelegate: class {
    func tappedAddButton()
    func tappedSendButton(withText text: String)
    func tappedVoiceButton()
    func typing(withText text: String)
}

class MessageInputBar: UIView {
    
    // MARK:- Outlets
    
    @IBOutlet weak var messageTextView: MessageTextView!
    @IBOutlet weak var messageTextViewTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var messageTextViewBottomConstraint: NSLayoutConstraint!

    @IBOutlet weak var collapsedTextViewCoverView: UIView!
    @IBOutlet weak var expandedTextViewCoverView: UIView!
    @IBOutlet weak var semiTransparentView: UIView!

    @IBOutlet weak var messageTextViewCoverView: MessageInputTextBackgroundView!
    @IBOutlet weak var messageTextViewCoverViewBottomContraint: NSLayoutConstraint!
    @IBOutlet weak var messageTextViewCoverViewTopConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var backgroundViewTrailingTextViewConstraint: NSLayoutConstraint!
    @IBOutlet weak var backgroundViewTrailingButtonConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var sendButton: UIButton!
    @IBOutlet weak var micButton: UIButton!
    @IBOutlet weak var expandCollapseButton: UIButton!
    
    // MARK:- Interface properties

    weak var delegate: MessageInputBarDelegate?
    
    // MARK:- Private properties

    private var keyboardShowObserver: NSObjectProtocol!
    private var keyboardHideObserver: NSObjectProtocol!
    
    private var expanded: Bool = false
    private var expandedHeight: CGFloat? {
        guard let keyboardHeight = keyboardHeight else {
            return nil
        }
           
        return UIScreen.main.bounds.height -
            (messageTextViewTopConstraintValueWhenExpanded!
                + messageTextViewBottomConstraintDefaultValue
                + keyboardHeight)
    }
    
    private var keyboardHeight: CGFloat?
    private let messageTextViewBottomConstraintDefaultValue: CGFloat = 15.0
    private let messageTextViewTopConstraintValueWhenCollapsed: CGFloat = 32.0
    private var messageTextViewTopConstraintValueWhenExpanded: CGFloat? {
        var statusBarHeight: CGFloat = 20.0
        if #available(iOS 11.0, *) {
            statusBarHeight = UIApplication.shared.keyWindow?.safeAreaInsets.top ?? 20.0
        }
        
        // The text view should be (statusBarHeight + 67.0) from the top of the screen
        return statusBarHeight + 67.0
    }
    
    // MARK: - Overriden methods.
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        setPlaceholderTextWhenKeyboardHidden()

        messageTextView.collapsedMaxHeightReachedAction = { [weak self] collapsedMaxHeightReached in
            guard let `self` = self, !self.expanded else {
                return
            }
            
            self.expandCollapseButton.isHidden = !collapsedMaxHeightReached
        }
        
        registerKeyboardNotifications()
        
        messageTextViewCoverView.maxCornerRadius = messageTextView.font!.lineHeight
            + messageTextViewCoverViewTopConstraint.constant
            + messageTextViewCoverViewBottomContraint.constant
            + messageTextView.textContainerInset.top
            + messageTextView.textContainerInset.bottom
    }
    
    override var intrinsicContentSize: CGSize {
        return .zero
    }
    
    //MARK: - interface method.
    
    func isMicButtonPresent(atLocation point: CGPoint) -> Bool {
        let view = hitTest(point, with: nil)
        return view === micButton
    }
    
    func dismissKeyboard() {
        messageTextView.resignFirstResponder()
    }
    
    // MARK: - Actions
    
    @IBAction func exapandCollapseButtonTapped(_ button: UIButton) {
        expanded = !expanded
        /// Since we are toggling first (the above line) if toggled state is expanded we need to expand.
        if expanded {
            expand()
        } else {
            collapse()
        }
    }
    
    @IBAction func sendButtonTapped(_ button: UIButton) {
        guard let delegate = delegate,
            let text = messageTextView.text else {
            return
        }
        
        messageTextView.text = nil
        delegate.tappedSendButton(withText: text)
    }
    
    @IBAction func voiceButtonTapped(_ button: UIButton) {
        guard let delegate = delegate else {
            return
        }
        
        delegate.tappedVoiceButton()
    }
    
    @IBAction func addButtonTapped(_ button: UIButton) {
        guard let delegate = delegate else {
            return
        }
        
        delegate.tappedAddButton()
    }
    
    // MARK: - Private methods
    
    private func registerKeyboardNotifications() {
        keyboardHideObserver = keyboardHideNotification()
        keyboardShowObserver = keyboardShowNotification()
    }
    
    private func removeKeyboardNotifications() {
        NotificationCenter.default.removeObserver(keyboardShowObserver!)
        NotificationCenter.default.removeObserver(keyboardHideObserver!)
    }
    
    private func expand() {
        expandAnimationStart(completionHandler: expandAnimationComplete)
    }
    
    private func collapse() {
        collapseAnimationStart(completionHandler: collapseAnimationComplete)
    }
    
    private func collapseAnimationStart(completionHandler: ((Bool) -> Void)?) {
        messageTextViewCoverView.isHidden = false
        messageTextViewCoverView.alpha = 0.0
        
        let priorValue = messageTextView.intrinsicContentSize.height
        messageTextView.expand(false, expandedHeight: nil)
        let newValue = messageTextView.intrinsicContentSize.height
        let delta = priorValue - newValue
        messageTextViewBottomConstraint.constant += delta
        layoutIfNeeded()
        
        UIView.animate(withDuration: 0.4, animations: {
            self.messageTextViewBottomConstraint.constant = self.messageTextViewBottomConstraintDefaultValue
            self.messageTextViewTopConstraint.constant += delta
            self.messageTextViewCoverView.alpha = 1.0
            self.semiTransparentView.alpha = 0.0
            self.layoutIfNeeded()
        }, completion: completionHandler)

    }
    
    private func collapseAnimationComplete(_ animationCompletion: Bool) {
        expandedTextViewCoverView.isHidden = true
        collapsedTextViewCoverView.isHidden = false

        semiTransparentView.isHidden = true
        semiTransparentView.alpha = 1.0
        
        messageTextViewTopConstraint.constant = messageTextViewTopConstraintValueWhenCollapsed
        messageTextViewBottomConstraint.constant = messageTextViewBottomConstraintDefaultValue
        expandCollapseButton.setImage(#imageLiteral(resourceName: "expand"), for: .normal)
    }
    
    private func expandAnimationStart(completionHandler: ((Bool) -> Void)?) {
        collapsedTextViewCoverView.isHidden = true
        messageTextViewCoverView.isHidden = true
        expandedTextViewCoverView.isHidden = false
        semiTransparentView.alpha = 0.0
        semiTransparentView.isHidden = false

        let topConstraintValue: CGFloat = UIScreen.main.bounds.height
            - (keyboardHeight!
                + messageTextViewBottomConstraint.constant
                + messageTextView.intrinsicContentSize.height)

        messageTextViewTopConstraint.constant = topConstraintValue
        layoutIfNeeded()
        
        let bottomAnimatableConstraint = topConstraintValue
            - messageTextViewTopConstraintValueWhenExpanded!

        UIView.animate(withDuration: 0.4, animations: {
            self.semiTransparentView.alpha = 1.0
            self.messageTextViewBottomConstraint.constant += bottomAnimatableConstraint
            self.messageTextViewTopConstraint.constant = self.messageTextViewTopConstraintValueWhenExpanded!
            self.layoutIfNeeded()
        }, completion: completionHandler)
    }
    
    private func expandAnimationComplete(_ animationCompletion: Bool) {
        messageTextViewBottomConstraint.constant = messageTextViewBottomConstraintDefaultValue
        messageTextViewTopConstraint.constant = messageTextViewTopConstraintValueWhenExpanded ?? messageTextViewTopConstraintValueWhenCollapsed
        messageTextView.expand(true, expandedHeight: expandedHeight)
        expandCollapseButton.setImage(#imageLiteral(resourceName: "collapse"), for: .normal)
    }
    
    private func keyboardShowNotification() -> NSObjectProtocol {
        return NotificationCenter.default.addObserver(
            forName: UIResponder.keyboardDidShowNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard let `self` = self else {
                return
            }
            
            guard let keyboardFrame = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue, self.messageTextView.isFirstResponder else {
                return
            }
            
            let inputBarHeight: CGFloat = self.messageTextView.intrinsicContentSize.height
                + self.messageTextViewBottomConstraint.constant
                + self.messageTextViewTopConstraint.constant
            self.keyboardHeight = keyboardFrame.size.height - inputBarHeight
            
            if self.backgroundViewTrailingButtonConstraint.isActive {
                return
            }
            
            self.setPlaceholderTextWhenKeyboardShown()
            
            self.sendButton.alpha = 0.0
            self.sendButton.isHidden = false

            UIView.animate(withDuration: 0.4, animations: {
                self.backgroundViewTrailingTextViewConstraint.isActive = false
                self.backgroundViewTrailingButtonConstraint.isActive = true
                self.micButton.alpha = 0.0
                self.sendButton.alpha = 1.0
                self.layoutIfNeeded()

            }) { _ in
                self.micButton.isHidden = true
                self.micButton.alpha = 1.0
            }
        }
    }
    
    private func keyboardHideNotification() -> NSObjectProtocol {
        return NotificationCenter.default.addObserver(
            forName: UIResponder.keyboardWillHideNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            guard let `self` = self else {
                return
            }
            
            self.micButton.alpha = 0.0
            self.micButton.isHidden = false
            
            self.setPlaceholderTextWhenKeyboardHidden()

            if self.messageTextView.text.count == 0 {
                UIView.animate(withDuration: 0.4, animations: {
                    self.backgroundViewTrailingTextViewConstraint.isActive = true
                    self.backgroundViewTrailingButtonConstraint.isActive = false
                    self.micButton.alpha = 1.0
                    self.sendButton.alpha = 0.0
                    self.layoutIfNeeded()
                }) { _ in
                    self.sendButton.isHidden = true
                    self.sendButton.alpha = 1.0
                }
            }
        }
    }
    
    private func setPlaceholderTextWhenKeyboardShown() {
        messageTextView.placeholderText = AMLocalizedString("Message...", "Chat: This is the placeholder text for text view when keyboard is shown")
    }
    
    private func setPlaceholderTextWhenKeyboardHidden() {
        messageTextView.placeholderText = AMLocalizedString("Write message to", "Chat: This is the placeholder text for text view when keyboard is hidden")
    }
    
    // MARK: - Deinit
    
    deinit {
        removeKeyboardNotifications()
    }
}

// MARK: - UITextViewDelegate

extension MessageInputBar: UITextViewDelegate {
    func textViewDidChange(_ textView: UITextView) {
        guard let delegate = delegate,
            let text = textView.text else {
            return
        }
        
        sendButton.isEnabled = !text.isEmpty
        delegate.typing(withText: text)
    }
}

