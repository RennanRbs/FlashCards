//
//  ConfettiView.swift
//  FlashCards
//

internal import SwiftUI

struct ConfettiView: View {
    @State private var particles: [ConfettiParticle] = []
    @State private var appeared = false

    var body: some View {
        GeometryReader { geo in
            ZStack {
                ForEach(particles) { p in
                    Circle()
                        .fill(p.color)
                        .frame(width: p.size, height: p.size)
                        .position(
                            x: p.x * geo.size.width,
                            y: appeared ? p.y * geo.size.height : -10
                        )
                        .opacity(appeared ? 0.8 : 0)
                }
            }
            .onAppear {
                let colors: [Color] = [
                    Color("PrimaryColor"),
                    Color("SuccessColor"),
                    Color("ErrorColor").opacity(0.8),
                ]
                particles = (0..<24).map { _ in
                    ConfettiParticle(
                        x: CGFloat.random(in: 0.1...0.9),
                        y: CGFloat.random(in: 0.3...1.0),
                        size: CGFloat.random(in: 4...10),
                        color: colors.randomElement() ?? .gray
                    )
                }
                withAnimation(.easeOut(duration: 0.6)) {
                    appeared = true
                }
            }
        }
    }
}

private struct ConfettiParticle: Identifiable {
    let id = UUID()
    let x: CGFloat
    let y: CGFloat
    let size: CGFloat
    let color: Color
}

#Preview {
    ConfettiView()
        .frame(height: 100)
}
