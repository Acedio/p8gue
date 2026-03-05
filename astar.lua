MinHeap = {}

function MinHeap:new()
  o = {
    arr = {},
  }
  setmetatable(o, self)
  self.__index = self
  return o
end

function MinHeap:swap(a, b)
  self.arr[a], self.arr[b] = self.arr[b], self.arr[a]
end

function MinHeap:push(o)
  add(self.arr, o)
  -- Heapify
  local considering = #self.arr
  while considering > 1 and self.arr[considering] < self.arr[considering \ 2] do
    self:swap(considering, considering \ 2)
    considering = considering \ 2
  end
end

function MinHeap:print()
  for i=1,#self.arr do
    printh(self.arr[i])
  end
end

function MinHeap:delete_min()
  assert(self:size() > 0, "tried to pop an empty heap")
  local considering = 1
  if #self.arr <= 1 then
    deli(self.arr)
    return
  end

  self.arr[1] = deli(self.arr)
  while considering * 2 <= #self.arr do
    if considering * 2 + 1 > #self.arr then
      -- Only the left side exists.
      if self.arr[considering * 2] < self.arr[considering] then
        self:swap(considering, considering * 2)
      end
      return
    end
    -- Both sides exist.
    local c, a, b = self.arr[considering], self.arr[considering * 2], self.arr[considering * 2 + 1]
    if a < b then
      if a < c then
        self:swap(considering, considering * 2)
        considering *= 2
      else
        return
      end
    else
      if b < c then
        self:swap(considering, considering * 2 + 1)
        considering = considering * 2 + 1
      else
        return
      end
    end
  end
end

function MinHeap:min()
  assert(self:size() > 0, "tried to pop an empty heap")
  return self.arr[1]
end

function MinHeap:size()
  return #self.arr
end

function MinHeap:pop()
  assert(self:size() > 0, "tried to pop an empty heap")
  local result = self:min()
  self:delete_min()
  return result
end

ScoredPos = {}
function ScoredPos:new(pos, score)
  o = {
    pos = pos:copy(),
    score = score,
  }
  setmetatable(o, self)
  self.__index = self
  return o
end

function ScoredPos.__lt(a,b)
  return a.score < b.score
end

local function neighbor_tiles(tilemap, pos)
  local ns = {}
  for dir in all({v2(1,0),v2(-1,0),v2(0,1),v2(0,-1)}) do
    local npos = pos + dir
    local bounds = tilemap_bounds(tilemap)
    local in_bounds = npos.y >= 0 and npos.y < bounds.y and npos.x >= 0 and npos.x < bounds.x
    if in_bounds and tilemap_at(tilemap, npos) == TILE_FLOOR then
      add(ns, npos)
    end
  end
  return ns
end

local function manhattan_distance(a, b)
  local delta = a - b
  return abs(delta.x) + abs(delta.y)
end

-- Returns a list of v2 describing the path, or nil if no path exists.
--
-- If max_dist is non-nil, abandons the search if the path distance is longer
-- than max_dist.
function astar(tilemap, from, to, max_dist)
  local frontier = MinHeap:new()
  local cost_so_far = {}
  local come_from = {}
  cost_so_far[from:serialize()] = 0
  frontier:push(ScoredPos:new(from, 0))

  while frontier:size() > 0 and ((not max_dist) or frontier:min().score <= max_dist) do
    local current = frontier:pop().pos

    if current == to then
      local path = {}
      while come_from[current:serialize()] do
        add(path, current)
        current = come_from[current:serialize()]
      end
      -- Reverse the path.
      for i=1,#path\2 do
        path[i], path[#path-i+1] = path[#path-i+1], path[i]
      end
      return path
    end

    for neighbor in all(neighbor_tiles(tilemap, current)) do
      local new_cost = cost_so_far[current:serialize()] + 1
      local prev_cost = cost_so_far[neighbor:serialize()]
      if not prev_cost or new_cost < prev_cost then
        come_from[neighbor:serialize()] = current
        cost_so_far[neighbor:serialize()] = new_cost
        local score = new_cost + manhattan_distance(neighbor, to)
        frontier:push(ScoredPos:new(neighbor, score))
      end
    end
  end

  return nil -- No path found.
end
