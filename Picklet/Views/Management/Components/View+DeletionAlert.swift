import SwiftUI

extension View {
    func confirmDeletionAlert(
        title: String = "削除の確認",
        message: String = "この項目を削除してもよろしいですか？",
        isPresented: Binding<Bool>,
        onDelete: @escaping () -> Void
    ) -> some View {
        alert(
            title,
            isPresented: isPresented,
            actions: {
                Button("削除", role: .destructive, action: onDelete)
                Button("キャンセル", role: .cancel) {}
            },
            message: {
                Text(message)
            }
        )
    }
}
