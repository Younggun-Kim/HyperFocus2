import SwiftUI
import Utils

public struct ContentView: View {
    private var formattedTime = TimeFormatter.minuteSecond(from: 5400)
    
    public init() {}

    public var body: some View {
        Text("Hello, World!, \(formattedTime)")
            .padding()
    }
}


struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
