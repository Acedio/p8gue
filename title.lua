Title = {}

function Title:new()
  local o = {}
  setmetatable(o, self)
  self.__index = self
  o:init()
  for k,v in pairs(o) do
    printh(k)
  end
  return o
end

function Title:init()
  self.title_text = bubbletext("boggarts & billiards", v2(nil, 30))
  for k,v in pairs(self) do
    printh(k)
  end
end

function Title:update()
  self.title_text:update()
  if btnp(4) or btnp(5) then
    return true
  end
end

function Title:draw()
  cls(2)
  self.title_text:draw()
end
