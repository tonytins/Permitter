import Testing

@testable import Permitter

struct LicenseTextFormatterTests {
    @Test func stripsTrailingWhitespaceAndBlankLines() {
        let text = "Title  \n\nBody   \n\n"

        #expect(LicenseTextFormatter.format(text) == "Title\n\nBody")
    }

    @Test func separatesCopyrightFromTitle() {
        let text = """
            MIT License Copyright (c) <year> <copyright holders>

            Permission is hereby granted.
            """

        #expect(
            LicenseTextFormatter.format(text)
                == """
                MIT License

                Copyright (c) <year> <copyright holders>

                Permission is hereby granted.
                """
        )
    }

    @Test func reflowsPlainParagraphs() {
        let text = "one two three four five six seven"

        #expect(
            LicenseTextFormatter.format(text, width: 10)
                == "one two\nthree four\nfive six\nseven"
        )
    }

    @Test func preservesIndentedBlocks() {
        let text = """
               1. Definitions.

               This deliberately long indented line stays exactly as it is even though it is wider than the limit.
            """

        #expect(LicenseTextFormatter.format(text, width: 40) == text)
    }

    @Test func wrapsListItemsWithoutMergingThem() {
        let text = """
            1. First item is long.
            2. Second item is long.
            """

        #expect(
            LicenseTextFormatter.format(text, width: 20)
                == """
                1. First item is
                long.
                2. Second item is
                long.
                """
        )
    }

    @Test func keepsCompactSectionHeadingsSeparate() {
        let text = """
            1.Definitions
            This is the definition.
            """

        #expect(
            LicenseTextFormatter.format(text)
                == """
                1.Definitions
                This is the definition.
                """
        )
    }

    @Test func handlesBulletItems() {
        let text = """
            — First item that is long enough to wrap.
            — Second item.
            """

        #expect(
            LicenseTextFormatter.format(text, width: 20)
                == """
                — First item that is
                long enough to wrap.
                — Second item.
                """
        )
    }

    @Test func isIdempotent() {
        let text = """
            Title Copyright (c) 2026 Example

            A paragraph that is long enough to wrap onto several lines when the width is small.

            — A bullet item that also wraps onto more than one line.

            1.Definitions
            Body text.
            """
        let once = LicenseTextFormatter.format(text, width: 40)

        #expect(LicenseTextFormatter.format(once, width: 40) == once)
    }
}
