import Dependencies
import Domain

public enum DataModule {
    /// 앱 진입점(`HyperFocusApp.init`)에서 Store를 만들기 전에 한 번 호출한다.
    ///
    /// swift-dependencies는 `liveValue`를 런타임 conformance 조회로 찾기 때문에,
    /// 코드에서 직접 참조하지 않으면 링커가 Data의 구현 파일을 바이너리에 넣지 않는다.
    /// 여기서 각 Repository의 `liveValue`를 하나씩 명시해 링크와 등록을 함께 보장한다.
    /// 빈 함수로는 안 된다. 새 Repository를 추가하면 반드시 이 목록에도 추가한다.
    public static func bootstrap() {
        prepareDependencies {
            $0.sampleRepository = SampleRepository.liveValue
            $0.settingRepository = SettingRepository.liveValue
            $0.feedbackRepository = FeedbackRepository.liveValue
            $0.authRepository = AuthRepository.liveValue
            $0.appVersionRepository = AppVersionRepository.liveValue
        }
    }
}
