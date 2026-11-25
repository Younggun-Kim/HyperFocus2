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
                    "API_BASE_URL": "$(API_BASE_URL)",
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
                .target(name: "SessionLog"),
                .target(name: "Setting"),
                .target(name: "Data"),
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
                .target(name: "FocusTimer"),
                .target(name: "SessionLog"),
                .target(name: "Setting"),
                .target(name: "Domain"),
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
        dependencies: [.target(name: "Util")]
    )
    + Target.feature(
        name: "SessionLog",
        dependencies: [
            .target(name: "Domain"),
            .target(name: "DesignSystem"),
        ],
    )
    + Target.feature(
        name: "Setting",
        dependencies: [
            .target(name: "Domain"),
            .target(name: "DesignSystem"),
        ],
    )
    + [
        // MARK: - Domain
        // 내부 모듈에 의존하지 않는다. Entity, Repository 포트, UseCase
        .module(
            name: "Domain",
            path: "./Modules/Domain",
            dependencies: [
                .external(name: "Dependencies"),
                .external(name: "DependenciesMacros"),
            ]
        ),
        .moduleTests(
            name: "Domain",
            path: "./Modules/Domain",
            dependencies: [
                .external(name: "Dependencies"),
            ]
        ),
        
        // MARK: - Data
        // Domain의 Repository 포트를 구현한다. App만 링크하고 bootstrap()으로 등록
        .module(
            name: "Data",
            path: "./Modules/Data",
            dependencies: [
                .target(name: "Domain"),
                .target(name: "CoreNetwork"),
                .external(name: "Dependencies"),
            ]
        ),
        .moduleTests(
            name: "Data",
            path: "./Modules/Data",
            dependencies: [
                .target(name: "Domain"),
                .target(name: "CoreNetwork"),
            ]
        ),
        
        // MARK: - Core
        .module(
            name: "Util",
            path: "./Modules/Core/Util"
        ),
        .module(
            name: "CoreNetwork",
            path: "./Modules/Core/CoreNetwork",
            dependencies: [
                .external(name: "Moya"),
                .external(name: "Alamofire"),
            ]
        ),
        .moduleTests(
            name: "CoreNetwork",
            path: "./Modules/Core/CoreNetwork",
            dependencies: [
                .external(name: "Moya"),
            ]
        ),
        .module(
            name: "DesignSystem",
            path: "./Modules/Core/DesignSystem",
            hasResources: true
        ),
    ]
)
