//
//  ViewController.swift
//  VideoPlayer
//
//  Created by Sergey Kuleshov on 21.12.2019.
//  Copyright © 2019 Sergey Kuleshov. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

class VideoPlayerController: UIViewController {
    @IBOutlet var playerView: PlayerView!
    @IBOutlet var videoUrlTextField: UITextField!
    @IBOutlet var progressView: UIProgressView!
    @IBOutlet var downloadButton: UIButton!
    
    private let bag = DisposeBag()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        let input = VideoPlayerViewModel.Input(url: videoUrlTextField.rx.text.asDriver(),
                                               playSignal: videoUrlTextField.rx.controlEvent(.editingDidEndOnExit).asSignal(),
                                               downloadSignal: downloadButton.rx.tap.asSignal())
        
        let viewModel = VideoPlayerViewModel()
        let output = viewModel.transform(input: input)
        output.playSignal.emit(onNext: {[weak self] in
                self?.playerView.play(url: $0)
            }).disposed(by: bag)        
        
        output.isDownloadEnabled.map { !$0 }.drive(downloadButton.rx.isHidden).disposed(by: bag)
        
        output.result.emit(onNext: {[weak self] result in
            switch result {
            case .completed:
                self?.downloadButton.isEnabled = true
                self?.progressView.isHidden = true
            case .downloading(let progress):
                self?.downloadButton.isEnabled = false
                self?.progressView.isHidden = false
                self?.progressView.progress = progress
            case .error(let message):
                self?.downloadButton.isEnabled = true
                self?.progressView.isHidden = true
                
                let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default))
                self?.show(alert, sender: self)
            }
        }).disposed(by: bag)
    }
}

