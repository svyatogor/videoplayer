//
//  VideoPlayerViewModel.swift
//  VideoPlayer
//
//  Created by Sergey Kuleshov on 21.12.2019.
//  Copyright © 2019 Sergey Kuleshov. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa

class VideoPlayerViewModel: NSObject {
    enum Result {
        case error(String)
        case downloading(Float)
        case completed
    }
    
    private var result = PublishSubject<Result>()
    
    struct Input {
        var url: Driver<String?>
        var playSignal: Signal<Void>
        var downloadSignal: Signal<Void>
    }
    
    struct Output {
        var playSignal: Signal<URL>
        var result: Signal<Result>
        var isDownloadEnabled: Driver<Bool>
    }
    
    func transform(input: Input) -> Output {
        let session = URLSession(configuration: .default,
                                 delegate: self,
                                 delegateQueue: OperationQueue())
        let playSignal = input.playSignal
            .withLatestFrom(input.url)
            .filter { $0 != nil }
            .map { URL(string: $0!) }
            .filter { $0 != nil }
            .map { $0! }
            .map { [weak self] in self?.tryFromCache($0) ?? $0 }
            .asSignal(onErrorSignalWith: .empty())
        
        let isDownloadEnabled = playSignal
            .map { $0.scheme != "file" }
            .asDriver(onErrorJustReturn: true)
        
        let result = input.downloadSignal
            .withLatestFrom(input.url)
            .asObservable()
            .filter { $0 != nil }
            .flatMapLatest {[weak self] string -> Observable<Result> in
                if let url = URL(string: string!) {
                    session.downloadTask(with: url).resume()
                    return self?.result.startWith(.downloading(0.0)) ?? .empty()
                } else {
                    return .just(.error("Invalid URL"))
                }
            }
            .asSignal(onErrorJustReturn: .error("Unknwon error"))
        
        return Output(playSignal: playSignal, result: result, isDownloadEnabled: isDownloadEnabled)
    }
    
    private func tryFromCache(_ url: URL) -> URL {
        do {
            let cacheURL = try
                FileManager.default.url(for: .cachesDirectory,
                                        in: .userDomainMask,
                                        appropriateFor: nil,
                                        create: false)
            let cachedURL = cacheURL.appendingPathComponent(url.lastPathComponent)
            return FileManager.default.fileExists(atPath: cachedURL.path) ? cachedURL : url
        } catch {
            return url
        }
    }
}

extension VideoPlayerViewModel: URLSessionDownloadDelegate {
    func urlSession(_ session: URLSession, didBecomeInvalidWithError error: Error?) {
        if let error = error {
            result.onNext(.error(error.localizedDescription))
        }
    }
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        guard let fileName = downloadTask.currentRequest?.url?.lastPathComponent else  { return }
        do {
            let cacheURL = try
                FileManager.default.url(for: .cachesDirectory,
                                        in: .userDomainMask,
                                        appropriateFor: nil,
                                        create: false)
            let savedURL = cacheURL.appendingPathComponent(fileName)
            try FileManager.default.moveItem(at: location, to: savedURL)
            result.onNext(.completed)
        } catch {
            result.onNext(.error("Failed to save file"))
        }
     }
     
     func urlSession(_ session: URLSession,
                     downloadTask: URLSessionDownloadTask,
                     didWriteData bytesWritten: Int64,
                     totalBytesWritten: Int64,
                     totalBytesExpectedToWrite: Int64) {
         result.onNext(.downloading(Float(totalBytesWritten) / Float(totalBytesExpectedToWrite)))
     }
}
