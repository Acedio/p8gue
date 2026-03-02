Ball = {}

function Ball:new(o)
  o = o or {}
  setmetatable(o, self)
  self.__index = self
  return o
end

function Ball:update(tilemap)
  self.pos = self.pos + self.vel
  self.vel = self.vel * 0.9
end

function Ball:draw()
  local midfoot = self.pos + v2(4,4)
  ovalfill(midfoot.x-2, midfoot.y-1, midfoot.x+2, midfoot.y+1, 5)
  spr(5, self.pos.x, self.pos.y - 3)
end
