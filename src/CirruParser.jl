
module CirruParser
  export parse, pare

  include("Tree.jl")

  function parse(code, filename)
    buffer = Dict()

    state = Dict()
    state[:name] = :indent
    state[:x] = 1
    state[:y] = 1
    state[:level] = 1
    state[:indent] = 0
    state[:indented] = 0
    state[:nest] = 0
    state[:path] = filename

    res = parseRunner({}, buffer, state, code)
    res = map(Tree.resolveDollar, res)
    res = map(Tree.resolveComma, res)
    res
  end

  function shorten(xs)
    if typeof(xs) <: Array
      return map(shorten, xs)
    else
      return xs[:text]
    end
  end

  # eof

  function pare(code, filename)
    res = parse(code, filename)
    shorten(res)
  end

  function escape_eof(xs, buffer, state, code)
    error("EOF in escape state")
  end

  function string_eof(xs, buffer, state, code)
    error("EOF in string state")
  end

  function space_eof(xs, buffer, state, code)
    return xs
  end

  function token_eof(xs, buffer, state, code)
    buffer[:ex] = state[:x]
    buffer[:ey] = state[:y]
    xs = Tree.appendBuffer(xs, state[:level], buffer)
    buffer = Dict()
    xs
  end

  function indent_eof(xs, buffer, state, code)
    return xs
  end

  # escape

  function escape_newline(xs, buffer, state, code)
    error("new line whice escape")
  end

  function escape_n(xs, buffer, state, code)
    state[:x] += 1
    buffer[:text] *= "\n"
    state[:name] = :string
    parseRunner(xs, buffer, state, code[2:end])
  end

  function escape_t(xs, buffer, state, code)
    state[:x] += 1
    buffer.text *= "\t"
    state[:name] = :string
    parseRunner(xs, buffer, state, code[2:end])
  end

  function escape_else(xs, buffer, state, code)
    state[:x] += 1
    buffer[:text] *= string(code[1])
    state[:name] = :string
    parseRunner(xs, buffer, state, code[2:end])
  end

  # string

  function string_backslash(xs, buffer, state, code)
    state[:name] = :escape
    state[:x] += 1
    parseRunner(xs, buffer, state, code[2:end])
  end

  function string_newline(xs, buffer, state, code)
    error("newline in a string")
  end

  function string_quote(xs, buffer, state, code)
    state[:name] = :token
    state[:x] += 1
    parseRunner(xs, buffer, state, code[2:end])
  end

  function string_else(xs, buffer, state, code)
    state[:x] += 1
    buffer[:text] *= string(code[1])
    parseRunner(xs, buffer, state, code[2:end])
  end

  # space

  function space_space(xs, buffer, state, code)
    state[:x] += 1
    parseRunner(xs, buffer, state, code[2:end])
  end

  function space_newline(xs, buffer, state, code)
    if state[:nest] != 0
      error("incorrect nesting")
    end

    state[:name] = :indent
    state[:x] = 1
    state[:y] += 1
    state[:indented] = 0
    parseRunner(xs, buffer, state, code[2:end])
  end

  function space_open(xs, buffer, state, code)
    nesting = Tree.createNesting(1)
    xs = Tree.appendList(xs, state[:level], nesting)
    state[:nest] += 1
    state[:level] += 1
    state[:x] += 1
    parseRunner(xs, buffer, state, code[2:end])
  end

  function space_close(xs, buffer, state, code)
    state[:nest] -= 1
    state[:level] -= 1
    if state[:nest] < 0
      error("close at space")
    end
    state[:x] += 1
    parseRunner(xs, buffer, state, code[2:end])
  end

  function space_quote(xs, buffer, state, code)
    state[:name] = :string

    buffer = Dict()
    buffer[:text] = ""
    buffer[:x] = state[:x]
    buffer[:y] = state[:y]
    buffer[:path] = state[:path]

    state[:x] += 1
    parseRunner(xs, buffer, state, code[2:end])
  end

  function space_else(xs, buffer, state, code)
    state[:name] = :token

    buffer = Dict()
    buffer[:text] = string(code[1])
    buffer[:x] = state[:x]
    buffer[:y] = state[:y]
    buffer[:path] = state[:path]

    state[:x] += 1
    parseRunner(xs, buffer, state, code[2:end])
  end

  # token

  function token_space(xs, buffer, state, code)
    state[:name] = :space
    buffer[:ex] = state[:x]
    buffer[:ey] = state[:y]
    xs = Tree.appendBuffer(xs, state[:level], buffer)
    state[:x] += 1
    buffer = Dict()
    parseRunner(xs, buffer, state, code[2:end])
  end

  function token_newline(xs, buffer, state, code)
    state[:name] = :indent
    buffer[:ex] = state[:x]
    buffer[:ey] = state[:y]
    xs = Tree.appendBuffer(xs, state[:level], buffer)
    state[:indented] = 0
    state[:x] = 1
    state[:y] += 1
    buffer = Dict()
    parseRunner(xs, buffer, state, code[2:end])
  end

  function token_open(xs, buffer, state, code)
    error("open parenthesis in token")
  end

  function token_close(xs, buffer, state, code)
    state[:name] = :space
    buffer[:ex] = state[:x]
    buffer[:ey] = state[:y]
    xs = Tree.appendBuffer(xs, state[:level], buffer)
    buffer = Dict()
    parseRunner(xs, buffer, state, code)
  end

  function token_quote(xs, buffer, state, code)
    state[:name] = :string
    state[:x] += 1
    parseRunner(xs, buffer, state, code[2:end])
  end

  function token_else(xs, buffer, state, code)
    buffer[:text] *= string(code[1])
    state[:x] += 1
    parseRunner(xs, buffer, state, code[2:end])
  end

  # indent

  function indent_space(xs, buffer, state, code)
    state[:indented] += 1
    state[:x] += 1
    parseRunner(xs, buffer, state, code[2:end])
  end

  function indent_newline(xs, buffer, state, code)
    state[:x] = 1
    state[:y] += 1
    state[:indented] = 0
    parseRunner(xs, buffer, state, code[2:end])
  end

  function indent_close(xs, buffer, state, code)
    error("close parenthesis at indent")
  end

  function indent_else(xs, buffer, state, code)
    state[:name] = :space
    if (state[:indented] % 2) == 1
      error("odd indentation")
    end
    indented = state[:indented] / 2
    diff = indented - state[:indent]

    if diff <= 0
      nesting = Tree.createNesting(1)
      xs = Tree.appendList(xs, (state[:level] + diff - 1), nesting)
    elseif diff > 0
      nesting = Tree.createNesting(diff)
      xs = Tree.appendList(xs, state[:level], nesting)
    end

    state[:level] += diff
    state[:indent] = indented
    parseRunner(xs, buffer, state, code)
  end

  # parse

  function parseRunner(xs, buffer, state, code)
    args = {xs, buffer, state, code}
    if length(code) == 0
      eof = true
    else
      eof = false
      char = code[1]
    end

    if state[:name] == :escape
      if eof
        escape_eof(args...)
      elseif char == '\n'
        escape_newline(args...)
      elseif char == 'n'
        escape_n(args...)
      elseif char == 't'
        escape_t(args...)
      else
        escape_else(args...)
      end
    elseif state[:name] == :string
      if eof
        string_eof(args...)
      elseif char == '\\'
        string_backslash(args...)
      elseif char == '\n'
        string_newline(args...)
      elseif char == '"'
        string_quote(args...)
      else
        string_else(args...)
      end
    elseif state[:name] == :space
      if eof
        space_eof(args...)
      elseif char == ' '
        space_space(args...)
      elseif char == '\n'
        space_newline(args...)
      elseif char == '('
        space_open(args...)
      elseif char == ')'
        space_close(args...)
      elseif char =='"'
        space_quote(args...)
      else
        space_else(args...)
      end
    elseif state[:name] == :token
      if eof
        token_eof(args...)
      elseif char == ' '
        token_space(args...)
      elseif char == '\n'
        token_newline(args...)
      elseif char == '('
        token_open(args...)
      elseif char == ')'
        token_close(args...)
      elseif char == '"'
        token_quote(args...)
      else
        token_else(args...)
      end
    elseif state[:name] == :indent
      if eof
        indent_eof(args...)
      elseif char == ' '
        indent_space(args...)
      elseif char == '\n'
        indent_newline(args...)
      elseif char == ')'
        indent_close(args...)
      else
        indent_else(args...)
      end
    end
  end
end
