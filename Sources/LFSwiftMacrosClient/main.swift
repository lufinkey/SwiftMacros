import LFSwiftMacros

let a = 17
let b = 25

let (result, code) = #stringify(a + b)

print("The value \(result) was produced by the code \"\(code)\"")

@ExtendableEnum
enum Color: Hashable {
	private enum KnownCases: String {
		case red = "blue"
	}
}

print("red = \(Color.red.rawValue)")
