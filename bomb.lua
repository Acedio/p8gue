Bomb = {
  WAKE_DISTANCE = 10,
  EXPLODE_DISTANCE = 2,
  STATE_SLEEPING = 1,
  STATE_CHASING = 2,
  STATE_TICKING = 3,
}

function Bomb:new(o)
  local o = o or {}
  setmetatable(o, self)
  self.__index = self
  return o
end

-- TODO: Bombs don't die when hit with a ball. Probably need to update name.
function Bomb:die(hit_dir)
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
function Bomb:move_target(tilemap, player, monsters)
  if self.state == Bomb.STATE_SLEEPING then
    local player_dist = chessboard_distance(player.pos, self.pos)
    if player_dist < Bomb.WAKE_DISTANCE then
      self.state = Bomb.STATE_CHASING
      -- TODO: Play an animation, make a noise, something.
    end
    return self.pos
  elseif self.state == Bomb.STATE_CHASING then
    local path = astar(tilemap, self.pos, player.pos, Bomb.WAKE_DISTANCE)
    if not path then
      self.state = Bomb.STATE_SLEEPING
    else
      if chessboard_distance(self.pos, player.pos) <= Bomb.EXPLODE_DISTANCE then
        self.state = Bomb.STATE_TICKING
        self.explode_ticks = 3
      else
        assert(#path > 0)
        return path[1]:copy()
      end
    end
  elseif self.state == Bomb.STATE_TICKING then
    self.explode_ticks -= 1
    if self.explode_ticks <= 0 then
      if chessboard_distance(self.pos, player.pos) <= 2 then
        player:hurt()
      end
      -- TODO: Animation.
      monsters[self.pos:serialize()] = nil
    end
  end

  return self.pos
end

function Bomb:idle_update()
end

function Bomb:offset()
  return v2(0,0)
end

function Bomb:draw_shadow()
  local midfoot = self.pos * TILE_SIZE + v2(4,4) + self:offset()
  ovalfill(midfoot.x-2, midfoot.y-1, midfoot.x+2, midfoot.y+1, 5)
end

function Bomb:draw()
  self:draw_shadow()
  local draw_pos = self.pos * TILE_SIZE + v2(0, -3) + self:offset()
  local sprnum = 13
  local size_mod = 0
  sspr(sprnum*8,0,8,8,draw_pos.x - size_mod / 2,draw_pos.y - size_mod / 2, TILE_SIZE + size_mod, TILE_SIZE + size_mod)
end
