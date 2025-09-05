//
//  File.swift
//  JQSPM
//
//  Created by 无故事王国 on 2024/11/26.
//

import OSLog

@available(macOS 10.15, iOS 13.0, *)
@MainActor final class JQLog{

    struct JQLogConfig {
        //日志文件路径
        var logFilePath:URL
        //日志文件名
        var projectName:String
        //是否创建日志文件夹
        var createLogDirectory:Bool = true
        //异常上报地址
        var exceptionReportURL:URL?
        var enable = true
    }

    private static var _sharedInstance: JQLog?
    private var config:JQLogConfig!

    public class func instance(enable:Bool) -> JQLog {
        guard let instance = _sharedInstance else {
            _sharedInstance = JQLog()

            let projectName = Bundle.main.infoDictionary?["CFBundleName"] as? String

            //创建当日日志文件，如果文件不存在，则创建
            let date = Date()
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            let dateString = formatter.string(from: date)
            let logFilePath = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!.appendingPathComponent("Logs/\(dateString).log")

            _sharedInstance?.config = JQLogConfig(logFilePath: logFilePath, projectName:projectName ?? "PROJECT")

            Task(priority: .background) {
                do{
                    //清理超过30天的日志
                    let fileManager = FileManager.default
                    let logDirectory = logFilePath.deletingLastPathComponent()
                    let logFiles = try? fileManager.contentsOfDirectory(at: logDirectory, includingPropertiesForKeys: nil)
                    let thirtyDaysAgo = Date(timeIntervalSinceNow: -30 * 24 * 60 * 60)
                    for logFile in logFiles ?? [] {
                        if logFile.creationDate! < thirtyDaysAgo {
                            try? fileManager.removeItem(at: logFile)
                        }
                    }
                }
            }

            //异常崩溃监听
            NSSetUncaughtExceptionHandler { (v) in
                let crashInfo = String(format: "===========异常崩溃===========\n%@\n=============\n%@\n", v.name.rawValue,v.reason ?? "")
                JQLog.instance(enable: true).writeLog(crashInfo, separator: "\n")
            }
            return _sharedInstance!
        }
        return instance
    }

