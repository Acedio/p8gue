local game_state = {}

function _init()
  game_state = {}
  local generator = BoxesNLines:new{
    width_metatiles = 8,
    height_metatiles = 6,
    metatile_width_tiles = 16,
    metatile_height_tiles = 12,
  }
  game_state.tilemap = generator:generate()
  for y=1,#game_state.tilemap do
    for x=1,#game_state.tilemap[y] do
      if game_state.tilemap[y][x] == TILE_FLOOR then
        mset(y-1,x-1,2)
      end
    end
  end
end

function _draw()
  cls()
  map()
end

function _update()
end
