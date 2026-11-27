import ComposableArchitecture

extension AlertState where Action == RootFeature.Alert {
    /// 강제 업데이트 알림. 닫는 버튼이 없어 업데이트하기 전에는 들어갈 수 없다.
    static var requiredUpdate: Self {
        AlertState {
            TextState("Update Required")
        } actions: {
            ButtonState(action: .updateTapped) { TextState("Update") }
        } message: {
            TextState("A new version of HyperFocus is available. Please update to keep using the app.")
        }
    }

    /// 권장 업데이트 알림. 나중에 하면 지금 버전으로 들어간다.
    static var optionalUpdate: Self {
        AlertState {
            TextState("Update Available")
        } actions: {
            ButtonState(action: .updateTapped) { TextState("Update") }
            ButtonState(role: .cancel, action: .laterTapped) { TextState("Later") }
        } message: {
            TextState("A new version of HyperFocus is available. Would you like to update now?")
        }
    }
}
