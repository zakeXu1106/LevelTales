import SwiftUI

struct WelcomeView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Image(systemName: "book.closed.fill")
                    .font(.largeTitle)
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(.indigo)
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 8) {
                    Text("LevelTales")
                        .font(.system(.largeTitle, design: .serif, weight: .bold))
                        .accessibilityAddTraits(.isHeader)

                    Text("Stories at exactly your child's reading level.")
                        .font(.title2)
                }

                VStack(alignment: .leading, spacing: 12) {
                    Label("按孩子的英语级别生成故事", systemImage: "text.book.closed")
                    Label("故事优先在设备上生成，学习记录保存在本机", systemImage: "iphone")
                    Label("一次买断，无订阅", systemImage: "checkmark.circle")
                }

                Text("无需账号，不收集孩子的数据。")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding(24)
            .frame(maxWidth: 460, alignment: .leading)
            .frame(maxWidth: .infinity)
        }
    }
}
