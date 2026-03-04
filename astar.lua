MinHeap = {}

function MinHeap:new()
  o = {
    arr = {},
  }
  setmetatable(o, self)
  self.__index = self
  return o
end

function swap_i(arr, a, b)
  arr[a], arr[b] = arr[b], arr[a]
end

function MinHeap:push(o)
  add(self.arr, o)
  -- Heapify
  local considering = #self.arr
  while considering > 1 and self.arr[considering] < self.arr[considering \ 2] do
    swap_i(self.arr, considering, considering \ 2)
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
        swap_i(self.arr, considering, considering * 2)
      end
      return
    end
    -- Both sides exist.
    local c, a, b = self.arr[considering], self.arr[considering * 2], self.arr[considering * 2 + 1]
    if a < b then
      if a < c then
        swap_i(self.arr, considering, considering * 2)
        considering *= 2
      else
        return
      end
    else
      if b < c then
        swap_i(self.arr, considering, considering * 2 + 1)
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

function astar(tilemap, from, to)
  local heap = MinHeap:new()
  for i=1,10 do
    local val = rnd_int(10)
    printh("pushing " .. val)
    heap:push(val)
    heap:print()
  end

  while heap:size() > 0 do
    printh("pop " .. heap:pop())
  end
end
