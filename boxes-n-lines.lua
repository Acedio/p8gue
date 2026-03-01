BoxesNLines = {}

-- width_metatiles
-- height_metatiles
-- metatile_width_tiles
-- metatile_height_tiles
-- rooms
-- seed?
function BoxesNLines:new(o)
  o = o or {}
  setmetatable(o, self)
  self.__index = self
  return o
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

function BoxesNLines:neighbors(x, y)
  assert(x > 0, "x <= 0")
  assert(x <= self.width_metatiles, "x > width_metatiles")
  assert(y > 0, "y <= 0")
  assert(y <= self.height_metatiles, "y > height_metatiles")

  local rooms = {}
  if x > 1 then
    add(rooms, v2(x - 1, y))
  end
  if x < self.width_metatiles then
    add(rooms, v2(x + 1, y))
  end
  if y > 1 then
    add(rooms, v2(x, y - 1))
  end
  if y < self.height_metatiles then
    add(rooms, v2(x, y + 1))
  end
  return rooms
end

-- TODO: Maybe make this initialize to non-null (0?)
function init_grid(w, h)
  local meta_tiles = {}
  for my=1,h do
    meta_tiles[my] = {}
    for mx=1,w do
      meta_tiles[my][mx] = nil
    end
  end
  return meta_tiles
end

-- Returns 2d array
--
-- Thinking an easy first step is to have a metagrid of x * y sections. Each
-- section can only contain one room, so they're guaranteed to not overlap.
--
-- To start, place a room in a random section. Then iteratively add a room
-- connected cardinally to a random existing room and connect to it with a
-- (potentially Z-shaped) hall.
function BoxesNLines:grid_tree()
  local meta_tiles = init_grid(self.width_metatiles, self.height_metatiles)

  -- Pick the starting cell
  local room_xy = v2(rnd_int(self.width_metatiles) + 1, rnd_int(self.height_metatiles) + 1)

  meta_tiles[room_xy.y][room_xy.x] = -1

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

  -- TODO: This can control "fullness"
  local rooms_to_make = self.width_metatiles * self.height_metatiles / 2

  while num_candidates > 0 and rooms_to_make > 0 do
    local current_room_key = rnd_table_key(candidates, num_candidates)

    -- Pick a random room that is next to this one.
    local from_room = rnd(candidates[current_room_key])

    local room_xy = V2.from_serialized(current_room_key)
    meta_tiles[room_xy.y][room_xy.x] = from_room

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

ROOM_NONE = 0
ROOM_NORMAL = 1

function init_rooms(w, h)
  local meta_tiles = {}
  for my=1,h do
    meta_tiles[my] = {}
    for mx=1,h do
      meta_tiles[my][mx] = {
        room_type = ROOM_NONE
      }
    end
  end
  return meta_tiles
end

function BoxesNLines:random_room_bounds(metatile_x, metatile_y)
  -- Include a border of 3 tiles so we can always draw a Z-shaped corridor.
  local border = 3
  local min_width = 3
  local min_height = 3

  local room_width = min_width + rnd_int(self.metatile_width_tiles - min_width - border)
  local room_height = min_height + rnd_int(self.metatile_height_tiles - min_height - border)

  local offset_x = rnd_int(self.metatile_width_tiles - border - room_width)
  local offset_y = rnd_int(self.metatile_height_tiles - border - room_height)

  local tile_bounds = {
    upper_left = v2(
      self.metatile_width_tiles * (metatile_x - 1) + offset_x + 1,
      self.metatile_height_tiles * (metatile_y - 1) + offset_y + 1),
    dimensions = v2(room_width, room_height),
  }

  return tile_bounds
end

TILE_EMPTY = 0
TILE_FLOOR = 1
TILE_WALL = 2

function draw_tile_rect(tilemap, upper_left, dimensions, tile)
  for y=upper_left.y,upper_left.y+dimensions.y do
    for x=upper_left.x,upper_left.x+dimensions.x do
      assert(tilemap[y], "bad y: " .. y)
      tilemap[y][x] = tile
    end
  end
end

function BoxesNLines:generate()
  -- The room network.
  local grid_tree = self:grid_tree()

  -- Initialize rooms and determine their position within their metatile.
  local rooms = {}
  for my=1,self.height_metatiles do
    rooms[my] = {}
    for mx=1,self.width_metatiles do
      if grid_tree[my][mx] then
        rooms[my][mx] = {
          room_type = ROOM_NORMAL,
          from_room = grid_tree[my][mx],
          tile_bounds = self:random_room_bounds(mx, my),
        }
      else
        rooms[my][mx] = {
          room_type = ROOM_NONE
        }
      end
    end
  end

  -- Start with an empty tilemap.
  local tilemap = {}
  local tilemap_width = self.width_metatiles * self.metatile_width_tiles
  local tilemap_height = self.height_metatiles * self.metatile_height_tiles
  for ty=1,tilemap_height do
    tilemap[ty] = {}
    for tx=1,tilemap_width do
      tilemap[ty][tx] = TILE_EMPTY
    end
  end

  -- Rasterize the rooms to tiles.
  for my=1,self.height_metatiles do
    for mx=1,self.width_metatiles do
      local room = rooms[my][mx]
      if room.room_type == ROOM_NORMAL then
        draw_tile_rect(tilemap, room.tile_bounds.upper_left, room.tile_bounds.dimensions, TILE_FLOOR)
      end
    end
  end

  -- TODO: Connect the rooms.

  return tilemap
end
