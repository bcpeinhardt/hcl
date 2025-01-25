//// An HCL parser and public AST in Gleam.
//// The [spec](https://github.com/hashicorp/hcl/blob/main/hclsyntax/spec.md)

import gleam/string
import gleam/list
import gleam/result

// Let's start with a scanner.

pub type HclTokenType {

  /// Line comments start with either the // or # sequences and end with the next 
  /// newline sequence. A line comment is considered equivalent to a newline sequence.
  LineComment

  /// Inline comments start with the /* sequence and end with the */ sequence, 
  /// and may have any characters within except the ending sequence. An inline comment 
  /// is considered equivalent to a whitespace sequence.
  InlineComment

  /// Newline sequences (either U+000A or U+000D followed by U+000A) are not considered whitespace 
  /// but are ignored as such in certain contexts
  Newline

  /// Horizontal tab characters (U+0009) are also treated as whitespace, but are counted 
  /// only as one "column" for the purpose of reporting source positions.
  HorizontalTab

  /// Identifier = ID_Start (ID_Continue | '-')*;
  /// Definition of ID_START and ID_Continue [here](http://unicode.org/reports/tr31/)
  Identifier

  /// NumericLit = decimal+ ("." decimal+)? (expmark decimal+)?;
  /// decimal    = '0' .. '9';
  /// expmark    = ('e' | 'E') ("+" | "-")?;
  NumericLiteral

  /// Operators and Delimeters
  /// +    &&   ==   <    :    {    [    (    ${
  /// -    ||   !=   >    ?    }    ]    )    %{
  /// *    !         <=        =         .
  /// /              >=        =>        ,
  /// %                                  ...
  OperatorOrDelimeter
}

pub type HclToken {
  HclToken(type_: HclTokenType, lexeme: String, byte_offset: Int)
}

// ------------------ Scanner ---------------------------------------------------

type ScannerMode {
  Normal
}

type Scanner {
  Scanner(
    src: String,
    byte_offset: Int,
    mode: ScannerMode
  )
}

fn new_scanner(src: String) -> Scanner {
  Scanner(src:, byte_offset: 0, mode: Normal)
}

/// Increment the byte offset.
fn advance(scanner: Scanner, by offset: Int, new_src src: String) -> Scanner {
  Scanner(..scanner, byte_offset: scanner.byte_offset + offset, src:)
}

/// Produce a token of the given type with the scanner's current state.
fn token(scanner: Scanner, type_: HclTokenType, lexeme: String) -> HclToken {
  HclToken(type_:, byte_offset: scanner.byte_offset, lexeme:)
}

/// Scan terraform source code into a list of tokens.
pub fn scan(src: String) -> Result(List(HclToken), Nil) {
  let scanner = new_scanner(src)
  do_scan(scanner, []) |> result.map(list.reverse)
}

fn do_scan(scanner: Scanner, acc: List(HclToken)) -> Result(List(HclToken), Nil) {

  let op = fn(new_src, lexeme) {
    do_scan(advance(scanner, by: string.length(lexeme), new_src:), [token(scanner, OperatorOrDelimeter, lexeme), ..acc])
  }

  case scanner.mode {
    Normal -> case scanner.src {
      "" -> Ok(acc)

      // Whitespace is ignored
      " " <> rest -> do_scan(scanner |> advance(by: 1, new_src: rest), acc)

      "{" <> rest -> op(rest, "{")
      "}" <> rest -> op(rest, "}")

      "[" <> rest -> op(rest, "[")
      "]" <> rest -> op(rest, "]")

      "(" <> rest -> op(rest, "(")
      ")" <> rest -> op(rest, ")")

      "+" <> rest -> op(rest, "+")
      "-" <> rest -> op(rest, "-")
      "*" <> rest -> op(rest, "*")
      "/" <> rest -> op(rest, "/")

      // Starts with %
      "%{" <> rest -> op(rest, "%{")
      "%" <> rest -> op(rest, "%")

      // Starts with <
      "<=" <> rest -> op(rest, "<=")
      "<" <> rest -> op(rest, "<")

      // Starts with >
      ">=" <> rest -> op(rest, ">=")
      ">" <> rest -> op(rest, ">")

      // Starts with =
      "==" <> rest -> op(rest, "==")
      "=>" <> rest -> op(rest, "=>")
      "=" <> rest -> op(rest, "=")

      // Starts with !
      "!=" <> rest -> op(rest, "!=")
      "!" <> rest -> op(rest, "!")

      // Starts with .
      "..." <> rest -> op(rest, "...")
      "." <> rest -> op(rest, ".")

      "&&" <> rest -> op(rest, "&&")
      "||" <> rest -> op(rest, "||")

      ":" <> rest -> op(rest, ":")
      "?" <> rest -> op(rest, "?")
      "," <> rest -> op(rest, ",")
      "${" <> rest -> op(rest, "${")


      _ -> todo
    }
  }
}

// --------------------- End Scanner ----------------------------------------------------------


