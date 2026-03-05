local game_state = {}

TILE_SIZE = 8

TURN_UNFINISHED = 1
TURN_FINISHED = 2

TURNS_PLAYER = 1
TURNS_OBJECTS = 2

function _init()
  music(0)
  game_state = {
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
  game_state.tilemap = generator_result.tilemap
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

  write_tilemap_to_map(game_state.tilemap)

  game_state.camera = v2(0,0)

  game_state.player = Player:new{
    pos = start_pos:copy(),
  }
  game_state.objects = {
    Ball:new{
      pos = start_pos:copy(),
    },
  }
  game_state.monsters = {
    Monster:new{
      pos = enemy_pos:copy(),
      sleeping = true,
    },
  }

  local bounds = tilemap_bounds(game_state.tilemap)
  while #game_state.monsters < 20 do
    local mpos = v2(rnd_int(bounds.x), rnd_int(bounds.y))
    if tilemap_at(game_state.tilemap, mpos) == TILE_FLOOR then
      -- TODO: This just randomly (inefficiently) places monsters, but we want
      -- to avoid the player start room at least.
      add(game_state.monsters, Monster:new{
        pos = mpos:copy(),
        sleeping = true,
      })
    end
  end
end

function _draw()
  cls()
  camera(game_state.camera.x, game_state.camera.y)
  map()
  for i=1,#game_state.objects do
    game_state.objects[i]:draw()
  end
  for i=1,#game_state.monsters do
    game_state.monsters[i]:draw()
  end
  game_state.player:draw()

  -- Reset the camera to draw the HUD
  camera()
  game_state.player:draw_life()
end

function _update()
  if game_state.turn == TURNS_PLAYER then
    local turn_state = game_state.player:turn_update(game_state.tilemap, game_state.objects)
    game_state.camera = game_state.player.pos * TILE_SIZE - v2(64,64)
    if turn_state == TURN_FINISHED then
      game_state.turn = TURNS_OBJECTS
    end
  else
    game_state.player:idle_update()
  end

  if game_state.turn == TURNS_OBJECTS then
    local all_done = true
    for i=1,#game_state.objects do
      local turn_state = game_state.objects[i]:turn_update(game_state.tilemap, game_state.monsters)
      if turn_state ~= TURN_FINISHED then
        all_done = false
      end
    end

    if all_done then
      game_state.turn = TURNS_MONSTERS
    end
  else
    for i=1,#game_state.objects do
      game_state.objects[i]:idle_update()
    end
  end

  if game_state.turn == TURNS_MONSTERS then
    local all_done = true
    for i=1,#game_state.monsters do
      local turn_state = game_state.monsters[i]:turn_update(game_state.tilemap, game_state.player)
      if turn_state ~= TURN_FINISHED then
        all_done = false
      end
    end

    if all_done then
      game_state.turn = TURNS_PLAYER
    end
  else
    for i=1,#game_state.monsters do
      game_state.monsters[i]:idle_update()
    end
  end
end
