//
//  SpeechRecognizerManager.swift
//  TestDemo
//
//  Created by MrBai on 2025/7/3.
//

import Speech
import AVFoundation // 用于录音

#if canImport(UIKit)
/// 内置的语音识别
@available(iOS 10.0, macOS 10.15, *)
final class SpeechRecognizerManager: NSObject,SFSpeechRecognizerDelegate {

    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "zh-CN")) // 选择语言，例如中文
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    let audioEngine = AVAudioEngine() // 用于处理音频输入
    // 音量阈值，低于此值视为无语音
    private let audioLevelThreshold: Float = -40.0
    private var lastVoiceTime: Date?
    // 计时器，用于检测无语音状态
    private var silenceTimer: Timer?
    // 无语音时间阈值（秒）
    private let silenceThreshold: TimeInterval = 1.0

    var onTranscriptionUpdate: ((String?) -> Void)? // 用于更新转录结果的回调
    var onRecordDone:(()->Void)? //完成录音
    var onError: ((Error) -> Void)? // 用于处理错误的回调

    override init() {
        super.init()
        speechRecognizer?.delegate = self
    }

    // MARK: - 权限请求
    @MainActor func requestAuthorization(completion: @Sendable @escaping (Bool) -> Void) {
        SFSpeechRecognizer.requestAuthorization { authStatus in
                switch authStatus {
                case .authorized:
                    completion(true)
                case .denied, .restricted, .notDetermined:
                    completion(false)
                    self.onError?(SpeechRecognizerError.authorizationDenied)
                default:
                    completion(false)
                    self.onError?(SpeechRecognizerError.unknownAuthorizationStatus)
                }
        }
    }

    // MARK: - 开始录音并识别
    func startRecording() throws {
        // 取消之前的识别任务（如果有）
        if let recognitionTask = recognitionTask {
            recognitionTask.cancel()
            self.recognitionTask = nil
        }

        // 配置音频会话
        #if os(iOS)
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            onError?(SpeechRecognizerError.audioSessionSetupFailed(error))
            return
        }
        #endif

        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        recognitionRequest?.taskHint = .search
        guard let recognitionRequest else {
            fatalError("无法创建 SFSpeechAudioBufferRecognitionRequest 对象")
        }

        // 允许在识别过程中返回部分结果
        recognitionRequest.shouldReportPartialResults = true
        if #available(iOS 16, *) {
            //如果可以的话，添加断句
            recognitionRequest.addsPunctuation = true
        }

        // 确保 speechRecognizer 可用
        guard speechRecognizer?.isAvailable ?? false else {
            onError?(SpeechRecognizerError.recognizerNotAvailable)
            return
        }

        recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest) { result, error in
            var isFinal = false

            if let result {
                self.onTranscriptionUpdate?(result.bestTranscription.formattedString)
                isFinal = result.isFinal
                if !recognitionRequest.shouldReportPartialResults{
                    self.stopRecording()
                    self.onRecordDone?()
                }
            }
            
            if let error {
                self.clearRecordContext()
                self.onError?(SpeechRecognizerError.recognitionFailed(error))
                self.stopRecording()
            } else if isFinal {
                self.clearRecordContext()
                self.stopRecording()
            }
        }

        // 配置音频输入
        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
            self.recognitionRequest?.append(buffer)
            self.analyzeAudioBuffer(buffer)
        }

        audioEngine.prepare()
        do {
            try audioEngine.start()
            startSilenceTimer()
        } catch {
            onError?(SpeechRecognizerError.audioEngineStartFailed(error))
        }
    }
    
    
    // MARK: - 停止录音
    func stopRecording() {
        audioEngine.inputNode.removeTap(onBus: 0)
        audioEngine.stop()
        recognitionTask?.finish() // 停止识别任务
        #if os(iOS)
        do {
           try AVAudioSession.sharedInstance().setActive(false)
            resetSilenceTimer()
            self.onRecordDone?()
        } catch {
            onError?(SpeechRecognizerError.audioSessionDeactivationFailed(error))
            resetSilenceTimer()
            self.onRecordDone?()
        }
        #else
        resetSilenceTimer()
        self.onRecordDone?()
        #endif
    }

    //清除上下文
    func clearRecordContext() {
        recognitionTask = nil
        recognitionRequest = nil
        recognitionRequest?.endAudio()
    }

    // 分析音频缓冲区的平均功率
    private func analyzeAudioBuffer(_ buffer: AVAudioPCMBuffer) {
        guard let format = buffer.format.channelCount > 0 ? buffer.format : nil else { return }

        // 获取音频平均功率
        let level = getAveragePower(for: buffer, format: format)

        // 如果音量高于阈值，认为有语音
        if level > audioLevelThreshold {
            resetSilenceTimer()
        }
    }

    // 计算音频缓冲区的平均功率
    private func getAveragePower(for buffer: AVAudioPCMBuffer, format: AVAudioFormat) -> Float {
        guard let floatChannelData = buffer.floatChannelData else { return -100.0 }

        let channelCount = UInt32(buffer.format.channelCount)
        var sum: Float = 0.0

        for channel in 0..<channelCount {
            let data = floatChannelData[Int(channel)]
            let frameCount = Int(buffer.frameLength)

            for i in 0..<frameCount {
                sum += data[i] * data[i]
            }
        }

        let rms = sqrtf(sum / Float(buffer.frameLength * channelCount))
        let avgPower = 20.0 * log10f(rms) // 转换为 dB
        return avgPower
    }

    // 启动静默计时器：用于判断无声间隔时间
    private func startSilenceTimer() {
        stopSilenceTimer()
        self.lastVoiceTime = Date()
        self.silenceTimer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(self.checkSilence), userInfo: nil, repeats: true)
    }

    // 停止静默计时器
    private func stopSilenceTimer() {
        silenceTimer?.invalidate()
        silenceTimer = nil
    }

    // 重置静默计时器
    private func resetSilenceTimer() {
        lastVoiceTime = Date()
    }

    // 检查是否处于静默状态
    @objc private func checkSilence() {
        guard let lastVoiceTime = lastVoiceTime else { return }

        // 计算无语音持续时间
        let silenceDuration = Date().timeIntervalSince(lastVoiceTime)

        // 如果超过阈值，触发回调
        if silenceDuration >= silenceThreshold {
            stopSilenceTimer()
            stopRecording()
        }
    }

    // MARK: - SFSpeechRecognizerDelegate
    func speechRecognizer(_ speechRecognizer: SFSpeechRecognizer, availabilityDidChange available: Bool) {
        if !available {
            onError?(SpeechRecognizerError.recognizerNotAvailable)
        }
    }

    // MARK: - 自定义错误类型
     enum SpeechRecognizerError: Error, LocalizedError {
        case authorizationDenied
        case unknownAuthorizationStatus
        case recognizerNotAvailable
        case audioSessionSetupFailed(Error)
        case audioEngineStartFailed(Error)
        case audioSessionDeactivationFailed(Error)
        case recognitionFailed(Error)

        var errorDescription: String? {
            switch self {
            case .authorizationDenied:
                return "语音识别权限被拒绝。请在设置中启用麦克风和语音识别权限。"
            case .unknownAuthorizationStatus:
                return "未知的语音识别权限状态。"
            case .recognizerNotAvailable:
                return "语音识别器当前不可用。请检查网络连接或设备设置。"
            case .audioSessionSetupFailed(let error):
                return "音频会话设置失败: \(error.localizedDescription)"
            case .audioEngineStartFailed(let error):
                return "音频引擎启动失败: \(error.localizedDescription)"
            case .audioSessionDeactivationFailed(let error):
                return "音频会话停用失败: \(error.localizedDescription)"
            case .recognitionFailed(let error):
                return "语音识别失败: \(error.localizedDescription)"
            }
        }
    }
}
#endif
