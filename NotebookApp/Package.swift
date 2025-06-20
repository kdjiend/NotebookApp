//
//  Package.swift
//  NotebookApp
//
//  Created by Irui Li on 2025/6/19.
//

// swift-tools-version:5.5

let package = Package(
  name: "NotebookApp",
  platforms: [.macOS(.v12)],
  dependencies: [
    .package(url: "https://github.com/jedisct1/swift-sodium.git", .upToNextMajor(from: "0.9.1")),
  ],
  targets: [
    .target(name: "NotebookApp", dependencies: ["Sodium"])
  ]
)
