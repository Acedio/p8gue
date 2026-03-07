Monster = {
  WAKE_DISTANCE = 10,
  BOUNCE_FREQUENCY = 3,
}

function Monster:new(o)
  local o = o or {}
  o.turns_to_wait = 0
  o.shake_ticks = 0
  o.alive_ticks = 0
  setmetatable(o, self)
  self.__index = self
  return o
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

-- Returns the spot that the monster would like to move to.
function Monster:move_target(tilemap, player, monsters)
  self.shake_ticks = 0
  if self.sleeping then
    local player_dist = chessboard_distance(player.pos, self.pos)
    if player_dist < Monster.WAKE_DISTANCE then
      self.turns_to_wait = 1
      self.sleeping = false
      -- TODO: Play an animation, make a noise, something.
    end
    return self.pos
  else
    local path = astar(tilemap, self.pos, player.pos, Monster.WAKE_DISTANCE)
    if not path then
      self.sleeping = true
    else
      if self.turns_to_wait > 0 then
        self.turns_to_wait -= 1
      elseif #path > 0 then
        self.turns_to_wait = 1
        if player.pos == path[1] then
          -- Attack the player if we're right next to them.
          -- TODO: Animate.
          player:hurt()
          return self.pos
        end
        return path[1]:copy()
      end
    end
  end

  return self.pos
end

function Monster:idle_update()
  self.alive_ticks += 1
  if self.turns_to_wait == 0 then
    self.shake_ticks += 1
  end
end

function Monster:offset()
  local bouncing = not self.sleeping and frequency_pulse(self.alive_ticks, Monster.BOUNCE_FREQUENCY)
  local offset = v2(sin(self.shake_ticks/5) * 1,bouncing and -1 or 0)
  return offset
end

function Monster:draw_shadow()
  -- Assume that all y offsets are to indicate height and not north/south
  -- movement.
  local midfoot = self.pos * TILE_SIZE + v2(4,4) + v2(self:offset().x, 0)
  ovalfill(midfoot.x-2, midfoot.y-1, midfoot.x+2, midfoot.y+1, 5)
end

function Monster:draw()
  self:draw_shadow()
  local draw_pos = self.pos * TILE_SIZE + v2(0, -3) + self:offset()
  local sprnum = 6
  local size_mod = sin(self.shake_ticks/6)*2
  sspr(sprnum*8,0,8,8,draw_pos.x - size_mod / 2,draw_pos.y - size_mod / 2, TILE_SIZE + size_mod, TILE_SIZE + size_mod)
end
