local game_state = {}

function _init()
  game_state = {}
  local generator = BoxesNLines:new{
    meta_width = 16,
    meta_height = 12,
    tile_width = 32,
    tile_height = 24,
  }
  game_state.meta_tiles = generator:generate()
  for y=1,generator.meta_height do
    for x=1,generator.meta_width do
      if game_state.meta_tiles[y][x] then
        mset(x-1, y-1, 1)
      else
        mset(x-1, y-1, 2)
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
