// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "FaceRecognitionClient",
    platforms: [
        .iOS(.v15)
    ],
    products: [
        .library(
            name: "FaceRecognitionClient",
            targets: ["FaceRecognitionClient"]),
    ],
    dependencies: [
        .package(url: "https://github.com/firebase/firebase-ios-sdk.git", from: "10.0.0")
    ],
    targets: [
        .target(
            name: "FaceRecognitionClient",
            dependencies: [
                .product(name: "FirebaseAuth", package: "firebase-ios-sdk"),
                .product(name: "FirebaseFirestore", package: "firebase-ios-sdk"),
                .product(name: "FirebaseStorage", package: "firebase-ios-sdk")
            ]),
        .testTarget(
            name: "FaceRecognitionClientTests",
            dependencies: ["FaceRecognitionClient"]),
    ]
)
