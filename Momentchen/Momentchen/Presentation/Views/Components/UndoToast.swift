//
//  UndoToast.swift
//  Momentchen
//
//  Created by Developer Agent on 23.10.2025.
//

import SwiftUI

/// Toast view that appears when a moment is deleted, offering an undo option
struct UndoToast: View {
    let message: String
    let onUndo: () -> Void

    @Environment(\.accessibilityReduceMotion) var reduceMotion

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "trash")
                .foregroundStyle(.white)

            Text(message)
                .foregroundStyle(.white)
                .font(.subheadline)
                .fontWeight(.medium)

            Spacer()

            Button("Rückgängig") {
                onUndo()
            }
            .foregroundStyle(.yellow)
            .fontWeight(.semibold)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(.black.opacity(0.9))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.2), radius: 8, y: 4)
        .padding(.horizontal, 16)
        .padding(.bottom, 16)
        .transition(reduceMotion ? .opacity : .move(edge: .bottom).combined(with: .opacity))
    }
}

#if DEBUG
#Preview {
    VStack {
        Spacer()
        UndoToast(message: "Moment gelöscht") {
            print("Undo tapped")
        }
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color.gray.opacity(0.3))
}
#endif
