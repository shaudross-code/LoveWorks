import SwiftUI

/// Picture guide showing exactly where to measure (swipe or use the arrows).
struct MeasureGuideView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var index: Int

    init(startKey: String) {
        _index = State(initialValue: MeasureGuide.index(of: startKey))
    }

    private var item: MeasureGuideItem { MeasureGuide.items[index] }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    ZStack {
                        Image(item.imageName)
                            .resizable()
                            .aspectRatio(1, contentMode: .fit)
                            .frame(maxWidth: .infinity)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .accessibilityLabel("Where to measure \(item.title.lowercased())")
                        HStack {
                            arrow("chevron.left", -1)
                            Spacer()
                            arrow("chevron.right", 1)
                        }
                        .padding(.horizontal, 8)
                    }
                    .gesture(DragGesture(minimumDistance: 30).onEnded { v in
                        if v.translation.width < -40 { go(1) } else if v.translation.width > 40 { go(-1) }
                    })

                    Label("How to measure · \(index + 1) of \(MeasureGuide.items.count)", systemImage: "ruler")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(Theme.primary)
                        .textCase(.uppercase)

                    Text(item.title)
                        .font(.system(size: 26, weight: .bold))
                        .foregroundStyle(Theme.textMain)

                    Text(item.tip)
                        .font(.system(size: 15))
                        .foregroundStyle(Theme.textMuted)
                        .lineSpacing(3)

                    HStack(spacing: 6) {
                        ForEach(Array(MeasureGuide.items.enumerated()), id: \.element.key) { i, g in
                            Button { withAnimation { index = i } } label: {
                                Capsule()
                                    .fill(i == index ? Theme.primary : Color.zinc)
                                    .frame(width: i == index ? 24 : 8, height: 6)
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel(g.title)
                        }
                    }
                }
                .padding(20)
            }
            .background(Theme.background.ignoresSafeArea())
            .navigationTitle("Measurement guide")
            .inlineNavigationTitle()
            .toolbar {
                ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } }
            }
        }
        .presentationDetents([.large])
    }

    private func arrow(_ icon: String, _ delta: Int) -> some View {
        Button { go(delta) } label: {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .semibold))
                .frame(width: 40, height: 40)
                .background(.black.opacity(0.6))
                .foregroundStyle(Theme.textMain)
                .clipShape(Circle())
                .overlay(Circle().stroke(Theme.border, lineWidth: 1))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(delta < 0 ? "Previous" : "Next")
    }

    private func go(_ delta: Int) {
        let n = MeasureGuide.items.count
        withAnimation(.easeInOut(duration: 0.2)) { index = (index + delta + n) % n }
    }
}
