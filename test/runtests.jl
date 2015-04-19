
using CirruParser
using Base.Test
using JSON

testCases = ["comma" "demo" "folding" "html" "indent" "line" "parentheses" "quote" "spaces" "unfolding"]

for name in testCases
  code = readall(open("../examples/$(name).cirru"))
  excepted = strip(readall(open("../ast/$(name).json")))
  ast = CirruParser.pare(code, "")
  formated = strip(JSON.json(ast, 2))
  if formated == excepted
    println("ok: $(name)")
  else
    println("failed:")
    println(formated)
    println("")
  end
  @test formated == excepted
end

println()
