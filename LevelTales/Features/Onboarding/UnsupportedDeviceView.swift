import SwiftUI

struct UnsupportedDeviceView: View {
    var body: some View {
        ScrollView {
            ContentUnavailableView {
                Label("需要 Apple Intelligence", systemImage: "apple.intelligence")
            } description: {
                Text("LevelTales 需要运行 iOS 26 或更新版本、支持 Apple Intelligence 的 iPhone，例如 iPhone 15 Pro。若设备符合要求，请在系统设置中确认 Apple Intelligence 已启用，等待模型就绪后重新打开 App。")
            }
            .frame(maxWidth: 460)
            .frame(maxWidth: .infinity)
        }
    }
}
