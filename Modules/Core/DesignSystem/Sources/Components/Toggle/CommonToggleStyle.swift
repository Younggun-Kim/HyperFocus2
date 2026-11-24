//
//  CommonToggleStyle.swift
//  DesignSystem
//
//  Created by 김영건 on 11/24/26.
//

import Foundation
import SwiftUI

struct CommonToggleStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        Capsule()
            .fill(
                configuration.isOn
                ? Color(red: 60 / 255, green: 211 / 255, blue: 254 / 255)
                : Color(red: 120 / 255, green: 120 / 255, blue: 128 / 255, opacity: 0.32)
            )
            .frame(width: 64, height: 28)
            .overlay(alignment: configuration.isOn ? .trailing : .leading) {
                Capsule()
                    .fill(Color.black)
                    .frame(width: 39, height: 24)
                    .padding(2)
            }
            .animation(.snappy(duration: 0.2), value: configuration.isOn)
            .onTapGesture { configuration.isOn.toggle() }
    }
}
