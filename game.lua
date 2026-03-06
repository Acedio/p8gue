Game = {}

function Game:new()
  local o = {}
  setmetatable(o, self)
  self.__index = self
  o:init()
  return o
end

TILE_SIZE = 8

TURN_UNFINISHED = 1
TURN_FINISHED = 2

TURNS_PLAYER = 1
TURNS_OBJECTS = 2

function Game:init()
  music(0)
  self.state = {
    turn = TURNS_PLAYER,
  }
  local generator = BoxesNLines:new{
    width_metatiles = 4,
    height_metatiles = 4,
    metatile_width_tiles = 12,
    metatile_height_tiles = 10,
  }

  local seed = rnd_int(33333)
  if SEED then
    print("Loaded seed.")
    seed = SEED
  end
  printh("SEED = " .. seed, "last_seed.txt", true)
  srand(seed)
  local generator_result = generator:generate()
  self.state.tilemap = generator_result.tilemap
  local start_pos = nil
  local enemy_pos = nil
  for i=1,#generator_result.objects do
    if generator_result.objects[i].object_type == OBJECT_STAIRS_UP then
      start_pos = generator_result.objects[i].pos:copy()
    elseif generator_result.objects[i].object_type == OBJECT_STAIRS_DOWN then
      enemy_pos = generator_result.objects[i].pos:copy()
    end
  end
  assert(start_pos, "Couldn't find start_pos.")
  assert(enemy_pos, "Couldn't find start_pos.")

  write_tilemap_to_map(self.state.tilemap)

  self.state.camera = v2(0,0)

  self.state.player = Player:new{
    pos = start_pos:copy(),
  }
  self.state.objects = {
    Ball:new{
      pos = start_pos:copy(),
    },
  }
  self.state.monsters = {
    Monster:new{
      pos = enemy_pos:copy(),
      sleeping = true,
    },
  }

  local bounds = tilemap_bounds(self.state.tilemap)
  while #self.state.monsters < 20 do
    local mpos = v2(rnd_int(bounds.x), rnd_int(bounds.y))
    if tilemap_at(self.state.tilemap, mpos) == TILE_FLOOR then
      -- TODO: This just randomly (inefficiently) places monsters, but we want
      -- to avoid the player start room at least.
      add(self.state.monsters, Monster:new{
        pos = mpos:copy(),
        sleeping = true,
      })
    end
  end
end

function Game:draw()
  cls()
  camera(self.state.camera.x, self.state.camera.y)
  map()
  self.state.player:draw_aim()
  for i=1,#self.state.objects do
    self.state.objects[i]:draw()
  end
  for i=1,#self.state.monsters do
    self.state.monsters[i]:draw()
  end
  self.state.player:draw()

  -- Reset the camera to draw the HUD
  camera()
  self.state.player:draw_life()
end

function Game:update()
  if self.state.turn == TURNS_PLAYER then
    local turn_state = self.state.player:turn_update(self.state.tilemap, self.state.objects)
    self.state.camera = self.state.player.pos * TILE_SIZE - v2(64,64)
    if turn_state == TURN_FINISHED then
      self.state.turn = TURNS_OBJECTS
    end
  else
    self.state.player:idle_update()
  end

  if self.state.turn == TURNS_OBJECTS then
    local all_done = true
    for i=1,#self.state.objects do
      local turn_state = self.state.objects[i]:turn_update(self.state.tilemap, self.state.monsters)
      if turn_state ~= TURN_FINISHED then
        all_done = false
      end
    end

    if all_done then
      self.state.turn = TURNS_MONSTERS
    end
  else
    for i=1,#self.state.objects do
      self.state.objects[i]:idle_update()
    end
  end

  if self.state.turn == TURNS_MONSTERS then
    local all_done = true
    for i=1,#self.state.monsters do
      local turn_state = self.state.monsters[i]:turn_update(self.state.tilemap, self.state.player)
      if turn_state ~= TURN_FINISHED then
        all_done = false
      end
    end

    if all_done then
      self.state.turn = TURNS_PLAYER
    end
  else
    for i=1,#self.state.monsters do
      self.state.monsters[i]:idle_update()
    end
  end

  return false -- call again plz
end
