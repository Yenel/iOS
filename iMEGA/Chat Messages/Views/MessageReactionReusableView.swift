import MessageKit
import AlignedCollectionViewFlowLayout

protocol MessageReactionReusableViewDelegate: class {
    func emojiTapped(_ emoji: String, chatMessage: ChatMessage)
    func emojiLongPressed(_ emoji: String, chatMessage: ChatMessage)
}

class MessageReactionReusableView: MessageReusableView, UICollectionViewDelegate, UICollectionViewDataSource {
    
    @IBOutlet weak var reactionCollectionView: UICollectionView!
    var emojis = [String]()
    
    var chatMessage: ChatMessage? {
        didSet {
            emojis.removeAll()
            let megaMessage = chatMessage?.message
            let list = MEGASdkManager.sharedMEGAChatSdk()?.getMessageReactions(forChat: chatMessage?.chatRoom.chatId ?? 0, messageId: megaMessage?.messageId ?? 0)
            for index in 0..<list!.size {
                emojis.append((list?.string(at: index))!)
            }
            reactionCollectionView.reloadData()
        }
    }
    
    weak var delegate: MessageReactionReusableViewDelegate?

    override func awakeFromNib() {
        super.awakeFromNib()
        
        reactionCollectionView.delegate = self
        reactionCollectionView.dataSource = self
        
        reactionCollectionView.register(ReactionCollectionViewCell.nib, forCellWithReuseIdentifier: ReactionCollectionViewCell.reuseIdentifier)
        // Initialization code
        
        guard let flowLayout = reactionCollectionView.collectionViewLayout as? AlignedCollectionViewFlowLayout else {
            return
        }
        flowLayout.horizontalAlignment = .trailing
        flowLayout.estimatedItemSize = CGSize(width: 1, height: 1)
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return emojis.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView
            .dequeueReusableCell(withReuseIdentifier: ReactionCollectionViewCell.reuseIdentifier, for: indexPath)
        
        let emoji = emojis.reversed()[indexPath.row]
        
        let megaMessage = chatMessage?.message
        
        let count = MEGASdkManager.sharedMEGAChatSdk()?.getMessageReactionCount(forChat: chatMessage?.chatRoom.chatId ?? 0, messageId: megaMessage?.messageId ?? 0, reaction: emoji) ?? 0

        if let reactionCell = cell as? ReactionCollectionViewCell {
            reactionCell.configureCell(emoji, count)
            reactionCell.delegate = self
        }
        
        return cell
    }
}

extension MessageReactionReusableView: ReactionCollectionViewCellDelegate {
    func emojiTapped(_ emoji: String) {
        guard let delegate = delegate, let chatMessage = chatMessage else {
            return
        }
        
        delegate.emojiTapped(emoji, chatMessage: chatMessage)
    }
    
    func emojiLongPressed(_ emoji: String) {
        guard let delegate = delegate, let chatMessage = chatMessage else {
            return
        }

        delegate.emojiLongPressed(emoji, chatMessage: chatMessage)
    }
}

//
//
//extension MessageReactionReusableView: MEGAChatRoomDelegate {
//
//    func onReactionUpdate(_ api: MEGAChatSdk!, messageId: UInt64, reaction: String!, count: Int) {
//        print(reaction)
//    }
//}
