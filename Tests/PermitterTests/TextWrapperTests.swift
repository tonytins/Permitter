import Testing

@testable import Permitter

struct TextWrapperTests {
    @Test(arguments: [
        ("foo", 10, "foo"),
        ("foo bar baz", 5, "foo\nbar\nbaz"),
        ("foo bar baz", 10, "foo bar\nbaz"),
        (
            "Memory safety without garbage collection.",
            15,
            "Memory safety\nwithout garbage\ncollection."
        ),
        ("First line.\nSecond line.", 40, "First line.\nSecond line."),
        ("foo-bar", 5, "foo-\nbar"),
        ("foo-bar-baz", 5, "foo-\nbar-\nbaz"),
        ("foo-bar-baz", 9, "foo-bar-\nbaz"),
        ("Na2-CH4", 5, "Na2-\nCH4"),
        ("foobarbaz", 3, "foo\nbar\nbaz"),
        ("ab\ncdefghijkl", 5, "ab\ncdefg\nhijkl"),
        ("abcdefgh\nijkl", 5, "abcde\nfgh\nijkl"),
        ("test\n", 11, "test\n"),
        ("test\n\na\n\n", 11, "test\n\na\n\n"),
        ("1 3 5 7\n1 3 5 7", 5, "1 3 5\n7\n1 3 5\n7"),
    ])
    func fillsLikeTextwrap(
        text: String,
        width: Int,
        expected: String
    ) {
        #expect(TextWrapper.fill(text, width: width) == expected)
    }

    @Test func keepsLeadingIndentationFromNewLines() {
        let text = "   0. Definitions.\n\n   A file is an \"Independent Module\"."

        #expect(
            TextWrapper.fill(text, width: 80)
                == "   0. Definitions.\n\n   A file is an \"Independent Module\"."
        )
    }
}
