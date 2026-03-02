local game_state = {}

TILE_SIZE = 8

function _init()
  game_state = {}
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
  game_state.tilemap = generator:generate()

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

  game_state.player = Player:new()
  game_state.player:init()
  game_state.balls = {}
end

function _draw()
  cls()
  camera(game_state.camera.x, game_state.camera.y)
  map()
  for i=1,#game_state.balls do
    game_state.balls[i]:draw()
  end
  game_state.player:draw()
end

function _update()
  game_state.player:update(game_state.tilemap)
  game_state.camera = game_state.player.pos * TILE_SIZE - v2(64,64)
  for i=1,#game_state.balls do
    game_state.balls[i]:update(tilemap)
  end
end
