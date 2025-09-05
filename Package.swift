// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "JQSPM",

    //支持平台
    platforms: [
        .iOS(.v15),
        .macOS(.v10_15)
    ],

    /**
     【products】定义此包输出的产品，供其他项目使用：
     .library 表示构建成静态库或动态库；
     .targets 指定由哪些目标组成这个库。
     */

    products: [
        .library(
            name: "JQSPM",
            targets: ["JQSPM"]),
        .library(
            name: "JQSPM-UI",
            targets: ["JQSPM-UI"])
    ],

    //指定依赖的外部 Swift 包
    dependencies: [
//        .package(url: "https://github.com/krzyzanowskim/CryptoSwift.git", from: "1.8.3"),
//        .package(url: "https://github.com/stephencelis/SQLite.swift.git", from: "0.15.4")
    ],

    //target 是构建的最小单元，通常与 Sources/ 和 Tests/ 目录对应
    targets: [
        .target(
            name: "JQSPM"),
        .target(
            name: "JQSPM-UI",
            dependencies: ["JQSPM"]
        ),
        .testTarget(
            name: "JQSPMTests",
            dependencies: ["JQSPM","JQSPM-UI"]
        ),
    ]
)
