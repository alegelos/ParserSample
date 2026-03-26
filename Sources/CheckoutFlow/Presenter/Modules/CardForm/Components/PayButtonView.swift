import SwiftUI

struct PayButtonView: View {
    
    let title: String
    let isEnabled: Bool
    let isLoading: Bool
    let action: () -> Void
    
    init(
        title: String = "Pay",
        isEnabled: Bool = true,
        isLoading: Bool = false,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.isEnabled = isEnabled
        self.isLoading = isLoading
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(.circular)
                }
                
                Text(isLoading ? "Processing..." : title)
                    .fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
        }
        .buttonStyle(.plain)
        .foregroundColor(.white)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(isEnabled && !isLoading ? Color.blue : Color.gray.opacity(0.6))
        )
        .disabled(!isEnabled || isLoading)
        .accessibilityLabel(isLoading ? "Processing payment" : title)
    }
}

#if DEBUG
struct PayButtonView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 16) {
            PayButtonView(title: "Pay €19.99") { }
            PayButtonView(title: "Pay €19.99", isEnabled: false) { }
            PayButtonView(title: "Pay €19.99", isLoading: true) { }
        }
        .padding()
        .previewLayout(.sizeThatFits)
    }
}
#endif
