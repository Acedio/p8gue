local game_state = {}

TILE_SIZE = 8

TURN_UNFINISHED = 1
TURN_FINISHED = 2

TURNS_PLAYER = 1
TURNS_OBJECTS = 2

function _init()
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
  for i=1,#generator_result.objects do
    if generator_result.objects[i].object_type == OBJECT_STAIRS_UP then
      start_pos = generator_result.objects[i].pos:copy()
    end
  end
  assert(start_pos, "Couldn't find start_pos.")
  printh("start_pos: " .. start_pos.x .. " " .. start_pos.y)

  for y=1,#game_state.tilemap do
    for x=1,#game_state.tilemap[y] do
      local tile = game_state.tilemap[y][x]
      if tile == TILE_FLOOR then
        mset(x-1,y-1,1)
      elseif tile == TILE_WALL then
        mset(x-1,y-1,2)
      end
    end
  end

  game_state.camera = v2(0,0)

  game_state.player = Player:new{
    pos = start_pos:copy(),
  }
  game_state.objects = {
    Ball:new{
      pos = start_pos:copy(),
      vel = v2(0,0),
    },
  }
end

function _draw()
  cls()
  camera(game_state.camera.x, game_state.camera.y)
  map()
  for i=1,#game_state.objects do
    game_state.objects[i]:draw()
  end
  game_state.player:draw()
end

function _update()
  if game_state.turn == TURNS_PLAYER then
    local turn_state = game_state.player:turn_update(game_state.tilemap, game_state.objects)
    game_state.camera = game_state.player.pos * TILE_SIZE - v2(64,64)
    if turn_state == TURN_FINISHED then
      game_state.turn = TURNS_OBJECTS
    end
  else 
    local all_done = true
    for i=1,#game_state.objects do
      local turn_state = game_state.objects[i]:turn_update(tilemap)
      if turn_state ~= TURN_FINISHED then
        all_done = false
      end
    end

    if all_done then
      game_state.turn = TURNS_PLAYER
    end
  end
end
