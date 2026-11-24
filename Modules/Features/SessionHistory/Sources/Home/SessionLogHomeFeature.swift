//
//  SessionLogHomeFeature.swift
//  CoreNetwork
//
//  Created by 김영건 on 11/24/26.
//

import ComposableArchitecture
import Foundation

@Reducer
public struct SessionLogHomeFeature {
    @ObservableState
    public struct State: Equatable {
        
        public init() {}
    }
    
    public enum Action: Equatable {}
    
    
    
    public init() {}
    
    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            default:
                break
            }
        }
    }
}
