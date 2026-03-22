import SwiftUI

struct SipBottomSheet<Content: View>: View {
    @Binding var isPresented: Bool
    let detent: CGFloat
    let content: Content

    @State private var dragOffset: CGFloat = 0

    init(isPresented: Binding<Bool>, detent: CGFloat = 420, @ViewBuilder content: () -> Content) {
        _isPresented = isPresented
        self.detent = detent
        self.content = content()
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            if isPresented {
                ColorToken.textPrimary.opacity(0.25)
                    .ignoresSafeArea()
                    .onTapGesture {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.9)) {
                            isPresented = false
                        }
                    }

                VStack(spacing: 0) {
                    Capsule()
                        .fill(ColorToken.border)
                        .frame(width: 46, height: 6)
                        .padding(.top, Spacing.sm.rawValue)
                        .padding(.bottom, Spacing.md.rawValue)

                    content
                        .padding(.horizontal, Spacing.page.rawValue)
                        .padding(.bottom, Spacing.page.rawValue)
                }
                .frame(maxWidth: .infinity)
                .frame(height: detent)
                .background(ColorToken.surface)
                .clipShape(RoundedRectangle(cornerRadius: Radius.xl.rawValue, style: .continuous))
                .shadow(color: ColorToken.shadow, radius: 20, y: -4)
                .offset(y: max(0, dragOffset))
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            dragOffset = max(0, value.translation.height)
                        }
                        .onEnded { value in
                            if value.translation.height > 120 {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.9)) {
                                    isPresented = false
                                }
                            }
                            dragOffset = 0
                        }
                )
                .transition(.move(edge: .bottom))
            }
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.9), value: isPresented)
    }
}
