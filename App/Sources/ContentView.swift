import Dependencies
import Domain
import SwiftUI
import Utils

public struct ContentView: View {
    @Dependency(\.sampleRepository) private var sampleRepository

    @State private var sampleStatus = "불러오는 중"
    private var formattedTime = TimeFormatter.minuteSecond(from: 5400)

    public init() {}

    public var body: some View {
        VStack(spacing: 8) {
            Text("Hello, World!, \(formattedTime)")
            Text(sampleStatus)
        }
        .padding()
        .task {
            do {
                let samples = try await sampleRepository.getSamples()
                sampleStatus = "liveValue OK: \(samples.count)개"
            } catch {
                sampleStatus = "liveValue 실패: \(error)"
            }
        }
    }
}


struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
