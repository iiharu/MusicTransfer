
import SwiftUI

var str = "アイウエオ123:/\".?<>*´()’abd."

print("0. original")
print(str)

func test1(str: String) {
  print("1. replaceSubrange")
  var _str = str
  while ((_str.range(of: ":")) != nil) {
    if let range = _str.range(of: ":") {
       _str.replaceSubrange(range, with: "_")
    }
  }
  print(_str)
}
func test2(str: String) {
  print("2 range regex")
  var _str = str
  let pattern = "[:/\"]"
  while ((_str.range(of: pattern, options: .regularExpression)) != nil) {
    if let range = _str.range(of: pattern, options: .regularExpression) {
      _str.replaceSubrange(range, with: "_")
    }
  }
  print(_str)
}

func test3(s: String) {
  print("3 replacingOccurrences")
  var t = s
  let pattern = "[:/\"?*<>´’]"
  t = s.replacingOccurrences(of: pattern, with: "_", options: .regularExpression)
  print(t)
}

test1(str: str)
test2(str: str)
test3(s: str)

