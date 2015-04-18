
module Tree

  export appendBuffer, appendList, createNesting
  export resolveDollar, resolveComma

  function appendBuffer(xs, level, buffer)
    if level == 0
      return vcat(xs, {buffer})
    else
      res = appendBuffer(xs[end], (level - 1), buffer)
      return vcat(xs[1:end-1], {res})
    end
  end

  function appendList(xs, level, list)
    if level == 0
      return vcat(xs, {list})
    else
      res = appendList(xs[end], (level - 1), list)
      return vcat(xs[1:end-1], {res})
    end
  end

  function nestingHelper(xs, n)
    if n <= 1
      return xs
    else
      return {nestingHelper(xs, (n - 1))}
    end
  end

  function createNesting(n)
    return nestingHelper({}, n)
  end

  function dollarHelper(before, after)
    if length(after) == 0
      return before
    end

    cursor = after[1]
    if typeof(cursor) <: Array
      chunk = resolveDollar(cursor)
      return dollarHelper(vcat(before, {chunk}), after[2:end])
    elseif cursor[:text] == "\$"
      chunk = resolveDollar(after[2:end])
      return vcat(before, {chunk})
    else
      chunk = vcat(before, {cursor})
      return dollarHelper(chunk, after[2:end])
    end
  end

  function resolveDollar(xs)
    if length(xs) == 0
      return xs
    else
      return dollarHelper({}, xs)
    end
  end

  function commaHelper(before, after)
    if length(after) == 0
      return before
    end

    cursor = after[1]
    if (typeof(cursor) <: Array) && (length(cursor) > 0)
      head = cursor[1]
      if typeof(head) <: Array
        chunk = resolveComma(cursor)
        return commaHelper(vcat(before, {chunk}), after[2:end])
      elseif head[:text] == ","
        chunk = resolveComma(cursor[2:end])
        return commaHelper(before, vcat(chunk, after[2:end]))
      else
        chunk = resolveComma(cursor)
        return commaHelper(vcat(before, {chunk}), after[2:end])
      end
    else
      return commaHelper(vcat(before, {cursor}), after[2:end])
    end
  end

  function resolveComma(xs)
    if length(xs) == 0
      return xs
    else
      return commaHelper({}, xs)
    end
  end

end
