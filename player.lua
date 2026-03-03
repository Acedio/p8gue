Player = {}

function Player:new(o)
  o = o or {}
  setmetatable(o, self)
  self.__index = self
  return o
end

function Player:init()
  self.pos = v2(8,8)
  self.frames_moved = 0
end

function Player:y_offset()
  return abs(3*sin(self.frames_moved / 15))
end

function Player:draw()
  local midfoot = self.pos * TILE_SIZE + v2(4,4)
  ovalfill(midfoot.x-2, midfoot.y-1, midfoot.x+2, midfoot.y+1, 5)
  spr(4, self.pos.x * TILE_SIZE, self.pos.y * TILE_SIZE - 3 - self:y_offset(), 1, 1, self.facing_left)
end

function Player:turn_update(tilemap)
  if not self.taking_turn then
    self.taking_turn = true
    -- TODO: init turn taking stuff
  end

  local moved = false
  local took_action = false
  if btnp(0) then -- Left
    self.facing_left = true
    local target = self.pos + v2(-1,0)
    if tilemap[target.y + 1][target.x + 1] == TILE_FLOOR then
      self.pos = target
    end
    moved = true
    took_action = true
  elseif btnp(1) then -- Right
    self.facing_left = false
    local target = self.pos + v2(1,0)
    if tilemap[target.y + 1][target.x + 1] == TILE_FLOOR then
      self.pos = target
    end
    moved = true
    took_action = true
  elseif btnp(2) then -- Up
    local target = self.pos + v2(0,-1)
    if tilemap[target.y + 1][target.x + 1] == TILE_FLOOR then
      self.pos = target
    end
    moved = true
    took_action = true
  elseif btnp(3) then -- Down
    local target = self.pos + v2(0,1)
    if tilemap[target.y + 1][target.x + 1] == TILE_FLOOR then
      self.pos = target
    end
    moved = true
    took_action = true
  elseif btnp(4) then -- ball
    add(game_state.balls, Ball:new{
      pos = self.pos:copy(),
      vel = self.facing_left and v2(-5,0) or v2(5,0),
    })
    took_action = true
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

  if took_action then
    self.taking_turn = false
    return TURN_FINISHED
  end
  return TURN_UNFINISHED
end

function Player:idle_update(tilemap)
end
