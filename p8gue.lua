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
end

function _draw()
  cls()
  map()
end

function _update()
end
