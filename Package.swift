// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "TwoFactorAuth",
    platforms: [
        .macOS(.v12)
    ],
    products: [
        .library(name: "TwoFactorAuth", targets: ["TwoFactorAuth"]),
        .executable(name: "totp", targets: ["totp"])
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-crypto.git", from: "3.0.0")
    ],
    targets: [
        .target(
            name: "TwoFactorAuth",
            dependencies: [
                .product(name: "Crypto", package: "swift-crypto")
            ]
        ),
        .executableTarget(
            name: "totp",
            dependencies: ["TwoFactorAuth"]
        ),
        .testTarget(
            name: "TwoFactorAuthTests",
            dependencies: ["TwoFactorAuth"]
        )
    ]
)
