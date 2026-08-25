// swift-tools-version: 5.7

import PackageDescription

let package = Package(
  name: "keyclean",
  platforms: [
    .macOS(.v13)
  ],
  products: [
    // Keep the build product distinct from KeyClean.app on the default
    // case-insensitive macOS filesystem. The bundle step installs it as
    // the public `keyclean` command.
    .executable(name: "keyclean-cli", targets: ["KeyCleanCLI"]),
    .executable(name: "KeyCleanSafe", targets: ["KeyCleanSafeApp"]),
    .executable(name: "KeyCleanFull", targets: ["KeyCleanFullApp"]),
  ],
  targets: [
    .target(name: "KeyCleanCore"),
    .target(
      name: "KeyCleanUI",
      dependencies: ["KeyCleanCore"]
    ),
    .executableTarget(
      name: "KeyCleanCLI",
      dependencies: ["KeyCleanCore"]
    ),
    .executableTarget(
      name: "KeyCleanSafeApp",
      dependencies: ["KeyCleanCore", "KeyCleanUI"]
    ),
    .executableTarget(
      name: "KeyCleanFullApp",
      dependencies: ["KeyCleanCore", "KeyCleanUI"]
    ),
    .testTarget(
      name: "KeyCleanCoreTests",
      dependencies: ["KeyCleanCore"]
    ),
  ]
)
