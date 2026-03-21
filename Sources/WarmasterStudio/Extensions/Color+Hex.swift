import SwiftUI

extension Color {
    /// Initialise a Color from a 6-character uppercase hex string (no leading #).
    init(hex: String) {
        let cleaned = hex.trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "#", with: "")
        let scanner = Scanner(string: cleaned)
        var rgb: UInt64 = 0
        scanner.scanHexInt64(&rgb)

        let r = Double((rgb >> 16) & 0xFF) / 255.0
        let g = Double((rgb >>  8) & 0xFF) / 255.0
        let b = Double( rgb        & 0xFF) / 255.0
        self.init(red: r, green: g, blue: b)
    }

    /// Returns a 6-character uppercase hex string representing this colour (sRGB).
    var hexString: String {
        let resolved = NSColor(self).usingColorSpace(.sRGB) ?? NSColor(self)
        let r = Int((resolved.redComponent   * 255).rounded())
        let g = Int((resolved.greenComponent * 255).rounded())
        let b = Int((resolved.blueComponent  * 255).rounded())
        return String(format: "%02X%02X%02X", r, g, b)
    }
}
