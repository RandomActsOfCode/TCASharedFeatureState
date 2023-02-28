// swift-tools-version: 5.7

import PackageDescription

let package = Package(
  name: "SharedState",
  platforms: [.iOS(.v16), .macOS(.v13)],
  products: [
    .library(
      name: "AppFeature",
      targets: ["AppFeature"]
    ),
    .library(
      name: "FooFeaure",
      targets: ["FooFeature"]
    ),
    .library(
      name: "BarFeature",
      targets: ["BarFeature"]
    ),
    .library(
      name: "BazzFeature",
      targets: ["BazzFeature"]
    ),
    .library(
      name: "SharedFeatureStateClient",
      targets: ["SharedFeatureStateClient"]
    ),
  ],
  dependencies: [
    .package(url: "https://github.com/pointfreeco/swift-composable-architecture", from: "0.50.1"),
    .package(url: "https://github.com/pointfreeco/swift-dependencies", from: "0.1.4"),
  ],
  targets: [
    .target(
      name: "AppFeature",
      dependencies: [
        "SharedFeatureStateClient",
        "FooFeature",
        .product(
          name: "ComposableArchitecture",
          package: "swift-composable-architecture"
        ),
        .product(
          name: "Dependencies",
          package: "swift-dependencies"
        ),
      ]
    ),
    .target(
      name: "FooFeature",
      dependencies: [
        "BarFeature",
        .product(
          name: "ComposableArchitecture",
          package: "swift-composable-architecture"
        ),
        .product(
          name: "Dependencies",
          package: "swift-dependencies"
        ),
      ]
    ),
    .target(
      name: "BarFeature",
      dependencies: [
        "BazzFeature",
        "SharedFeatureStateClient",
        .product(
          name: "ComposableArchitecture",
          package: "swift-composable-architecture"
        ),
        .product(
          name: "Dependencies",
          package: "swift-dependencies"
        ),
      ]
    ),
    .target(
      name: "BazzFeature",
      dependencies: [
        "SharedFeatureStateClient",
        .product(
          name: "ComposableArchitecture",
          package: "swift-composable-architecture"
        ),
        .product(
          name: "Dependencies",
          package: "swift-dependencies"
        ),
      ]
    ),
    .target(
      name: "SharedFeatureStateClient",
      dependencies: [
        .product(
          name: "ComposableArchitecture",
          package: "swift-composable-architecture"
        ),
        .product(
          name: "Dependencies",
          package: "swift-dependencies"
        ),
      ]
    ),
  ]
)
