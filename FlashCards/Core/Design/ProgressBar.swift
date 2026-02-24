//
//  ProgressBar.swift
//  FlashCards
//

internal import SwiftUI

struct ProgressBar: View {
    let progress: Double // 0...1
    var height: CGFloat = 4
    var cornerRadius: CGFloat = 2

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(Color.primary.opacity(0.12))
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(Color("PrimaryColor"))
                    .frame(width: max(0, geo.size.width * CGFloat(min(1, max(0, progress)))))
            }
        }
        .frame(height: height)
    }
}

#Preview {
    VStack(spacing: 16) {
        ProgressBar(progress: 0.78)
        ProgressBar(progress: 0.3)
        ProgressBar(progress: 1)
    }
    .padding()
    .frame(width: 200)
}
