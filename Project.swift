import ProjectDescription

let deploymentTargets: DeploymentTargets = .iOS("18.0")

let project = Project(
    name: "HyperFocus",
    targets: [
        .target(
            name: "HyperFocus",
            destinations: .iOS,
            product: .app,
            bundleId: "com.hyperfocus.timer",
            deploymentTargets: deploymentTargets,
            infoPlist: .extendingDefault(
                with: [
                    "UILaunchScreen": [
                        "UIColorName": "",
                        "UIImageName": "",
                    ],
                ]
            ),
            buildableFolders: [
                "./Sources",
                "./Resources",
            ],
            dependencies: []
        ),
        .target(
            name: "HyperFocusTests",
            destinations: .iOS,
            product: .unitTests,
            bundleId: "com.hyperfocus.timer.tests",
            deploymentTargets: deploymentTargets,
            infoPlist: .default,
            buildableFolders: [
                "./Tests"
            ],
            dependencies: [.target(name: "HyperFocus")]
        ),
    ]
)
