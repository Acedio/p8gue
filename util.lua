function chessboard_distance(a, b)
  local delta = a - b
  return max(abs(delta.x), abs(delta.y))
end

function manhattan_distance(a, b)
  local delta = a - b
  return abs(delta.x) + abs(delta.y)
end

-- Returns a boolean that pulses high/low/high according to freq and ticks.
function frequency_pulse(ticks, freq)
  -- No need to flr because band will remove the floating part.
  return band(ticks * freq * 2 / UPDATE_FREQ, 1) == 0
end

-- Random int between [0,max)
function rnd_int(max)
  return flr(rnd()*max)
end

-- Random int between [x,y)
function rnd_range(x,y)
  return x + rnd_int(y-x)
end

-- Pick a random table key for a table with `size` entries.
function rnd_table_key(tbl, size)
  local remaining = size
  for k,_ in pairs(tbl) do
    if rnd_int(size) == 0 then
      return k
    end
    remaining -= 1
    if remaining == 0 then
      return k
    end
  end
  assert(nil, "ran out of table entries")
end