    func success(_ items:Any...,separator:String="\n",file:String=#file,function:String=#function,line:Int=#line){
        guard config.enable else {return}
        if #available(iOS 14.0, *,macOS 11.0, *) {
            let logger = Logger(subsystem: config.projectName, category: Thread.current.name ?? "main")
            logger.debug("\(file)｜line：\(line)\n\(items)")
        }else{
            let file = (file as NSString).lastPathComponent.split(separator: ".").first!;
            print("✅✅✅ SUCCESS: \(file)  \(function) [Line: \(line)]: \(items)",separator);
        }
        writeLog(items,separator: separator,file: file,function: function,line: line)
    }

    func error(_ items:Any...,separator:String="\n",file:String=#file,function:String=#function,line:Int=#line){
        guard config.enable else {return}
        if #available(iOS 14.0, *,macOS 11.0, *) {
            let logger = Logger(subsystem: config.projectName, category:  Thread.current.name ?? "main")
            logger.error("\(items)")
        }else{
            let file = (file as NSString).lastPathComponent.split(separator: ".").first!;
            print("❌❌❌ ERROR: \(file)  \(function) [Line: \(line)]: \(items)",separator);
        }
        writeLog(items,separator: separator,file: String(file),function: function,line: line)
    }

    func carch(_ items:Any...,separator:String="\n",file:String=#file,function:String=#function,line:Int=#line){
        guard config.enable else {return}
        if #available(iOS 14.0, *,macOS 11.0, *) {
            let logger = Logger(subsystem: config.projectName, category:Thread.current.name ?? "main")
            logger.error("\(items)")
        }else{
            let file = (file as NSString).lastPathComponent.split(separator: ".").first!;
            print("☠️☠️☠️ Carsh: \(file)  \(function) [Line: \(line)]: \(items)",separator);
        }
        writeLog(items,separator: separator,file: String(file),function: function,line: line)
    }

    func debug(_ items:Any...,separator:String="\n",file:String=#file,function:String=#function,line:Int=#line){
        guard config.enable else {return}
        if #available(iOS 14.0, *,macOS 11.0, *) {
            let logger = Logger(subsystem: config.projectName, category:Thread.current.name ?? "main")
            logger.debug("\(items)")
        }else{
            let file = (file as NSString).lastPathComponent.split(separator: ".").first!;
            print("❕❕❕ DEBUG: \(file)  \(function) [Line: \(line)]: \(items)",separator);
        }
        writeLog(items,separator: separator,file: String(file),function: function,line: line)
    }

    func info(_ items:Any...,separator:String="\n",file:String=#file,function:String=#function,line:Int=#line){
        guard config.enable else {return}
        if #available(iOS 14.0, *,macOS 11.0, *) {
            let logger = Logger(subsystem: config.projectName, category:Thread.current.name ?? "main")
            logger.error("\(items)")
        }else{
            let file = (file as NSString).lastPathComponent.split(separator: ".").first!;
            print("⚠️⚠️⚠️INFO: \(file)  \(function) [Line: \(line)]: \(items)",separator);
        }
        writeLog(items,separator: separator,file: String(file),function: function,line: line)
    }

    func trace(_ items:Any...,separator:String="\n",file:String=#file,function:String=#function,line:Int=#line){
        guard config.enable else {return}
        if #available(iOS 14.0, *,macOS 11.0, *) {
            let logger = Logger(subsystem: config.projectName, category:Thread.current.name ?? "main")
            logger.trace("\(items)")
        }else{
            let file = (file as NSString).lastPathComponent.split(separator: ".").first!;
            print("⚠️⚠️⚠️TRACE: \(file)  \(function) [Line: \(line)]: \(items)",separator);
        }
        writeLog(items,separator: separator,file: String(file),function: function,line: line)
    }

    func warning(_ items:Any...,separator:String="\n",file:String=#file,function:String=#function,line:Int=#line){
        guard config.enable else {return}
        if #available(iOS 14.0, *,macOS 11.0, *) {
            let logger = Logger(subsystem: config.projectName, category:Thread.current.name ?? "main")
            logger.warning("\(items)")
        }else{
            let file = (file as NSString).lastPathComponent.split(separator: ".").first!;
            print("⚠️⚠️⚠️WARNING: \(file)  \(function) [Line: \(line)]: \(items)",separator);
        }
        writeLog(items,separator: separator,file: String(file),function: function,line: line)
    }

    func notice(_ items:Any...,separator:String="\n",file:String=#file,function:String=#function,line:Int=#line){
        guard config.enable else {return}
        if #available(iOS 14.0, *,macOS 11.0, *) {
            let logger = Logger(subsystem: config.projectName, category:Thread.current.name ?? "main")
            logger.notice("\(items)")
        }else{
            let file = (file as NSString).lastPathComponent.split(separator: ".").first!;
            print("⚠️⚠️⚠️NOTICE: \(file)  \(function) [Line: \(line)]: \(items)",separator);
        }
        writeLog(items,separator: separator,file: String(file),function: function,line: line)
    }

    func critical(_ items:Any...,separator:String="\n",file:String=#file,function:String=#function,line:Int=#line){
        guard config.enable else {return}
        if #available(iOS 14.0, *,macOS 11.0, *) {
            let logger = Logger(subsystem: config.projectName, category:Thread.current.name ?? "main")
            logger.critical("\(items)")
        }else{
            let file = (file as NSString).lastPathComponent.split(separator: ".").first!;
            print("⚠️⚠️⚠️CRITICAL: \(file)  \(function) [Line: \(line)]: \(items)",separator);
        }
        writeLog(items,separator: separator,file: String(file),function: function,line: line)
    }

    private func writeLog(_ items:Any...,separator:String="\n",file:String=#file,function:String=#function,line:Int=#line){
        //写入日志
        let logString = items.map{ "\($0)" }.joined(separator: separator)
        let logMessage = "\(logString)\n"
        do{
            try logMessage.write(to: config.logFilePath, atomically: true, encoding: .utf8)
        }catch{
            print("写入日志失败: \(error)")
        }
    }

    //清理全部日志
    func clearAllLogs(){
        let fileManager = FileManager.default
        let logDirectory = config.logFilePath.deletingLastPathComponent()
        try? fileManager.removeItem(at: logDirectory)
    }
}

private extension URL{
    var creationDate:Date?{
        return (try? resourceValues(forKeys: [.creationDateKey]))?.creationDate
    }
}

