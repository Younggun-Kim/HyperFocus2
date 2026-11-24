//
//  CommonToggle.swift
//  DesignSystem
//
//  Created by 김영건 on 11/24/26.
//

import SwiftUI

public struct CommonToggle: View {
    @Binding private var isOn: Bool
    
    public init(isOn: Binding<Bool>) {
        self._isOn = isOn
    }
    
    public var body: some View {
        Toggle("", isOn: $isOn)
            .labelsHidden()
            .toggleStyle(CommonToggleStyle())
    }
}


#Preview {
    @Previewable @State var isOn = false
    
    CommonToggle(isOn: $isOn)
        .padding()
        .background(Color.black)
}
