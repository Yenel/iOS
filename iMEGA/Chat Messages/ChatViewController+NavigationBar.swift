
import Foundation

extension ChatViewController {
    
    private var rightBarButtons: [UIBarButtonItem] {
        var barButtons: [UIBarButtonItem] = []
        
        if chatRoom.isGroup {
            if chatRoom.ownPrivilege == .moderator {
                barButtons.append(addParticpantBarButtonItem)
            }
            
            barButtons.append(audioCallBarButtonItem)
        } else {
            barButtons = [audioCallBarButtonItem, videoCallBarButtonItem]
        }
        
        return barButtons
    }
    
    private var shouldDisableAudioVideoCall: Bool {
        let chatConnection = MEGASdkManager.sharedMEGAChatSdk()!.chatConnectionState(chatRoom.chatId)
        
        return chatRoom.ownPrivilege.rawValue < MEGAChatRoomPrivilege.standard.rawValue
            || chatConnection != .online
            || !MEGAReachabilityManager.isReachable()
            || chatRoom.peerCount == 0
            || MEGASdkManager.sharedMEGAChatSdk()!.hasCall(inChatRoom: chatRoom.chatId)
            || MEGASdkManager.sharedMEGAChatSdk()!.mnz_existsActiveCall
    }
    
    
    func configureNavigationBar() {
        addRightBarButtons()
        setTitleView()
    }
    
    private func addRightBarButtons() {
        self.navigationItem.rightBarButtonItems = rightBarButtons
        
        let shouldEnableAudioVideoCall = !shouldDisableAudioVideoCall
        audioCallBarButtonItem.isEnabled = shouldEnableAudioVideoCall
        videoCallBarButtonItem.isEnabled = shouldEnableAudioVideoCall
    }
    
    private func setTitleView() {
        let titleView = ChatTitleView.instanceFromNib
        titleView.chatRoom = chatRoom
        titleView.tapHandler = { [weak self] in
            guard let `self` = self else {
                return
            }
            
            self.didTapTitle()
        }
        navigationItem.titleView = titleView
    }
    
    private func didTapTitle() {
        if chatRoom.isGroup {
            pushGroupDetailsViewController()
        } else {
            pushContactDetailsViewController()
        }
    }
    
    private func pushGroupDetailsViewController() {
        let storyboard = UIStoryboard(name: "Chat", bundle: nil)
        if let groupDetailsViewController = storyboard.instantiateViewController(withIdentifier:"GroupChatDetailsViewControllerID") as? GroupChatDetailsViewController {
            groupDetailsViewController.chatRoom = chatRoom
            navigationController?.pushViewController(groupDetailsViewController, animated: true)
        } else {
            MEGALogError("ChatViewController: Could not GroupChatDetailsViewController")
        }
    }
    
    private func pushContactDetailsViewController() {
        let storyboard = UIStoryboard(name: "Contacts", bundle: nil)
        if let contactDetailsViewController = storyboard.instantiateViewController(withIdentifier:"ContactDetailsViewControllerID") as? ContactDetailsViewController {
            let peerHandle = chatRoom.peerHandle(at: 0)
            let peerEmail = MEGASdkManager.sharedMEGAChatSdk()?.contacEmail(byHandle: peerHandle)

            contactDetailsViewController.contactDetailsMode = .fromChat
            contactDetailsViewController.userEmail = peerEmail
            contactDetailsViewController.userHandle = peerHandle
            navigationController?.pushViewController(contactDetailsViewController, animated: true)
        } else {
            MEGALogError("ChatViewController: Could not ContactDetailsViewControllerID")
        }
    }
    
}