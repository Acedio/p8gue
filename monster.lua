Monster = {}

function Monster:new(o)
  o = o or {}
  setmetatable(o, self)
  self.__index = self
  return o
end

WAKE_DISTANCE = 10

function Monster:turn_update(tilemap, player)
  if self.sleeping then
    local player_dist = abs(player.pos.x - self.pos.x) + abs(player.pos.y - self.pos.y)
    printh("player dist: " .. player_dist)
    if player_dist < WAKE_DISTANCE then
      self.sleeping = false
      -- TODO: Play an animation, make a noise, something.
    end
    return TURN_FINISHED
  end

  local target = self.pos:copy()
  if player.pos.x > self.pos.x then
    target.x += 1
  elseif player.pos.x < self.pos.x then
    target.x -= 1
  end
  if player.pos.y > self.pos.y then
    target.y += 1
  elseif player.pos.y < self.pos.y then
    target.y -= 1
  end
  
  if tilemap[target.y + 1][target.x + 1] == TILE_FLOOR then
    self.pos = target
  end

  return TURN_FINISHED
end

function Monster:idle_update(tilemap)
end

function Monster:draw_shadow()
  local midfoot = self.pos * TILE_SIZE + v2(4,4)
  ovalfill(midfoot.x-2, midfoot.y-1, midfoot.x+2, midfoot.y+1, 5)
end

function Monster:y_offset()
  return 0
end

function Monster:draw()
  self:draw_shadow()
  local draw_pos = self.pos * TILE_SIZE + v2(0, -3 - self:y_offset())
  spr(6, draw_pos.x, draw_pos.y)
end
