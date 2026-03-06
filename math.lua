function chessboard_distance(a, b)
  local delta = a - b
  return max(abs(delta.x), abs(delta.y))
end

function manhattan_distance(a, b)
  local delta = a - b
  return abs(delta.x) + abs(delta.y)
end
