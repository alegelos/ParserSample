import Foundation

enum CardInputUtils {
    
    static func formatCardExpiryDateInput(from rawValue: String) -> String {
        let onlyDigits = rawValue.filter(\.isNumber)
        let limitedDigits = String(onlyDigits.prefix(6)) // MMYYYY

        guard limitedDigits.count > 2 else {
            return limitedDigits
        }

        let monthText = String(limitedDigits.prefix(2))
        let yearText = String(limitedDigits.dropFirst(2))

        return "\(monthText)/\(yearText)"
    }
    
    static func sanitizeCardSecurityCodeInput(
        from rawValue: String,
        maximumLength: Int
    ) -> String {
        let digitOnlyValue = rawValue.filter(\.isNumber)
        return String(digitOnlyValue.prefix(maximumLength))
    }
    
    static func formatCardNumberInput(from rawValue: String) -> String {
           let digitOnlyValue = rawValue.filter(\.isNumber)
           let limitedDigitValue = String(digitOnlyValue.prefix(19))
           
           var groupedDigitValues: [String] = []
           var currentIndex = limitedDigitValue.startIndex
           
           while currentIndex < limitedDigitValue.endIndex {
               let nextIndex = limitedDigitValue.index(
                   currentIndex,
                   offsetBy: 4,
                   limitedBy: limitedDigitValue.endIndex
               ) ?? limitedDigitValue.endIndex
               
               groupedDigitValues.append(String(limitedDigitValue[currentIndex..<nextIndex]))
               currentIndex = nextIndex
           }
           
           return groupedDigitValues.joined(separator: " ")
       }
    
}
