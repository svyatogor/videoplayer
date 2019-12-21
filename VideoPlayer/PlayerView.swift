//
//  PlayerView.swift
//  VideoPlayer
//
//  Created by Sergey Kuleshov on 21.12.2019.
//  Copyright © 2019 Sergey Kuleshov. All rights reserved.
//

import Foundation
import UIKit
import AVFoundation

fileprivate enum PlayerState {
    case play
    case pause
    
    var next: PlayerState {
        switch self {
        case .play:
            return .pause
        case .pause:
            return .play
        }
    }
}

class PlayerView: UIControl {
    private var player: AVPlayer?
    private var playerLayer: AVPlayerLayer?
    private var url: URL?
    private var playImageView = UIImageView(image: UIImage(named: "playVideo"))
    private var playerState: PlayerState? {
        didSet {
            guard let newState = playerState, let player = player else { return }
            switch newState {
            case .play:
                player.play()
                playImageView.isHidden = true
            case .pause:
                player.pause()
                playImageView.isHidden = false
            }
        }
    }
    
    func play(url: URL) {
        playerLayer?.removeFromSuperlayer()
        
        player = AVPlayer(url: url)
        playerLayer = AVPlayerLayer(player: player)
        playerLayer?.frame = bounds
        playerLayer?.videoGravity = .resizeAspectFill
        playerLayer?.masksToBounds = true
        
        if let playerLayer = self.playerLayer {
            layer.addSublayer(playerLayer)
            bringSubviewToFront(playImageView)
        }
        playerState = .play
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }
    
    private func setup() {
        backgroundColor = .black
        
        addTarget(self, action: #selector(onTap), for: .touchUpInside)
        
        playImageView.isHidden = false
        playImageView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(playImageView)
        
        playImageView.widthAnchor.constraint(equalToConstant: 45).isActive = true
        playImageView.heightAnchor.constraint(equalToConstant: 45).isActive = true
        playImageView.centerXAnchor.constraint(lessThanOrEqualTo: centerXAnchor).isActive = true
        playImageView.centerYAnchor.constraint(lessThanOrEqualTo: centerYAnchor).isActive = true
    }
    
    @objc private func onTap() {
        playerState = playerState?.next
    }
}
