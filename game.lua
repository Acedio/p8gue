Game = {
  GAME_MADA_MADA = 1,
  GAME_LOSE = 2,
  GAME_WIN = 3,
  MONSTER_SPAWN_MIN_RADIUS = 8,
  FLOOR_COMPOSITIONS = {
    [1] = {
      monster_count = 20,
      make_monster = function(pos)
        return Monster:new{
          pos = pos:copy(),
          sleeping = true,
        }
      end,
    },
    [2] = {
      monster_count = 20,
      make_monster = function(pos)
        if rnd_int(2) == 0 then
          return Monster:new{
            pos = pos:copy(),
            sleeping = true,
          }
        else
          return Bomb:new{
            pos = pos:copy(),
            state = Bomb.STATE_SLEEPING,
          }
        end
      end,
    },
    [3] = {
      monster_count = 30,
      make_monster = function(pos)
        if rnd_int(3) == 0 then
          return Monster:new{
            pos = pos:copy(),
            sleeping = true,
          }
        else
          return Bomb:new{
            pos = pos:copy(),
            state = Bomb.STATE_SLEEPING,
          }
        end
      end,
    },
  },
}

function Game:new()
  local o = {}
  setmetatable(o, self)
  self.__index = self
  o:init()
  return o
end

TILE_SIZE = 8
UPDATE_FREQ = 30

TURN_UNFINISHED = 1
TURN_FINISHED = 2

TURNS_PLAYER = 1
TURNS_OBJECTS = 3
TURNS_MONSTERS = 5

ANIMATION_COMPLETE = 1
ANIMATION_MADA_MADA = 2

function Game:init_floor(seed, player)
  srand(seed)

  local generator = BoxesNLines:new{
    width_metatiles = 4,
    height_metatiles = 4,
    metatile_width_tiles = 12,
    metatile_height_tiles = 10,
  }
  local generator_result = generator:generate()
  self.next_level_seed = rnd_int(33333)

  self.tilemap = generator_result.tilemap
  local start_pos = nil
  self.stairs_pos = nil
  for i=1,#generator_result.objects do
    if generator_result.objects[i].object_type == OBJECT_STAIRS_UP then
      start_pos = generator_result.objects[i].pos:copy()
    elseif generator_result.objects[i].object_type == OBJECT_STAIRS_DOWN then
      self.stairs_pos = generator_result.objects[i].pos:copy()
    end
  end
  assert(start_pos, "Couldn't find start_pos.")
  assert(self.stairs_pos, "Couldn't find stairs down.")

  write_tilemap_to_map(self.tilemap)

  player.pos = start_pos:copy()
  self.objects = {
    Ball:new{
      pos = start_pos:copy(),
    },
  }
  self.monsters = self:monsters_for_floor(self.level_number, player)

  self.particles = {}
end

function Game:monsters_for_floor(level_number, player)
  local monsters = {}

  local bounds = tilemap_bounds(self.tilemap)
  local monster_count = 0
  while monster_count < 20 do
    local mpos = v2(rnd_int(bounds.x), rnd_int(bounds.y))
    local key = mpos:serialize()
    -- TODO: This just randomly places monsters, should be better.
    if tilemap_at(self.tilemap, mpos) == TILE_FLOOR and chessboard_distance(mpos, player.pos) >= Game.MONSTER_SPAWN_MIN_RADIUS and not monsters[key] then
      monster_count += 1
      monsters[key] = Game.FLOOR_COMPOSITIONS[level_number].make_monster(mpos)
    end
  end

  return monsters
end

function move_monster(monsters, monster, to)
  assert(monsters[monster.pos:serialize()] == monster)
  assert(monsters[to:serialize()] == nil)
  monsters[monster.pos:serialize()] = nil
  monsters[to:serialize()] = monster
  monster.pos = to:copy()
end

function Game:init()
  music(0)
  self.turn = TURNS_PLAYER

  local seed = rnd_int(33333)
  if SEED then
    print("Loaded seed.")
    seed = SEED
  end
  printh("SEED = " .. seed, "last_seed.txt", true)

  self.level_number = 2 -- TODO
  self.player = Player:new{}
  self:init_floor(seed, self.player)

  self.camera = Camera:new{
    pos = self.player.pos:copy()
  }
end

function Game:draw()
  cls()
  self.camera:point()
  map()
  spr(14, self.stairs_pos.x * TILE_SIZE, self.stairs_pos.y * TILE_SIZE)
  self.player:draw_aim()
  for i=1,#self.objects do
    self.objects[i]:draw()
  end
  for _, monster in pairs(self.monsters) do
    monster:draw()
  end
  self.player:draw()

  for i=1,#self.particles do
    self.particles[i]:draw()
  end

  -- Reset the (pico) camera to draw the HUD
  camera()
  self.player:draw_life()
end

function Game:update()
  self.camera:update()
  if self.turn == TURNS_PLAYER then
    local turn_state = self.player:turn_update(self.tilemap, self.objects, self.monsters)
    self.camera.pos = self.player.pos * TILE_SIZE
    if turn_state == TURN_FINISHED then
      if self.player.pos == self.stairs_pos then
        -- It stays the players turn if we go down stairs.
        self.player.held = nil
        if self.level_number < 3 then
          self.level_number += 1
          self:init_floor(self.next_level_seed, self.player)
        else
          return Game.GAME_WIN
        end
      else
        self.turn = TURNS_OBJECTS
      end
    end
  else
    self.player:idle_update()
  end

  if self.turn == TURNS_OBJECTS then
    local all_done = true
    for i=1,#self.objects do
      local turn_state = self.objects[i]:turn_update(self.tilemap, self.monsters, self.particles)
      if turn_state ~= TURN_FINISHED then
        all_done = false
      end
    end

    if all_done then
      self.turn = TURNS_MONSTERS
    end
  else
    for i=1,#self.objects do
      self.objects[i]:idle_update()
    end
  end

  if self.turn == TURNS_MONSTERS then
    -- Make a list so that we can modify monster keys while traversing.
    local monsters_list = {}
    for _, monster in pairs(self.monsters) do
      add(monsters_list, monster)
    end
    for monster in all(monsters_list) do
      -- This only works if monsters move a set number of spaces all at once. A
      -- rolling ball monster, for example, will need to interact frame by
      -- frame.
      monster:take_turn(self.tilemap, self.player, self.monsters, self.camera, self.particles)
    end

    self.turn = TURNS_PLAYER
  else
    for _, monster in pairs(self.monsters) do
      monster:idle_update()
    end
  end

  -- This'll only work if we never have particles add new particles. Seems fine.
  for i=#self.particles,1,-1 do
    if self.particles[i]:update() then
      deli(self.particles[i])
    end
  end

  if self.player.life <= 0 then
    return Game.GAME_LOSE
  else
    return Game.GAME_MADA_MADA
  end
end
