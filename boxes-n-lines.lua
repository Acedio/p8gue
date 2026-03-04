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

  meta_tiles[room_xy.y][room_xy.x] = 0

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

  local room_width = rnd_range(min_width, self.metatile_width_tiles - border)
  local room_height = rnd_range(min_height, self.metatile_height_tiles - border)

  local offset_x = rnd_int(self.metatile_width_tiles - border - room_width)
  local offset_y = rnd_int(self.metatile_height_tiles - border - room_height)

  local tile_bounds = {
    upper_left = v2(
      self.metatile_width_tiles * (metatile_x - 1) + offset_x,
      self.metatile_height_tiles * (metatile_y - 1) + offset_y)
      + v2(1,1) -- 0-indexed.
      + v2(1,1), -- Leave room for room walls.
    dimensions = v2(room_width, room_height),
  }

  return tile_bounds
end

TILE_EMPTY = 0
TILE_FLOOR = 1
TILE_WALL = 2

function draw_tile_rect(tilemap, upper_left, dimensions, tile)
  for y=upper_left.y,upper_left.y+dimensions.y-1 do
    for x=upper_left.x,upper_left.x+dimensions.x-1 do
      assert(tilemap[y], "bad y: " .. y)
      tilemap[y][x] = tile
    end
  end
end

function BoxesNLines:draw_corridor_lr(tilemap, left_bounds, right_bounds, tile)
  -- Pick a random point on the right side of the left_bounds, extend to wall.
  local left_door_xy = v2(
    left_bounds.upper_left.x + left_bounds.dimensions.x,
    rnd_range(left_bounds.upper_left.y, left_bounds.upper_left.y + left_bounds.dimensions.y))

  -- Pick a random point on the left side of the right_bounds, extend to wall.
  local right_door_xy = v2(
    right_bounds.upper_left.x,
    rnd_range(right_bounds.upper_left.y, right_bounds.upper_left.y + right_bounds.dimensions.y))

  -- TODO: I think this could theoretically lead to e.g. an upwards corridor and
  -- a rightwards corridor overlapping. Moving to the edge of each metatile
  -- should fix it, though.
  local wall_column = flr((left_door_xy.x + right_door_xy.x) / 2)
  -- Draw to the wall column from the left door.
  draw_tile_rect(tilemap, left_door_xy, v2(wall_column - left_door_xy.x,1), tile)
  -- And the right.
  -- -1 to start drawing from the tile immediately to the right of the wall column.
  local right_hall_length = right_door_xy.x - wall_column - 1
  draw_tile_rect(tilemap, right_door_xy - v2(right_hall_length,0), v2(right_hall_length,1), tile)

  -- Draw remaining corridor.
  local top = min(left_door_xy.y, right_door_xy.y)
  local bottom = max(left_door_xy.y, right_door_xy.y)
  draw_tile_rect(tilemap, v2(wall_column, top), v2(1, bottom-top+1), tile)
end

function BoxesNLines:draw_corridor_ud(tilemap, up_bounds, down_bounds, tile)
  -- Pick a random point on the bottom side of the up_bounds, extend to wall.
  local up_door_xy = v2(
    rnd_range(up_bounds.upper_left.x, up_bounds.upper_left.x + up_bounds.dimensions.x),
    up_bounds.upper_left.y + up_bounds.dimensions.y)

  -- Pick a random point on the top side of the down_bounds, extend to wall.
  local down_door_xy = v2(
    rnd_range(down_bounds.upper_left.x, down_bounds.upper_left.x + down_bounds.dimensions.x),
    down_bounds.upper_left.y)

  local wall_row = flr((up_door_xy.y + down_door_xy.y) / 2)
  -- Draw to the wall row from the upper door.
  draw_tile_rect(tilemap, up_door_xy, v2(1, wall_row - up_door_xy.y), tile)
  -- And the lower door.
  -- -1 to start drawing from the tile immediately below the wall row.
  local down_hall_length = down_door_xy.y - wall_row - 1
  draw_tile_rect(tilemap, down_door_xy - v2(0,down_hall_length), v2(1, down_hall_length), tile)

  -- Draw remaining corridor.
  local left = min(up_door_xy.x, down_door_xy.x)
  local right = max(up_door_xy.x, down_door_xy.x)
  draw_tile_rect(tilemap, v2(left, wall_row), v2(right-left+1, 1), tile)
end

function BoxesNLines:draw_corridor(tilemap, rooms, from_xy, to_xy, tile)
  if from_xy.x == to_xy.x then
    if from_xy.y < to_xy.y then
      self:draw_corridor_ud(tilemap, rooms[from_xy.y][from_xy.x].tile_bounds, rooms[to_xy.y][to_xy.x].tile_bounds, tile)
    else
      self:draw_corridor_ud(tilemap, rooms[to_xy.y][to_xy.x].tile_bounds, rooms[from_xy.y][from_xy.x].tile_bounds, tile)
    end
  elseif from_xy.y == to_xy.y then
    if from_xy.x < to_xy.x then
      self:draw_corridor_lr(tilemap, rooms[from_xy.y][from_xy.x].tile_bounds, rooms[to_xy.y][to_xy.x].tile_bounds, tile)
    else
      self:draw_corridor_lr(tilemap, rooms[to_xy.y][to_xy.x].tile_bounds, rooms[from_xy.y][from_xy.x].tile_bounds, tile)
    end
  else
    assert(false, "Non-cardinal connection found.")
  end
end

OBJECT_STAIRS_UP = 1
OBJECT_STAIRS_DOWN = 2

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
        draw_tile_rect(tilemap, room.tile_bounds.upper_left - v2(1,1), room.tile_bounds.dimensions + v2(2,2), TILE_WALL)
        draw_tile_rect(tilemap, room.tile_bounds.upper_left, room.tile_bounds.dimensions, TILE_FLOOR)
      end
    end
  end

  local objects = {}
  local stairs_down = nil

  -- Connect the rooms with hallways.
  for my=1,self.height_metatiles do
    for mx=1,self.width_metatiles do
      local room = rooms[my][mx]
      -- from_room is nil if no connection and 0 if it's the original tile.
      if room.room_type == ROOM_NORMAL and room.from_room > 0 then
        self:draw_corridor(tilemap, rooms, V2.from_serialized(room.from_room), v2(mx, my), TILE_FLOOR)
      end

      if room.room_type == ROOM_NORMAL and room.from_room == 0 then
        add(objects, {
          object_type = OBJECT_STAIRS_UP,
          pos = room.tile_bounds.upper_left + room.tile_bounds.dimensions \ 2,
        })
      elseif room.room_type == ROOM_NORMAL and not stairs_down then
        stairs_down = room.tile_bounds.upper_left + room.tile_bounds.dimensions \ 2
      end
    end
  end
  assert(stairs_down)
  add(objects, {
    object_type = OBJECT_STAIRS_DOWN,
    pos = stairs_down,
  })

  return {
    tilemap = tilemap,
    objects = objects,
  }
end
