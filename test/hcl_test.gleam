import birdie
import gleeunit
import hcl
import pprint

pub fn main() {
  gleeunit.main()
}

pub fn test_scan(name: String, src: String) {
  src |> hcl.scan |> pprint.format |> birdie.snap("Scanner: " <> name)
}

pub fn braces_test() {
  test_scan("braces", "{} [] ()")
}

pub fn math_test() {
  test_scan("math", "+ - * / %")
}

pub fn comparison_test() {
  test_scan("comparison", "!= < <= > >= = ==")
}

pub fn boolean_test() {
  test_scan("boolean", "! && ||")
}

pub fn other_punctuation_test() {
  test_scan("other_punctuation", ": ? => . , ... ${ %{")
}

pub fn ident_test() {
  test_scan("identifier", "hello_baby-c4kes")
}

pub fn byte_offset_of_ident_test() {
  test_scan("byte offset of identifier", "Foo + Bar")
}

pub fn line_comment_test() {
  test_scan("line comment with //", "// I am a comment\nFoo")
}
