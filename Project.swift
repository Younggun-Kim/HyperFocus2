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
                "com.apple.developer.applesignin": ["Default"],
            ]),
            dependencies: [
                .target(name: "Splash"),
                .target(name: "FocusTimer"),
                .target(name: "SessionLog"),
                .target(name: "Setting"),
                .target(name: "Domain"),
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
                .target(name: "Splash"),
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
        name: "Splash",
        dependencies: [.target(name: "DesignSystem")]
    )
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
            .target(name: "BaseFeature"),
            .target(name: "Domain"),
            .target(name: "DesignSystem"),
        ],
    )
    + [
        // Feature들이 함께 쓰는 화면 계층 코드. 화면이 없어 Example 없이 module로 만든다.
        .module(
            name: "BaseFeature",
            path: "./Modules/Features/BaseFeature",
            dependencies: [
                .target(name: "Domain"),
                .external(name: "ComposableArchitecture"),
            ]
        ),
        .moduleTests(
            name: "BaseFeature",
            path: "./Modules/Features/BaseFeature",
            dependencies: [
                .target(name: "Domain"),
                .external(name: "ComposableArchitecture"),
            ]
        ),


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
                .external(name: "Dependencies"),
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
                .external(name: "Alamofire"),
            ]
        ),
        .moduleTests(
            name: "CoreNetwork",
            path: "./Modules/Core/CoreNetwork"
        ),
        .module(
            name: "DesignSystem",
            path: "./Modules/Core/DesignSystem",
            hasResources: true
        ),
    ]
)
