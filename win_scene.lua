WinScene = {}

function WinScene:new()
  local o = {}
  setmetatable(o, self)
  self.__index = self
  o:init()
  return o
end

function WinScene:init()
  self.title_text = bubbletext("you win!!!", v2(nil, 30))
end

function WinScene:update()
  self.title_text:update()
  if btnp(4) or btnp(5) then
    return true
  end
end

function WinScene:draw()
  cls(3)
  self.title_text:draw()
end
