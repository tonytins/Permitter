/// Normalizes rendered license text before it is written.
///
/// Licensor embeds license texts exactly as published by the SPDX License
/// List. That leaves trailing whitespace, uneven wrapping, and copyright
/// notices glued to license titles. Permitter cleans those up so the output is
/// consistent regardless of how the source text happens to be formatted.
enum LicenseTextFormatter {
    static let defaultWidth = 80

    /// Formats license text without a trailing newline.
    static func format(_ text: String, width: Int = defaultWidth) -> String {
        var lines =
            text
            .replacingOccurrences(of: "\r\n", with: "\n")
            .replacingOccurrences(of: "\r", with: "\n")
            .split(separator: "\n", omittingEmptySubsequences: false)
            .map { trimmingTrailingWhitespace(String($0)) }

        separateCopyrightNotice(&lines)

        var output: [String] = []
        var block: [String] = []
        for line in lines {
            if line.isEmpty {
                appendFormattedBlock(block, to: &output, width: width)
                block.removeAll(keepingCapacity: true)
                output.append("")
            } else {
                block.append(line)
            }
        }
        appendFormattedBlock(block, to: &output, width: width)

        return trimmingBlankLines(output).joined(separator: "\n")
    }

    private enum MarkerKind {
        /// Bullets and parenthesized markers always start a new item.
        case always

        /// Numbers and letters only start a new item after a complete line.
        case conditional
    }

    private static func trimmingTrailingWhitespace(_ line: String) -> String {
        var end = line.endIndex
        while end > line.startIndex {
            let index = line.index(before: end)
            let character = line[index]
            guard character == " " || character == "\t" else {
                break
            }
            end = index
        }
        return String(line[..<end])
    }

    /// Moves a copyright notice to its own line when it shares a line with the
    /// license title, as in `MIT License Copyright (c) ...`.
    private static func separateCopyrightNotice(_ lines: inout [String]) {
        guard let index = lines.firstIndex(where: { !$0.isEmpty }) else {
            return
        }

        let line = lines[index]
        guard
            let separator = line.range(
                of: " Copyright ",
                options: .backwards
            )
        else {
            return
        }

        let title = String(line[..<separator.lowerBound])
        guard title.hasSuffix("License"), title.count <= 60 else {
            return
        }

        let notice = String(line[separator.upperBound...])
        lines.replaceSubrange(
            index...index,
            with: [title, "", "Copyright " + notice]
        )
    }

    private static func appendFormattedBlock(
        _ block: [String],
        to output: inout [String],
        width: Int
    ) {
        guard !block.isEmpty else {
            return
        }
        output.append(contentsOf: format(block: block, width: width))
    }

    private static func format(block: [String], width: Int) -> [String] {
        var output: [String] = []
        var current: String?

        func flushCurrent() {
            guard let text = current else {
                return
            }
            output.append(contentsOf: wrap(text, width: width))
            current = nil
        }

        for line in block {
            // Indented lines are code samples, placeholders, or deliberately
            // formatted material. Leave them alone.
            if line.first == " " || line.first == "\t" {
                flushCurrent()
                output.append(line)
                continue
            }

            if isSectionHeading(line) {
                flushCurrent()
                output.append(line)
                continue
            }

            guard let marker = markerKind(in: line) else {
                if current == nil {
                    current = line
                } else {
                    current = (current ?? "") + " " + line
                }
                continue
            }

            if current == nil
                || marker == .always
                || endsWithListPunctuation(current ?? "")
            {
                flushCurrent()
                current = line
            } else {
                current = (current ?? "") + " " + line
            }
        }

        flushCurrent()
        return output
    }

    private static func wrap(_ text: String, width: Int) -> [String] {
        TextWrapper.fill(text, width: max(1, width))
            .split(separator: "\n", omittingEmptySubsequences: false)
            .map(String.init)
    }

    /// Matches compact section headings such as `1.Definitions`, which the
    /// EUPL uses. Without this, such a heading would be merged with the prose
    /// that follows it.
    private static func isSectionHeading(_ line: String) -> Bool {
        let characters = Array(line)
        var index = 0
        while index < characters.count, characters[index].isNumber {
            index += 1
        }

        guard index > 0, index < characters.count, characters[index] == "."
        else {
            return false
        }

        let next = index + 1
        guard next < characters.count, characters[next].isUppercase else {
            return false
        }

        return line.count <= 60
    }

    private static func markerKind(in line: String) -> MarkerKind? {
        let characters = Array(line)
        guard let first = characters.first else {
            return nil
        }

        if "—–•·*-".contains(first) {
            guard characters.count > 1, characters[1].isWhitespace else {
                return nil
            }
            return .always
        }

        if first == "(" {
            var index = 1
            while index < characters.count,
                characters[index].isLetter || characters[index].isNumber
            {
                index += 1
            }
            guard index > 1, index < characters.count,
                characters[index] == ")",
                index + 1 < characters.count,
                characters[index + 1].isWhitespace
            else {
                return nil
            }
            return .always
        }

        if first.isNumber {
            var index = 0
            while index < characters.count, characters[index].isNumber {
                index += 1
            }
            while index + 1 < characters.count,
                characters[index] == ".",
                characters[index + 1].isNumber
            {
                index += 2
                while index < characters.count, characters[index].isNumber {
                    index += 1
                }
            }
            guard index < characters.count,
                characters[index] == "." || characters[index] == ")",
                index + 1 < characters.count,
                characters[index + 1].isWhitespace
            else {
                return nil
            }
            return .conditional
        }

        if first.isLetter {
            guard characters.count > 2,
                characters[1] == "." || characters[1] == ")",
                characters[2].isWhitespace
            else {
                return nil
            }
            return .conditional
        }

        return nil
    }

    private static func endsWithListPunctuation(_ text: String) -> Bool {
        guard let last = text.last else {
            return false
        }
        return ". ; : ! ?".contains(last)
    }

    private static func trimmingBlankLines(_ lines: [String]) -> [String] {
        var start = 0
        while start < lines.count, lines[start].isEmpty {
            start += 1
        }

        var end = lines.count
        while end > start, lines[end - 1].isEmpty {
            end -= 1
        }

        return Array(lines[start..<end])
    }
}
