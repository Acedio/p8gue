BoxesNLines = {}

-- meta_width
-- meta_height
-- tile_width
-- tile_height
-- rooms
-- seed?
function BoxesNLines:new(o)
  o = o or {}
  setmetatable(o, self)
  self.__index = self
  return o
end

--[[
Thinking an easy first step is to have a metagrid of x * y sections. Each section can only contain one room, so they're guaranteed to not overlap.

To start, place a room in a random section. Then iteratively add a room connected cardinally to a random existing room and connect to it with a (potentially L-shaped) hall.
]]

TILE_EMPTY = 0
TILE_FLOOR = 1
TILE_WALL = 2

function init_rooms(w, h)
  local meta_tiles = {}
  for my=1,h do
    meta_tiles[my] = {}
    for mx=1,h do
      meta_tiles[my][mx] = nil
    end
  end
  return meta_tiles
end

function rnd_int(max)
  return flr(rnd()*max)
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

function BoxesNLines:make_room(x,y,from_room)
  return {x,y,from_room}
end

function BoxesNLines:neighbors(x, y)
  assert(x > 0, "x <= 0")
  assert(x <= self.meta_width, "x > meta_width")
  assert(y > 0, "y <= 0")
  assert(y <= self.meta_height, "y > meta_height")

  local rooms = {}
  if x > 1 then
    add(rooms, v2(x - 1, y))
  end
  if x < self.meta_width then
    add(rooms, v2(x + 1, y))
  end
  if y > 1 then
    add(rooms, v2(x, y - 1))
  end
  if y < self.meta_height then
    add(rooms, v2(x, y + 1))
  end
  return rooms
end

-- Return 2d array
function BoxesNLines:generate()
  local meta_tiles = init_rooms(self.meta_width, self.meta_height)

  -- Pick the starting cell
  local room_xy = v2(rnd_int(self.meta_width) + 1, rnd_int(self.meta_height) + 1)

  meta_tiles[room_xy.y][room_xy.x] = self:make_room(room_xy.x, room_xy.y, -1)

  -- Track the number of candidates so we can randomly select one.
  local num_candidates = 0
  local candidates = {}

  -- Add roomless neighbors as candidates.
  for _, neighbor in ipairs(self:neighbors(room_xy.x, room_xy.y)) do
    local current_room_key = room_xy:serialize()
    local neighbor_key = neighbor:serialize()
    if not meta_tiles[neighbor.y][neighbor.x] then
      if candidates[neighbor_key] then
        add(candidates[neighbor_key], current_room_key)
      else
        num_candidates += 1
        candidates[neighbor_key] = {current_room_key}
      end
    end
  end

  local rooms_to_make = self.meta_width * self.meta_height / 2

  while num_candidates > 0 and rooms_to_make > 0 do
    local current_room_key = rnd_table_key(candidates, num_candidates)

    -- Pick a random room that is next to this one.
    local from_room = rnd(candidates[current_room_key])

    local room_xy = V2.from_serialized(current_room_key)
    meta_tiles[room_xy.y][room_xy.x] = self:make_room(room_xy.x, room_xy.y, from_room)

    -- Add roomless neighbors as candidates.
    for _, neighbor in ipairs(self:neighbors(room_xy.x, room_xy.y)) do
      local current_room_key = room_xy:serialize()
      local neighbor_key = neighbor:serialize()
      if not meta_tiles[neighbor.y][neighbor.x] then
        if candidates[neighbor_key] then
          add(candidates[neighbor_key], current_room_key)
        else
          num_candidates += 1
          candidates[neighbor_key] = {current_room_key}
        end
      end
    end

    candidates[current_room_key] = nil
    num_candidates -= 1
    rooms_to_make -= 1
  end

  return meta_tiles
end
