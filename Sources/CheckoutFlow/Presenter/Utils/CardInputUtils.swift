import Foundation

enum CardInputUtils {
    
    static func formatCardExpiryDateInput(from rawValue: String) -> String {
        let onlyDigits = rawValue.filter(\.isNumber)
        let limitedDigits = String(onlyDigits.prefix(4))

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
        
        guard digitOnlyValue.isEmpty == false else {
            return ""
        }
        
        if isAmexCardNumber(digitOnlyValue) {
            let limitedDigitValue = String(digitOnlyValue.prefix(15))
            return groupDigits(limitedDigitValue, groupSizes: [4, 6, 5])
        }
        
        let limitedDigitValue = String(digitOnlyValue.prefix(19))
        return groupDigits(limitedDigitValue, groupSizes: [4, 4, 4, 4, 3])
    }
    
    private static func isAmexCardNumber(_ cardNumber: String) -> Bool {
        cardNumber.hasPrefix("34") || cardNumber.hasPrefix("37")
    }
    
    private static func groupDigits(
        _ digits: String,
        groupSizes: [Int]
    ) -> String {
        var groups: [String] = []
        var currentIndex = digits.startIndex
        
        for groupSize in groupSizes where currentIndex < digits.endIndex {
            let nextIndex = digits.index(
                currentIndex,
                offsetBy: groupSize,
                limitedBy: digits.endIndex
            ) ?? digits.endIndex
            
            groups.append(String(digits[currentIndex..<nextIndex]))
            currentIndex = nextIndex
        }
        
        if currentIndex < digits.endIndex {
            groups.append(String(digits[currentIndex..<digits.endIndex]))
        }
        
        return groups.joined(separator: " ")
    }
}
