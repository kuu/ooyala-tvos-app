//
//  DetailViewController.swift
//  DynamicFilteringTest
//
//  Created by Kuu Miyazaki on 2018/03/15.
//  Copyright © 2018 Kuu Miyazaki. All rights reserved.
//

import UIKit

class DetailViewController: UIViewController {
    var asset: Asset?
    var ooyalaPlayerViewController: OOOoyalaSimpleTVPlayerViewController!
    @IBOutlet weak var button: UIButton!

    override func viewDidLoad() {
        super.viewDidLoad()
        createPlayer()
    }
}

private extension DetailViewController {
    func createPlayer() {
        let options = OOOptions()
        options?.showPromoImage = true
        options?.bypassPCodeMatching = false
        options?.dynamicFilters = ["TVAppAccess"]
        
        guard let player = OOOoyalaPlayer(pcode: asset!.pcode, domain: OOPlayerDomain(string: "https://example.com"), options: options) else {
            return
        }
        guard let vc = OOOoyalaSimpleTVPlayerViewController(player: player) else {
            return
        }
        NotificationCenter.default.addObserver(self, selector: #selector(DetailViewController.notificationHandler(_:)), name: nil, object: player)
        self.ooyalaPlayerViewController = vc
        self.addChildViewController(vc)
        self.view.addSubview(vc.view)
        let bounds = self.view.bounds
        vc.view.frame = CGRect(x: 0, y: 0, width: bounds.width, height: bounds.height - 300)
        player.setEmbedCode(asset!.id)
        player.play()
    }
}

extension DetailViewController {
    @IBAction func buttonPress(_ sender: UIButton) {
        let state = ooyalaPlayerViewController.player.state()
        debugPrint("@@@ button pressed: \(String(describing: button.titleLabel?.text)). state: \(OOOoyalaPlayer.playerState(toString: state)!)")
        
        switch state {
        case OOOoyalaPlayerStatePlaying:
            ooyalaPlayerViewController.player.pause()
        case OOOoyalaPlayerStatePaused, OOOoyalaPlayerStateCompleted:
            ooyalaPlayerViewController.player.play()
        default:
            debugPrint("@@@ Ignore")
        }
    }
    
    @objc func notificationHandler(_ notification: Notification) {
        if notification.name != NSNotification.Name.OOOoyalaPlayerStateChanged {
            return
        }
        let state = ooyalaPlayerViewController.player.state()
        debugPrint("@@@ Notification Received: \(notification.name). state: \(OOOoyalaPlayer.playerState(toString: state)!)")
        
        switch state {
        case OOOoyalaPlayerStatePlaying:
            button.setTitle("Pause", for: .normal)
        case OOOoyalaPlayerStatePaused:
            button.setTitle("Resume", for: .normal)
        case OOOoyalaPlayerStateCompleted:
            button.setTitle("Play", for: .normal)
        default:
            debugPrint("@@@ Ignore")
        }
    }
}
