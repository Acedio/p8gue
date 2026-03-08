Title = {
  MAX_SCROLL_TICKS = 30,
}

function Title:new()
  local o = {}
  setmetatable(o, self)
  self.__index = self
  o:init()
  return o
end

function Title:init()
  music(-1)
  self.scroll_ticks = 0
  self.title_text = bubbletext("boggarts & billiards", v2(nil, 42))
end

function Title:update()
  self.scroll_ticks += 1
  if self.scroll_ticks == Title.MAX_SCROLL_TICKS then
    sfx(7)
  end
  if self.scroll_ticks >= Title.MAX_SCROLL_TICKS then
    self.title_text:update()
  end
  if btnp(4) or btnp(5) then
    return true
  end
end

function centered_outline_text(text, y, bg, fg)
  print(text, 64 - #text * 2 + 1, y, bg)
  print(text, 64 - #text * 2 - 1, y, bg)
  print(text, 64 - #text * 2, y + 1, bg)
  print(text, 64 - #text * 2, y - 1, bg)
  print(text, 64 - #text * 2, y, fg)
end

function Title:draw()
  cls(2)
  local top = 20
  local completion = min(self.scroll_ticks, Title.MAX_SCROLL_TICKS) / Title.MAX_SCROLL_TICKS
  local bottom = 20 + TILE_SIZE + 40 * completion
  local left = 12
  local right = 116
  rectfill(left,top,right-1,bottom,15)
  rectfill(left+TILE_SIZE/2,bottom,right,bottom+TILE_SIZE-1,4)
  spr(32,left-TILE_SIZE,top)
  spr(35,right-TILE_SIZE,top)
  spr(33,left,bottom)
  spr(34,right,bottom)
  self.title_text:draw()
  local author_y = 100
  local author = "a 7drl by acedio"
  centered_outline_text(author, author_y, 0, 7)
  spr(4, 97, author_y - 2, 1, 1, true)
end
