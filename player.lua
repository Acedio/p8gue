Player = {}

function Player:new(o)
  o = o or {}
  setmetatable(o, self)
  self.__index = self
  return o
end

function Player:init()
  self.SPEED = 2
  self.x = 0
  self.y = 0
  self.frames_moved = 0
end

function Player:y_offset()
  return abs(3*sin(self.frames_moved / 10))
end

function Player:draw()
  spr(4, self.x, self.y - self:y_offset(), 1, 1, self.facing_left)
end

function Player:update()
  local moved = false
  if btn(0) then -- Left
    self.facing_left = true
    self.x -= self.SPEED
    moved = true
  end
  if btn(1) then -- Right
    self.facing_left = false
    self.x += self.SPEED
    moved = true
  end
  if btn(2) then -- Up
    self.y -= self.SPEED
    moved = true
  end
  if btn(3) then -- Down
    self.y += self.SPEED
    moved = true
  end
  if moved then
    self.frames_moved += 1
  else
    if self:y_offset() == 0 then
      self.frames_moved = 0
    else
      -- Keep incrementing until we get to a resting point.
      self.frames_moved += 1
    end
  end
end
