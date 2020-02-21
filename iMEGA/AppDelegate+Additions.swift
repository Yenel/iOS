
import Foundation
import SafariServices

extension AppDelegate {
    @objc func showAddPhoneNumberIfNeeded() {
        let visibleViewController = UIApplication.mnz_visibleViewController()
        if  visibleViewController is AddPhoneNumberViewController ||
            visibleViewController is InitialLaunchViewController ||
            visibleViewController is LaunchViewController ||
            visibleViewController is SMSVerificationViewController ||
            visibleViewController is VerificationCodeViewController ||
            visibleViewController is CreateAccountViewController ||
            visibleViewController is UpgradeTableViewController ||
            visibleViewController is OnboardingViewController ||
            visibleViewController is UIAlertController ||
            visibleViewController is VerifyEmailViewController { return }

        if MEGASdkManager.sharedMEGASdk().smsAllowedState() != .optInAndUnblock { return }
        
        if MEGASdkManager.sharedMEGASdk().smsVerifiedPhoneNumber() != nil { return }
        
        if let lastDateAddPhoneNumberShowed = UserDefaults.standard.value(forKey: "lastDateAddPhoneNumberShowed") {
            guard let days = Calendar.current.dateComponents([.day], from: lastDateAddPhoneNumberShowed as! Date, to: Date()).day else { return }
            if days < 7 { return }
        }
        
        UserDefaults.standard.set(Date(), forKey: "lastDateAddPhoneNumberShowed")
        
        let addPhoneNumberController = UIStoryboard(name: "SMSVerification", bundle: nil).instantiateViewController(withIdentifier: "AddPhoneNumberViewControllerID")
        addPhoneNumberController.modalPresentationStyle = .fullScreen
        UIApplication.mnz_presentingViewController()?.present(addPhoneNumberController, animated: true, completion: nil)
    }
    
    @objc func fetchContactsNickname() {
        guard let megaStore = MEGAStore.shareInstance(),
            let privateQueueContext = megaStore.childPrivateQueueContext else {
                return
        }
        
        privateQueueContext.perform {
            self.requestNicknames(context: privateQueueContext, store: megaStore) {
                OperationQueue.main.addOperation {
                    NotificationCenter.default.post(name: Notification.Name(MEGAAllUsersNicknameLoaded), object: nil)
                }
            }
        }
    }
    
    private func requestNicknames(context: NSManagedObjectContext, store: MEGAStore, completionBlock: @escaping (() -> Void)) {
        let requestDelegate = MEGAGenericRequestDelegate { request, error in
            if error.type != .apiOk {
                return
            }
            
            if let stringDictionary = request.megaStringDictionary {
                stringDictionary.forEach { key, value in
                    let userHandle = MEGASdk.handle(forBase64UserHandle: key)
                    
                    if let nickname = value.base64URLDecoded {
                        store.updateUser(withUserHandle: userHandle, nickname: nickname, context: context)
                    }
                }
                
                store.save(context)
                completionBlock()
            }
        }

        MEGASdkManager.sharedMEGASdk().getUserAttributeType(.alias, delegate: requestDelegate)
    }
    
    @objc func handleAccountBlockedEvent(_ event: MEGAEvent) {
        guard let suspensionType = AccountSuspensionType(rawValue: event.number) else { return }
        
        if suspensionType == .smsVerification && MEGASdkManager.sharedMEGASdk().smsAllowedState() != .notAllowed {
            if UIApplication.mnz_presentingViewController() is SMSNavigationViewController {
                return
            }
            
            let smsNavigationController = SMSNavigationViewController(rootViewController: SMSVerificationViewController.instantiate(with: .UnblockAccount))
            smsNavigationController.modalPresentationStyle = .fullScreen
            UIApplication.mnz_presentingViewController()?.present(smsNavigationController, animated: true, completion: nil)
        } else if suspensionType == .emailVerification {
            if UIApplication.mnz_visibleViewController() is VerifyEmailViewController || UIApplication.mnz_visibleViewController() is SFSafariViewController {
                return
            }
            
            let verifyEmailVC = UIStoryboard(name: "VerifyEmail", bundle: nil).instantiateViewController(withIdentifier: "VerifyEmailViewControllerID")
            UIApplication.mnz_presentingViewController()?.present(verifyEmailVC, animated: true, completion: nil)
        } else {
            let alert = UIAlertController(title: AMLocalizedString("error"), message: AMLocalizedString("accountBlocked", "Error message when trying to login and the account is blocked"), preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: AMLocalizedString("ok"), style: .cancel) { _ in
                MEGASdkManager.sharedMEGASdk().logout()
            })
            UIApplication.mnz_presentingViewController()?.present(alert, animated: true, completion: nil)
        }
    }
}

