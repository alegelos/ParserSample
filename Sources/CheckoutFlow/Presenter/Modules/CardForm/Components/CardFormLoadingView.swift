import SwiftUI

struct CardFormLoadingView: View {
    
    let message: String
    
    init(message: String = "Processing payment...") {
        self.message = message
    }
    
    var body: some View {
        VStack(spacing: 12) {
            ProgressView()
                .progressViewStyle(.circular)
            
            Text(message)
                .font(.footnote)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.secondarySystemBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color(.separator).opacity(0.2), lineWidth: 1)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel(message)
    }
}

#if DEBUG
struct CardFormLoadingView_Previews: PreviewProvider {
    static var previews: some View {
        CardFormLoadingView()
            .padding()
            .previewLayout(.sizeThatFits)
    }
}
#endif
