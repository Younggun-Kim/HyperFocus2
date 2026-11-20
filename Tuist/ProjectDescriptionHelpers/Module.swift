import ProjectDescription

/// 모든 타깃이 공유하는 값
public enum Module {
    public static let deploymentTargets: DeploymentTargets = .iOS("18.0")
    public static let bundleIdPrefix = "com.hyperfocus.timer"
}

extension Target {
    /// `Modules/` 아래의 정적 프레임워크 모듈 (Core, Domain, Data 등)
    public static func module(
        name: String,
        path: String,
        dependencies: [TargetDependency] = []
    ) -> Target {
        .target(
            name: name,
            destinations: .iOS,
            product: .staticFramework,
            bundleId: "\(Module.bundleIdPrefix).\(name.lowercased())",
            deploymentTargets: Module.deploymentTargets,
            infoPlist: .default,
            buildableFolders: [.folder("\(path)/Sources")],
            dependencies: dependencies
        )
    }

    /// Feature 하나 = 프레임워크 + Example 앱 + 테스트 (TMA)
    ///
    /// - Feature는 ComposableArchitecture를 기본으로 의존한다.
    /// - Example과 Tests는 Feature와 그 의존성까지 선언한다.
    ///   mock 주입(`prepareDependencies`, `TestStore`)에서 Domain의 Entity·UseCase·Repository 포트를 직접 import하기 때문이다.
    /// - Feature의 의존성에 Data를 넣지 않는다. Data는 App만 링크한다.
    public static func feature(
        name: String,
        dependencies: [TargetDependency] = []
    ) -> [Target] {
        let path = "./Modules/Features/\(name)"
        let bundleId = "\(Module.bundleIdPrefix).feature.\(name.lowercased())"
        let featureDependencies = dependencies + [.external(name: "ComposableArchitecture")]
        let consumerDependencies = [TargetDependency.target(name: name)] + featureDependencies
        return [
            .target(
                name: name,
                destinations: .iOS,
                product: .staticFramework,
                bundleId: bundleId,
                deploymentTargets: Module.deploymentTargets,
                infoPlist: .default,
                buildableFolders: [.folder("\(path)/Sources")],
                dependencies: featureDependencies
            ),
            .target(
                name: "\(name)Example",
                destinations: .iOS,
                product: .app,
                bundleId: "\(bundleId).example",
                deploymentTargets: Module.deploymentTargets,
                infoPlist: .extendingDefault(with: [
                    "UILaunchScreen": ["UIColorName": "", "UIImageName": ""],
                ]),
                buildableFolders: [.folder("\(path)/Example")],
                dependencies: consumerDependencies
            ),
            .target(
                name: "\(name)Tests",
                destinations: .iOS,
                product: .unitTests,
                bundleId: "\(bundleId).tests",
                deploymentTargets: Module.deploymentTargets,
                infoPlist: .default,
                buildableFolders: [.folder("\(path)/Tests")],
                dependencies: consumerDependencies
            ),
        ]
    }
}
