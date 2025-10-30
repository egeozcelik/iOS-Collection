import SwiftUI
struct AnimatedAuroraBackground: View {
    @State private var time: CGFloat = 0
    
    var body: some View {
        TimelineView(.animation) { timeline in
            let now = timeline.date.timeIntervalSinceReferenceDate
            Canvas { context, size in
                let center = CGPoint(x: size.width / 2, y: size.height / 2)
                
                for i in 0..<5 {
                    let progress = time + CGFloat(i) * 1.2
                    let x = center.x + sin(progress * 0.6 + CGFloat(i)) * size.width * 0.3
                    let y = center.y + cos(progress * 0.8 + CGFloat(i) * 1.5) * size.height * 0.3
                    let radius = 200 + 50 * sin(progress * 1.3 + CGFloat(i) * 2)
                    
                    var path = Path()
                    path.addEllipse(in: CGRect(x: x - radius/2, y: y - radius/2, width: radius, height: radius))
                    
                    context.fill(path, with: .color(Color.black.opacity(0.25)))
                    context.addFilter(.blur(radius: 60))
                    context.fill(path, with: .color(Color.gray.opacity(0.2)))
                }
            }
            .onChange(of: now) { newValue in
                time = CGFloat(newValue)
            }
        }
        .ignoresSafeArea()
        .background(Color.black)
    }
}

struct ContentView: View {
    var body: some View {
        ZStack {
            AnimatedAuroraBackground()
            VStack {
                Text("Welcome to")
                    .font(.title)
                    .foregroundColor(.white)
                    .fontWeight(.ultraLight)
                Text("RÚNE")
                    .font(.largeTitle)
                    .fontWeight(.light)
                    .foregroundColor(.white)
            }
        }
    }
}

#Preview {
    ContentView()
}
