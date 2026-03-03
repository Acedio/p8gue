Player = {}

STATE_BOPPIN = 1
STATE_PICKING_UP = 2
STATE_THROWING = 3

function Player:new(o)
  o = o or {}
  o.frames_moved = 0
  o.state = STATE_BOPPIN
  setmetatable(o, self)
  self.__index = self
  return o
end

function Player:y_offset()
  return abs(3*sin(self.frames_moved / 15))
end

function Player:draw()
  local midfoot = self.pos * TILE_SIZE + v2(4,4)
  ovalfill(midfoot.x-2, midfoot.y-1, midfoot.x+2, midfoot.y+1, 5)
  local draw_pos = self.pos * TILE_SIZE + v2(0, -3 - self:y_offset())
  spr(4, draw_pos.x, draw_pos.y, 1, 1, self.facing_left)

-- TODO: Maybe change based on direction faced?
  if self.held then
    self.held:draw_held(draw_pos)
  end
end

function direction_press()
  if btnp(0) then -- Left
    return v2(-1,0)
  elseif btnp(1) then -- Right
    return v2(1,0)
  elseif btnp(2) then -- Up
    return v2(0,-1)
  elseif btnp(3) then -- Down
    return v2(0,1)
  end
  return nil
end

function direction_held()
  local dir = v2(0,0)
  if btn(0) then -- Left
    dir.x -= 1
  end
  if btn(1) then -- Right
    dir.x += 1
  end
  if btn(2) then -- Up
    dir.y -= 1
  end
  if btn(3) then -- Down
    dir.y += 1
  end
  return dir
end

function Player:turn_update(tilemap, objects)
  if not self.taking_turn then
    self.taking_turn = true
    -- TODO: init turn taking stuff
  end

  local moved = false
  local took_action = false

  if self.state == STATE_BOPPIN then
    local step = direction_press()
    if step then
      local target = self.pos + step
      if tilemap[target.y + 1][target.x + 1] == TILE_FLOOR then
        self.pos = target
        moved = true
        took_action = true
      end
      if step.x ~= 0 then
        self.facing_left = step.x < 0
      end
    else
      if btn(4) then -- pick up/throw
        if self.held then
          -- Prep for throwing
          self.state = STATE_THROWING
        else
          -- pickup
          for i=1,#objects do
            if self.pos == objects[i].pos then
              self.state = STATE_PICKING_UP
              assert(not self.held, "Picking up multiple objects?")
              self.held = objects[i]
              deli(objects,i)
              took_action = true
            end
          end
        end
      end
    end
  elseif self.state == STATE_PICKING_UP then
    -- Wait for the player to release the throw button before the pickup is
    -- complete.
    if not btn(4) then
      self.state = STATE_BOPPIN
    end
    -- TODO: Also should let the player move here, just not pick up or throw.
  elseif self.state == STATE_THROWING then
    local dir = direction_held()
    if btn(4) then
      -- aiming
      if dir.x ~= 0 then
        self.facing_left = dir.x < 0
      end
    else
      -- throw
      if dir == v2(0,0) then
        -- TODO: Once we add aiming arrows we should throw in the last
        -- direction.
        dir = self.facing_left and v2(-1, 0) or v2(1, 0)
      end
      add(objects, self.held)
      self.held:throw(self.pos, dir * 5)
      self.held = nil
      took_action = true
      self.state = STATE_BOPPIN
    end
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
