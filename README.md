
CirruParser.jl
----

Cirru Parser in Julia.

Code is manually converted from CoffeeScript version of Parser.

### Usage

```julia
Pkg.add("CirruParser")
```

```julia
using CirruParser

code = "set a 1\nprint a"

CirruParser.parse(code, "filename")
CirruParser.pare(code, "filename") # simplified leaf nodes
```

### License

MIT
