Ball = {}

function Ball:new(o)
  o = o or {}
  -- Measures how many more moves the ball has left before stopping.
  self.energy = 0
  self.dir = v2(0,0)
  setmetatable(o, self)
  self.__index = self
  return o
end

function Ball:throw(pos, dir)
  self.pos = pos:copy()
  self.dir = dir:copy()
  self.energy = 10
end

function Ball:roll(tilemap)
  self.energy -= 1

  local target = self.pos + self.dir
  if tilemap_at(tilemap, target) == TILE_FLOOR then
    -- Can't stop me now.
    self.pos = target
  elseif self.dir.x == 0 or self.dir.y == 0 then
    -- Travelling horizontally or vertically, just bounce back.
    self.dir = self.dir * -1
  else
    -- Here we know we're travelling diagonally and the path directly ahead is
    -- blocked. What we do depends on if we're hitting a vertical wall, horizontal
    -- wall, or a corner (concave or convex).
    local x_only = self.pos + v2(self.dir.x, 0)
    local y_only = self.pos + v2(0, self.dir.y)
    local x_wall = tilemap_at(tilemap, x_only) ~= TILE_FLOOR
    local y_wall = tilemap_at(tilemap, y_only) ~= TILE_FLOOR
    if x_wall and not y_wall then
      -- Hitting a vertical wall (x-direction), so bounce horizontally.
      self.dir.x *= -1
      self.pos.y += self.dir.y
    elseif y_wall and not x_wall then
      -- Hitting a horizontal wall (y-direction), so bounce vertically.
      self.dir.y *= -1
      self.pos.x += self.dir.x
    else
      -- Corner, just bounce.
      self.dir = self.dir * -1
    end
  end
end

-- TODO: If a "solid" monster is hit (like a ball monster?), maybe should return
-- something so we can stop the ball.
function Ball:hit_monsters(monsters)
  for i=1,#monsters do
    if not monsters[i].dead and self.pos == monsters[i].pos then
      monsters[i]:hit_by_ball(self.dir)
    end
  end
end

-- Will be called repeatedly, once per game frame, until this returns
-- TURN_FINISHED to indicate it is done taking its turn.
function Ball:turn_update(tilemap, monsters)
  if not self.taking_turn then
    self.taking_turn = true
    -- TODO: init turn taking stuff
  end

  if self.energy <= 0 then
    self.taking_turn = false
    return TURN_FINISHED
  end

  self:roll(tilemap)

  self:hit_monsters(monsters)

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
