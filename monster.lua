Monster = {}

function Monster:new(o)
  o = o or {}
  o.wait_ticks = 0
  o.shake_ticks = 0
  setmetatable(o, self)
  self.__index = self
  return o
end

WAKE_DISTANCE = 10

function chebyshev_distance(a, b)
  local delta = a - b
  return max(abs(delta.x), abs(delta.y))
end

function Monster:turn_update(tilemap, player)
  self.shake_ticks = 0
  if self.sleeping then
    local player_dist = chebyshev_distance(player.pos, self.pos)
    if player_dist < WAKE_DISTANCE then
      self.wait_ticks = 1
      self.sleeping = false
      -- TODO: Play an animation, make a noise, something.
    end
  else
    local path = astar(tilemap, self.pos, player.pos, WAKE_DISTANCE)
    if not path then
      self.sleeping = true
    else
      -- TODO: assert(#path > 0, "Monster is on the player.")
      if self.wait_ticks > 0 then
        self.wait_ticks -= 1
      elseif #path > 0 then
        self.pos = path[1]:copy()
        self.wait_ticks = 1
      end
    end
  end

  return TURN_FINISHED
end

function Monster:idle_update()
  if self.wait_ticks == 0 then
    self.shake_ticks += 1
  end
end

function Monster:offset()
  local offset = v2(sin(self.shake_ticks/5) * 1,0)
  return offset
end

function Monster:draw_shadow()
  local midfoot = self.pos * TILE_SIZE + v2(4,4) + self:offset()
  ovalfill(midfoot.x-2, midfoot.y-1, midfoot.x+2, midfoot.y+1, 5)
end

function Monster:draw()
  self:draw_shadow()
  local draw_pos = self.pos * TILE_SIZE + v2(0, -3) + self:offset()
  local sprnum = 6
  local size_mod = sin(self.shake_ticks/6)*2
  sspr(sprnum*8,0,8,8,draw_pos.x - size_mod / 2,draw_pos.y - size_mod / 2, TILE_SIZE + size_mod, TILE_SIZE + size_mod)
end
