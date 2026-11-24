//
//  Core.swift
//  Config
//
//  Created by 김영건 on 11/24/26.
//

import Foundation
import ProjectDescription

let nameAttribute: Template.Attribute = .required("name")

let template = Template(
    description: "Core 모듈 (Sources, Tests)",
    attributes: [
        nameAttribute,
    ],
    items: [
        .file(
            path: "Modules/Core/\(nameAttribute)/Sources/\(nameAttribute)Core.swift",
            templatePath: "Core.stencil"
        ),
    ]
)
