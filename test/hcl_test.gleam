import hcl
import gleeunit
import birdie
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
