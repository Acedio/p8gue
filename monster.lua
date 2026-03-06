Monster = {}

function Monster:new(o)
  local o = o or {}
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

-- Returns a particle.
function Monster:die(hit_dir)
  -- TODO: Maybe have this increase in pitch as more monsters die in one move?
  sfx(3, 1)
  return {
    pos = self.pos,
    death_dir = hit_dir:copy(),
    ticks = 0,
    update = function(self)
      self.ticks += 1
    end,
    draw = function(self)
      -- TODO: Shadow
      local draw_pos = self.pos * TILE_SIZE
      -- bounce
      draw_pos += v2(0, -30*abs(sin(self.ticks/10)))
      -- in the death direction
      draw_pos += self.death_dir * self.ticks * 5
      spr(8, draw_pos.x, draw_pos.y)
    end,
  }
end

function Monster:move_target(tilemap, player)
  self.shake_ticks = 0
  if self.sleeping then
    local player_dist = chebyshev_distance(player.pos, self.pos)
    if player_dist < WAKE_DISTANCE then
      self.wait_ticks = 1
      self.sleeping = false
      -- TODO: Play an animation, make a noise, something.
    end
    return self.pos
  else
    local path = astar(tilemap, self.pos, player.pos, WAKE_DISTANCE)
    if not path then
      self.sleeping = true
    else
      -- TODO: assert(#path > 0, "Monster is on the player.")
      if self.wait_ticks > 0 then
        self.wait_ticks -= 1
      elseif #path > 0 then
        self.wait_ticks = 1
        return path[1]:copy()
      end
    end
  end

  return self.pos
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
