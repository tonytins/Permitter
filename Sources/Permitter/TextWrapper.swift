/// A close port of `textwrap::fill` from textwrap 0.11, which Licensor uses to
/// wrap exceptions to the width of the license they accompany.
///
/// Line breaks in the input are preserved, whitespace runs become split points,
/// and words longer than the width are broken at hyphens or between characters.
/// All bundled exception texts are ASCII, so display widths match for them.
enum TextWrapper {
    static func fill(_ text: String, width: Int) -> String {
        let characters = Array(text)
        var lines: [String] = []

        var start = 0
        var split = 0
        var splitLength = 0
        var lineWidth = 0
        var lineWidthAtSplit = 0
        var inWhitespace = false
        var index = 0

        while index < characters.count {
            let character = characters[index]
            let characterWidth = displayWidth(of: character)

            if character == "\n" {
                split = index
                splitLength = 1
                lineWidthAtSplit = lineWidth
                inWhitespace = false

                if split + splitLength < characters.count {
                    lines.append(String(characters[start..<split]))
                    start = split + splitLength
                    lineWidth = 0
                    index += 1
                    continue
                }
            } else if isWhitespace(character) {
                if inWhitespace {
                    splitLength += 1
                } else {
                    split = index
                    splitLength = 1
                }
                lineWidthAtSplit = lineWidth + characterWidth
                inWhitespace = true
            } else if lineWidth + characterWidth > width {
                inWhitespace = false

                let remaining = characters[(split + splitLength)...]
                let finalWord: ArraySlice<Character>
                if let whitespaceIndex = remaining.firstIndex(where: isWhitespace) {
                    finalWord = remaining[..<whitespaceIndex]
                } else {
                    finalWord = remaining
                }

                var hyphen: [Character] = []
                for candidate in hyphenSplits(finalWord).reversed() {
                    let candidateWidth =
                        displayWidth(of: candidate.head)
                        + displayWidth(of: candidate.hyphen)
                    if lineWidthAtSplit + candidateWidth <= width {
                        split += splitLength + candidate.head.count
                        splitLength = 0
                        hyphen = candidate.hyphen
                        break
                    }
                }

                if start >= split {
                    split = index
                    splitLength = 0
                    lineWidthAtSplit = lineWidth
                }

                if start < split {
                    var line = Array(characters[start..<split])
                    line.append(contentsOf: hyphen)
                    lines.append(String(line))

                    start = split + splitLength
                    lineWidth -= lineWidthAtSplit
                    lineWidth += characterWidth
                    index += 1
                    continue
                }
            } else {
                inWhitespace = false
            }

            lineWidth += characterWidth
            index += 1
        }

        if start < characters.count {
            lines.append(String(characters[start...]))
        }

        return lines.joined(separator: "\n")
    }

    private struct HyphenSplit {
        let head: [Character]
        let hyphen: [Character]
        let tail: [Character]
    }

    private static func hyphenSplits(
        _ word: ArraySlice<Character>
    ) -> [HyphenSplit] {
        let characters = Array(word)
        guard characters.count >= 2 else {
            return [HyphenSplit(head: characters, hyphen: [], tail: [])]
        }

        var splits: [HyphenSplit] = []
        var previous = characters[0]
        var currentIndex = 1
        var current = characters[1]

        for nextIndex in 2..<characters.count {
            let next = characters[nextIndex]
            if isAlphanumeric(previous),
                current == "-",
                isAlphanumeric(next)
            {
                splits.append(
                    HyphenSplit(
                        head: Array(characters[0...currentIndex]),
                        hyphen: [],
                        tail: Array(characters[(currentIndex + 1)...])
                    )
                )
            }
            previous = current
            currentIndex = nextIndex
            current = next
        }

        splits.append(HyphenSplit(head: characters, hyphen: [], tail: []))
        return splits
    }

    private static func isWhitespace(_ character: Character) -> Bool {
        character.isWhitespace && character != "\u{00A0}"
    }

    private static func isAlphanumeric(_ character: Character) -> Bool {
        character.isLetter || character.isNumber
    }

    private static func displayWidth(of characters: [Character]) -> Int {
        characters.reduce(0) { $0 + displayWidth(of: $1) }
    }

    private static func displayWidth(of character: Character) -> Int {
        guard character.unicodeScalars.count == 1,
            let scalar = character.unicodeScalars.first
        else {
            return 1
        }

        switch scalar.properties.generalCategory {
        case .nonspacingMark, .spacingMark, .enclosingMark:
            return 0
        default:
            break
        }

        if scalar.value < 0x20 || scalar.value == 0x7F {
            return 0
        }

        return isWide(scalar) ? 2 : 1
    }

    private static func isWide(_ scalar: Unicode.Scalar) -> Bool {
        switch scalar.value {
        case 0x1100...0x115F,
            0x2E80...0x303E,
            0x3041...0x33FF,
            0x3400...0x4DBF,
            0x4E00...0x9FFF,
            0xA000...0xA4CF,
            0xAC00...0xD7A3,
            0xF900...0xFAFF,
            0xFE10...0xFE19,
            0xFE30...0xFE6F,
            0xFF00...0xFF60,
            0xFFE0...0xFFE6,
            0x1F300...0x1F64F,
            0x1F900...0x1F9FF,
            0x20000...0x3FFFD:
            return true
        default:
            return false
        }
    }
}
