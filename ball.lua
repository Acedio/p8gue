Ball = {}

function Ball:new(o)
  o = o or {}
  setmetatable(o, self)
  self.__index = self
  return o
end

function Ball:throw(pos, vel)
  self.pos = pos:copy()
  self.vel = vel:copy()
end

-- Will be called repeatedly, once per game frame, until this returns
-- TURN_FINISHED to indicate it is done taking its turn.
function Ball:turn_update(tilemap)
  if not self.taking_turn then
    self.taking_turn = true
    -- TODO: init turn taking stuff
  end

  if self.vel.x > 0 then
    self.pos.x = self.pos.x + 1
    self.vel.x -= 1
  elseif self.vel.x < 0 then
    self.pos.x = self.pos.x - 1
    self.vel.x += 1
  end
  if self.vel.y > 0 then
    self.pos.y = self.pos.y + 1
    self.vel.y -= 1
  elseif self.vel.y < 0 then
    self.pos.y = self.pos.y - 1
    self.vel.y += 1
  end

  if self.vel == v2(0,0) then
    self.taking_turn = false
    return TURN_FINISHED
  end
  return TURN_UNFINISHED
end

-- Called to update during each game frame while it is not this object's turn.
function Ball:idle_update()
end

function Ball:draw()
  local midfoot = self.pos * TILE_SIZE + v2(4,4)
  ovalfill(midfoot.x-2, midfoot.y-1, midfoot.x+2, midfoot.y+1, 5)
  spr(5, self.pos.x * TILE_SIZE, self.pos.y * TILE_SIZE - 3)
end

function Ball:draw_held(pos)
  spr(5, pos.x, pos.y - 5)
end
