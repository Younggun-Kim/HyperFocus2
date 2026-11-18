import ProjectDescription
import ProjectDescriptionHelpers

let project = Project(
    name: "HyperFocus",
    targets: [
        // MARK: - App
        .target(
            name: "HyperFocus",
            destinations: .iOS,
            product: .app,
            bundleId: Module.bundleIdPrefix,
            deploymentTargets: Module.deploymentTargets,
            infoPlist: .extendingDefault(
                with: [
                    "UILaunchScreen": [
                        "UIColorName": "",
                        "UIImageName": "",
                    ],
                    "CFBundleDisplayName": "$(APP_DISPLAY_NAME)",
                ]
            ),
            buildableFolders: [
                "./App/Sources",
                "./App/Resources",
            ],
            entitlements: .dictionary([
                "com.apple.security.application-groups": ["$(APP_GROUP_ID)"],
            ]),
            dependencies: [
                .target(name: "FocusTimer"),
                .target(name: "SessionHistory"),
                .external(name: "ComposableArchitecture"),
            ],
            settings: .settings(
                configurations: [
                    .debug(name: .debug, xcconfig: "./App/Configs/Debug.xcconfig"),
                    .release(name: .release, xcconfig: "./App/Configs/Release.xcconfig"),
                ]
            ),
        ),
        .target(
            name: "HyperFocusTests",
            destinations: .iOS,
            product: .unitTests,
            bundleId: "\(Module.bundleIdPrefix).tests",
            deploymentTargets: Module.deploymentTargets,
            infoPlist: .default,
            buildableFolders: [
                "./App/Tests"
            ],
            dependencies: [
                .target(name: "HyperFocus"),
                .target(name: "Data"),
                .external(name: "ComposableArchitecture"),
            ]
        ),
        .target(
            name: "HyperFocusUITests",
            destinations: .iOS,
            product: .uiTests,
            bundleId: "\(Module.bundleIdPrefix).uitests",
            deploymentTargets: Module.deploymentTargets,
            infoPlist: .default,
            buildableFolders: [
                "./App/UITests"
            ],
            dependencies: [.target(name: "HyperFocus")]
        ),

        // MARK: - Features
    ]
    + Target.feature(
        name: "FocusTimer",
        dependencies: [.target(name: "Utils")]
    )
    + Target.feature(
        name: "SessionHistory",
        dependencies: [.target(name: "Data")]
    )
    + [
        // MARK: - Data
        .module(
            name: "Data",
            path: "./Modules/Data",
            dependencies: [
                .external(name: "Dependencies"),
                .external(name: "DependenciesMacros"),
            ]
        ),

        // MARK: - Core
        .module(
            name: "Utils",
            path: "./Modules/Core/Utils"
        ),
    ]
)
