WinScene = {}

function WinScene:new()
  local o = {}
  setmetatable(o, self)
  self.__index = self
  o:init()
  return o
end

function WinScene:init()
  music(-1)
  sfx(7,-1)
  self.ticks = 0
  self.title_text = bubbletext("boggarts & billiards", v2(nil, 30))
  self.burger_text = bubbletext("...& burgers ♥", v2(nil, 42))
  self.thanks_text = bubbletext("thank you for playing!", v2(nil, 106))
end

function WinScene:update()
  self.ticks += 1
  if self.title_text:update() then
    if self.burger_text:update() then
      self.thanks_text:update()
    end
  end
  if btnp(4) or btnp(5) then
    return true
  end
end

function WinScene:draw()
  cls(2)
  self.title_text:draw()
  self.burger_text:draw()
  self.thanks_text:draw()

  spr(4, 55, 70 - 4 * abs(sin(self.ticks / 15)))
  spr(18, 60, 60)
  spr(17, 65, 70)
  spr(5, 40, 70)
end
