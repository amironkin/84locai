import SwiftUI

struct MessageBubble: View {
    let message: ChatMessage
    @State private var appeared = false

    var body: some View {
        HStack(alignment: .bottom, spacing: Spacing.sm) {
            if message.isUser { Spacer(minLength: 48) }

            if !message.isUser {
                // Assistant avatar
                ZStack {
                    Circle()
                        .fill(LinearGradient.primaryGradient)
                        .frame(width: 30, height: 30)
                    Image(systemName: "sparkles")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(.white)
                }
            }

            VStack(alignment: message.isUser ? .trailing : .leading, spacing: Spacing.xs) {
                Text(message.content.isEmpty && message.isStreaming ? " " : message.content)
                    .font(.appBody)
                    .foregroundStyle(message.isUser ? .white : .appTextPrimary)
                    .padding(.horizontal, Spacing.md)
                    .padding(.vertical, Spacing.sm + 2)
                    .background(
                        Group {
                            if message.isUser {
                                RoundedRectangle(cornerRadius: Radius.lg)
                                    .fill(LinearGradient.userBubble)
                            } else {
                                RoundedRectangle(cornerRadius: Radius.lg)
                                    .fill(Color.appCard)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: Radius.lg)
                                            .stroke(Color.appBorder, lineWidth: 1)
                                    )
                            }
                        }
                    )
                    .textSelection(.enabled)

                Text(message.createdAt.formatted(.dateTime.hour().minute()))
                    .font(.system(size: 10))
                    .foregroundStyle(.appTextMuted)
            }

            if message.isUser { } else { Spacer(minLength: 48) }
        }
        .padding(.horizontal, Spacing.md)
        .offset(y: appeared ? 0 : 20)
        .opacity(appeared ? 1 : 0)
        .onAppear {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
                appeared = true
            }
        }
    }
}
