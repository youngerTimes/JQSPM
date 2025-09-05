//
//  MyCustomURLProtocol.swift
//  TestDemo
//
//  Created by MrBai on 2025/6/28.
//

import Foundation

class CustomURLProtocol:URLProtocol  {

    // 私有属性，用于存储原始的 URLSessionDataTask 或 URLSession
    // 这样我们可以在自定义协议中转发请求
    private static var myRequestKey: String { return "MyCustomURLProtocolHandledKey" }
    private var internalSession: URLSession?
    private var internalTask: URLSessionDataTask?
    private var uuid = UUID().uuidString
    // MARK: - 必须重写的方法

    /// 1. 判断是否能处理当前请求
    /// 当 URLSession 发起一个请求时，系统会询问所有已注册的 URLProtocol 子类是否能够处理这个请求。
    override class func canInit(with request: URLRequest) -> Bool {
        // 这里定义你的拦截逻辑
        // 例如，只拦截特定域名的请求
        guard let url = request.url else { return false }
//        print("尝试拦截请求: \(url.absoluteString)")

        // 避免无限循环：如果请求已经被我们处理过，就不要再次处理了
        // 这是关键，否则请求会一直被我们自己拦截
        if URLProtocol.property(forKey: CustomURLProtocol.myRequestKey, in: request) as? Bool == true {
            return false
        }

        // 假设我们只拦截 HTTP 或 HTTPS 请求
        return url.scheme == "http" || url.scheme == "https"
        // 或者只拦截特定主机
        // return url.host == "api.example.com"
    }

    /// 2. 标准化请求 (可选)
    /// 如果需要在转发请求之前修改请求，可以在这里进行。
    /// 例如，添加自定义头、重定向等。
    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        // 通常情况下，直接返回原始请求即可
        // 如果需要修改请求，可以在这里返回一个修改后的 URLRequest 实例
        // 比如：
        // var mutableRequest = (request as NSURLRequest).mutableCopy() as! NSMutableURLRequest
        // mutableRequest.addValue("MyCustomValue", forHTTPHeaderField: "X-Custom-Header")
        // return mutableRequest as URLRequest
        return request
    }

    /// 3. 是否应该缓存响应 (可选)
    /// 返回一个布尔值，指示是否应该缓存给定的响应。
    override class func canInit(with task: URLSessionTask) -> Bool {
        // 如果你的协议需要基于 URLSessionTask 来判断是否处理，而不是只基于 URLRequest
        // 在 iOS 7+ 废弃，通常使用 canInit(with: URLRequest)
        // 不过对于某些边缘情况，如 WebSocket 或特定 streaming，可能需要
        return CustomURLProtocol.canInit(with: task.currentRequest!)
    }

    // MARK: - 启动和停止请求

    /// 4. 启动请求
    /// 当 canInit(with:) 返回 true 时，系统会创建一个 MyCustomURLProtocol 实例并调用此方法。
    /// 在这里，你需要启动你的“替代”网络请求，或者直接提供响应。
    override func startLoading() {
        guard let request = request as? NSMutableURLRequest else { return }

        // 标记请求已被我们处理，防止无限循环
        URLProtocol.setProperty(true, forKey: CustomURLProtocol.myRequestKey, in: request)

        let config = URLSessionConfiguration.default
        internalSession = URLSession(configuration: config, delegate: self, delegateQueue: nil)
        internalTask = internalSession?.dataTask(with: request as URLRequest)
        internalTask?.resume()
        if let task = internalTask {
            NetworkMonitorManager.shared.addTask(uuid, task: task)
        }
    }

    /// 5. 停止请求
    /// 当请求被取消或完成时，系统会调用此方法。
    /// 在这里，你需要清理任何正在进行的网络操作。
    override func stopLoading() {
        internalTask?.cancel() // 取消可能正在进行的内部任务
        internalSession?.invalidateAndCancel() // 确保 session 被正确释放
        internalTask = nil
        internalSession = nil
    }
}

// 扩展 MyCustomURLProtocol 来实现 URLSessionDelegate 和 URLSessionDataDelegate
extension CustomURLProtocol: @unchecked Sendable,URLSessionDelegate, URLSessionDataDelegate  {

    /// 接收到响应
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive response: URLResponse, completionHandler: @escaping (URLSession.ResponseDisposition) -> Void) {
        // 将响应传递给 URLProtocol 的 client
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            NetworkMonitorManager.shared.receive(uuid: uuid, task: dataTask, didReceive: response)
        completionHandler(.allow)
    }

    /// 接收到数据
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        // 将数据传递给 URLProtocol 的 client
        NetworkMonitorManager.shared.receive(uuid: uuid, didReceive: data)
        client?.urlProtocol(self, didLoad: data)
    }

    func urlSession(_ session: URLSession, task: URLSessionTask, didFinishCollecting metrics: URLSessionTaskMetrics) {
        NetworkMonitorManager.shared.receive(uuid: uuid, didFinishCollecting: metrics)
    }

    /// 请求完成（成功或失败）
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        NetworkMonitorManager.shared.receive(uuid: uuid, task: task, didCompleteWithError: error)
        if let error = error {
            // 将错误传递给 URLProtocol 的 client
            client?.urlProtocol(self, didFailWithError: error)
        } else {
            // 请求成功完成
            client?.urlProtocolDidFinishLoading(self)
        }
    }

    // 更多代理方法，例如重定向处理等，可以根据需要实现
    func urlSession(_ session: URLSession, task: URLSessionTask, willPerformHTTPRedirection response: HTTPURLResponse, newRequest request: URLRequest, completionHandler: @escaping (URLRequest?) -> Void) {
        // 如果需要处理重定向，可以在这里修改 newRequest 或直接返回 nil 阻止重定向
        self.client?.urlProtocol(self, wasRedirectedTo: request, redirectResponse: response)
        completionHandler(request)
    }
}

extension CustomURLProtocol {
    /// Inject the protocol in every `URLSession` instance created by the app.
    public static func enableAutomaticRegistration() {
        URLProtocol.registerClass(CustomURLProtocol.self)
        if let lhs = class_getClassMethod(URLSession.self, #selector(URLSession.init(configuration:delegate:delegateQueue:))),
           let rhs = class_getClassMethod(URLSession.self, #selector(URLSession.networkMonitor_init(configuration:delegate:delegateQueue:))) {
            method_exchangeImplementations(lhs, rhs)
        }
    }
}

private extension URLSession {
    @objc class func networkMonitor_init(configuration: URLSessionConfiguration, delegate: URLSessionDelegate?, delegateQueue: OperationQueue?) -> URLSession {
        var protocolClasses = configuration.protocolClasses ?? []
        if !protocolClasses.contains(where: { $0 == CustomURLProtocol.self }) {
            protocolClasses.insert(CustomURLProtocol.self, at: 0)
        }
        configuration.protocolClasses = protocolClasses
        return self.networkMonitor_init(configuration: configuration, delegate: delegate, delegateQueue: delegateQueue)
    }
}
