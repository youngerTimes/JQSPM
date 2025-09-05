//
//  NetworkMonitorManager.swift
//  Voge
//
//  Created by MrBai on 2025/6/30.
//

import Foundation

final class NetworkMonitorManager {
    nonisolated(unsafe) static let shared = NetworkMonitorManager()
    private var taskCache = NSCache<NSString, NetworkInfoModel>()
    private var allKeys: [String] = []
    
    func start() {
        CustomURLProtocol.enableAutomaticRegistration()
        taskCache.countLimit = 100
    }

    func addTask(_ id: String, task: URLSessionTask) {
        clearCache(with: id)
        let model = NetworkInfoModel(id: id)
        model.setTask(task)
        model.requestHttpBody = task.originalRequest?.httpBodyStreamData
        taskCache.setObject(model, forKey: id as NSString)
        allKeys.append(id)
        if allKeys.count > 150 {
            removeUnUseKey()
        }
    }

    func receive(uuid: String, task: URLSessionDataTask, didReceive response: URLResponse) {
        let model = taskCache.object(forKey: uuid as NSString)
        model?.setTask(task)
        model?.state = .start
    }
    
    func receive(uuid: String, didReceive data: Data) {
        let model = taskCache.object(forKey: uuid as NSString)
        model?.responseData.append(data)
    }
    
    func receive(uuid: String, didFinishCollecting metrics: URLSessionTaskMetrics) {
        let model = taskCache.object(forKey: uuid as NSString)
        model?.metrics = metrics
    }
    
    func receive(uuid: String, task: URLSessionTask, didCompleteWithError error: Error?) {
        let model = taskCache.object(forKey: uuid as NSString)
        model?.setTask(task)
        if let error {
            model?.state = .failer(error)
        } else {
            model?.state = .completed
        }
    }
    
    func clearCache(with key: String) {
        taskCache.removeObject(forKey: key as NSString)
        allKeys.removeAll(where: {$0 == key})
    }

    func clearAll() {
        taskCache.removeAllObjects()
        allKeys.removeAll()
    }
    
    func taskList() -> [NetworkInfoModel] {
        removeUnUseKey()
        return allKeys.reversed().compactMap {
            taskCache.object(forKey: $0 as NSString)
        }
    }
    
    private func removeUnUseKey() {
        allKeys = allKeys.compactMap {
            if taskCache.object(forKey: $0 as NSString) == nil {
                return nil
            }
            return $0
        }
    }
}

enum NetworkInfoModelState {
    case start
    case failer(Error)
    case completed
}

class NetworkInfoModel {
    var id: String
    var metrics: URLSessionTaskMetrics?
    var originalRequest: URLRequest?
    var currentRequest: URLRequest?
    var response: URLResponse?
    var countOfBytesSent: Int64 = 0
    var countOfBytesReceived: Int64 = 0
    var state: NetworkInfoModelState = .start
    var responseData = Data()
    var requestHttpBody: Data?
    
    init(id: String) {
        self.id = id
    }
    
    func setTask(_ task: URLSessionTask) {
        originalRequest = task.originalRequest
        originalRequest = task.originalRequest
        currentRequest = task.currentRequest
        response = task.response
        countOfBytesSent = task.countOfBytesSent
        countOfBytesReceived = task.countOfBytesReceived
    }
}

extension URLRequest {
    var httpBodyStreamData: Data? {
        guard let bodyStream = self.httpBodyStream else {
            return nil
        }
        let bufferSize: Int = 1024
        let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: bufferSize)

        bodyStream.open()
        defer {
            buffer.deallocate()
            bodyStream.close()
        }

        var bodyStreamData = Data()
        while bodyStream.hasBytesAvailable {
            let readData = bodyStream.read(buffer, maxLength: bufferSize)
            guard readData != -1 else { return nil } // read failed
            bodyStreamData.append(buffer, count: readData)
        }
        return bodyStreamData
    }
}
