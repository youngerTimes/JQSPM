// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "JQSPM",

    //支持平台
    platforms: [
        .iOS(.v15)
    ],

    products: [
        .library(name: "JQSPM",targets: ["JQSPM"]),
        .library(name: "JQSPM-UI", targets: ["JQSPM-UI"])
    ],

    dependencies: [
        .package(url: "https://github.com/CoderMJLee/MJRefresh", from: "3.7.1"),
        .package(url: "https://github.com/ReactiveX/RxSwift.git", .upToNextMajor(from: "6.9.0")),
        .package(url: "https://github.com/alibaba/HandyJSON", from: "5.0.2"),
        .package(url: "https://github.com/SDWebImage/SDWebImage.git", from: "5.1.0"),
        .package(url: "https://github.com/stephencelis/SQLite.swift.git", from: "0.15.4")
    ],

    targets: [
        .target(
            name: "JQSPM"
        ),
        .target(
            name: "JQSPM-UI"
        )
    ]
)
