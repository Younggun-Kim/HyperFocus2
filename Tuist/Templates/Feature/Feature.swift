//
//  Feature.swift
//  Manifests
//
//  Created by 김영건 on 11/19/26.
//

import ProjectDescription

let nameAttribute: Template.Attribute = .required("name")

let template = Template(
    description: "TMA Feature 모듈 (Sources, Example, Tests)",
    attributes: [
        nameAttribute,
    ],
    items: [
        .file(
            path: "Modules/Features/\(nameAttribute)/Sources/\(nameAttribute)Feature.swift",
            templatePath: "Feature.stencil"
        ),
        .file(
            path: "Modules/Features/\(nameAttribute)/Sources/\(nameAttribute)View.swift",
            templatePath: "View.stencil"
        ),
        .file(
            path: "Modules/Features/\(nameAttribute)/Example/\(nameAttribute)ExampleApp.swift",
            templatePath: "ExampleApp.stencil"
        ),
        .file(
            path: "Modules/Features/\(nameAttribute)/Tests/\(nameAttribute)FeatureTests.swift",
            templatePath: "Tests.stencil"
        ),
    ]
)
