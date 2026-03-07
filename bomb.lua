Bomb = {
  WAKE_DISTANCE = 10,
  TRIGGER_DISTANCE = 1,
  EXPLOSION_RADIUS = 2,
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
function Bomb:hit_by_ball(hit_dir, monsters, particles)
  -- TODO: Maybe have this increase in pitch as more monsters die in one move?
  sfx(3, 1)
  local particle = {
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
  add(particles, particle)
  monsters[self.pos:serialize()] = nil
end

function make_explosion_particle(from, to, ttl)
  return {
    from = from:copy(),
    to = to:copy(),
    ttl = ttl,
    ticks = 0,
    update = function(self)
      self.ticks += 1
      return self.ticks >= ttl
    end,
    draw = function(self)
      local pos = (self.from + (self.to - self.from) * (self.ticks / self.ttl)) * TILE_SIZE
      -- Randomly flip vert/horiz
      spr(16, pos.x, pos.y, 1, 1, rnd() > 0.5, rnd() > 0.5)
    end,
  }
end

function make_explosion(center, radius)
  local chunks = {}
  for r=radius,0,-1 do
    for i=0,r*2 do
      -- Add lines that make up each concentric radius.
      -- Top left to top right.
      add(chunks, make_explosion_particle(center, center + r * v2(-1,-1) + v2(i, 0), 8))
      -- Top right to bottom right.
      add(chunks, make_explosion_particle(center, center + r * v2(1,-1) + v2(0, i), 8))
      -- Bottom right to bottom left.
      add(chunks, make_explosion_particle(center, center + r * v2(1,1) + v2(-i, 0), 8))
      -- Bottom left to top left.
      add(chunks, make_explosion_particle(center, center + r * v2(-1,1) + v2(0, -i), 8))
    end
  end
  local particle = {
    chunks = chunks,
    update = function(self)
      for i=#self.chunks,1,-1 do
        if self.chunks[i]:update() then
          deli(self.chunks, i)
        end
      end
      return #self.chunks == 0
    end,
    draw = function(self)
      for i=1,#self.chunks do
        self.chunks[i]:draw()
      end
    end,
  }
  return particle
end

-- Returns the spot that the monster would like to move to.
function Bomb:take_turn(tilemap, player, monsters, camera, particles)
  if self.state == Bomb.STATE_SLEEPING then
    local player_dist = chessboard_distance(player.pos, self.pos)
    if player_dist < Bomb.WAKE_DISTANCE then
      self.state = Bomb.STATE_CHASING
      -- TODO: Play an animation, make a noise, something.
    end
  elseif self.state == Bomb.STATE_CHASING then
    local path = astar(tilemap, self.pos, player.pos, Bomb.WAKE_DISTANCE)
    if not path then
      self.state = Bomb.STATE_SLEEPING
    else
      assert(#path > 0)
      if path[1] ~= player.pos and not monsters[path[1]:serialize()] then
        move_monster(monsters, self, path[1])
      end
      if chessboard_distance(self.pos, player.pos) <= Bomb.TRIGGER_DISTANCE then
        self.state = Bomb.STATE_TICKING
        self.explode_countdown = 3
        self.ticks_since_triggered = 0
      end
    end
  elseif self.state == Bomb.STATE_TICKING then
    self.explode_countdown -= 1
    if self.explode_countdown <= 0 then
      if chessboard_distance(self.pos, player.pos) <= Bomb.EXPLOSION_RADIUS then
        player:hurt()
      end
      sfx(5,3)
      add(particles, make_explosion(self.pos, Bomb.EXPLOSION_RADIUS))
      camera:shake(v2(0,4), 8, 20)
      monsters[self.pos:serialize()] = nil
    end
  end
end

function Bomb:idle_update()
  if self.state == Bomb.STATE_TICKING then
    self.ticks_since_triggered += 1
  end
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

  local sprnum = 13
  if self.state == Bomb.STATE_TICKING then
    -- This is in flashes per second.
    local frequency_table = {10,5,2}
    local frequency = frequency_table[self.explode_countdown] or 2
    if frequency_pulse(self.ticks_since_triggered, frequency) then
      -- Flash with anger.
      sprnum = 15
    end
  end

  local draw_pos = self.pos * TILE_SIZE + v2(0, -3) + self:offset()
  local size_mod = 0
  -- This will only work with sprites in the same row.
  sspr(sprnum*8,0,8,8,draw_pos.x - size_mod / 2,draw_pos.y - size_mod / 2, TILE_SIZE + size_mod, TILE_SIZE + size_mod)
end
