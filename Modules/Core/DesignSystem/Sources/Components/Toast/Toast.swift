import SwiftUI

public extension View {
    /// 화면 아래에 잠깐 떠 있다가 사라지는 안내.
    ///
    /// `message`가 nil이 아니면 보이고, `duration`이 지나면 바인딩에 nil을 넣는다.
    /// 상태는 바인딩 주인(Reducer)이 가지고, 사라지는 시점만 뷰가 정한다.
    func toast(message: Binding<String?>, duration: Duration = .seconds(2)) -> some View {
        modifier(ToastModifier(message: message, duration: duration))
    }
}

struct ToastModifier: ViewModifier {
    @Binding var message: String?
    let duration: Duration

    func body(content: Content) -> some View {
        content
            .overlay(alignment: .bottom) {
                if let message {
                    ToastLabel(message: message)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                        // 다른 문구로 바뀌면 시간을 다시 잰다. 뷰가 사라지면 Task도 취소된다.
                        .task(id: message) {
                            try? await Task.sleep(for: duration)
                            guard !Task.isCancelled else { return }
                            self.message = nil
                        }
                }
            }
            .animation(.easeInOut, value: message)
    }
}

struct ToastLabel: View {
    let message: String

    var body: some View {
        Text(message)
            .font(.body)
            // 파란 배경 위라 테마와 상관없이 흰색으로 둔다.
            .foregroundStyle(.white)
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(DesignSystemAsset.Colors.systemBlue.swiftUIColor, in: Capsule())
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
            .accessibilityAddTraits(.isStaticText)
    }
}

#Preview {
    @Previewable @State var message: String? = "Message received! Thanks. 💌"

    Button("Show toast") { message = "Message received! Thanks. 💌" }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(DesignSystemAsset.Colors.bgPrimary.swiftUIColor)
        .toast(message: $message)
}
