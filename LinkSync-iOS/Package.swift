// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "LinkSync-iOS",
    platforms: [
        .iOS(.v15)
    ],
    products: [
        .library(
            name: "LinkSync-iOS",
            targets: ["LinkSync-iOS"]),
    ],
    dependencies: [
        .package(url: "https://github.com/aws-amplify/amplify-swift", from: "2.0.0")
    ],
    targets: [
        .target(
            name: "LinkSync-iOS",
            dependencies: [
                .product(name: "Amplify", package: "amplify-swift"),
                .product(name: "AWSCognitoAuthPlugin", package: "amplify-swift")
            ]),
        .testTarget(
            name: "LinkSync-iOSTests",
            dependencies: ["LinkSync-iOS"]),
    ]
)
