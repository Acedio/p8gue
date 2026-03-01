local game_state = {}

function _init()
  game_state = {}
  local generator = BoxesNLines:new{
    width_metatiles = 8,
    height_metatiles = 6,
    metatile_width_tiles = 12,
    metatile_height_tiles = 12,
  }
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
end

function _draw()
  cls()
  camera(game_state.camera.x, game_state.camera.y)
  map()
end

function _update()
  if btn(0) then -- Left
    game_state.camera.x -= 8
  end
  if btn(1) then -- Right
    game_state.camera.x += 8
  end
  if btn(2) then -- Up
    game_state.camera.y -= 8
  end
  if btn(3) then -- Down
    game_state.camera.y += 8
  end
end
