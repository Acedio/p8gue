Player = {
  STATE_BOPPIN = 1,
  STATE_PICKING_UP = 2,
  STATE_AIMING = 3,
}

function Player:new(o)
  local o = o or {}
  o.frames_moved = 0
  o.state = Player.STATE_BOPPIN
  o.life = 3
  o.hurt_ticks = 0
  setmetatable(o, self)
  self.__index = self
  return o
end

function Player:y_offset()
  return abs(3*sin(self.frames_moved / 15))
end

function Player:draw_shadow()
  local midfoot = self.pos * TILE_SIZE + v2(4,4)
  ovalfill(midfoot.x-2, midfoot.y-1, midfoot.x+2, midfoot.y+1, 5)
end

function Player:draw_life()
  for i=1,self.life do
    spr(9, (i - 1) * TILE_SIZE + 4, 4)
  end
  if self.hurt_ticks % 2 ~= 0 then
    -- blink the lost heart when hurt
    spr(9, (self.life) * TILE_SIZE + 4, 4)
  end
end

function Player:draw_aim()
  if self.state == Player.STATE_AIMING then
    if self.aim_dir == v2(0,0) then
      spr(12, self.pos.x * TILE_SIZE, self.pos.y * TILE_SIZE)
    else
      for i=1,2 do
        local draw_pos = (self.pos + i * self.aim_dir) * TILE_SIZE
        spr(12, draw_pos.x, draw_pos.y)
      end
    end
  end
end

function Player:draw()
  self:draw_shadow()
  local draw_pos = self.pos * TILE_SIZE + v2(0, -3 - self:y_offset())
  if self.hurt_ticks % 2 == 0 then
    -- blink when hurt
    spr(4, draw_pos.x, draw_pos.y, 1, 1, self.facing_left)
  end

  if self.held then
    -- TODO: Maybe change based on direction faced?
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

function Player:turn_update(tilemap, objects, monsters)
  local moved = false
  local took_action = false

  self:idle_update()

  if self.state == Player.STATE_BOPPIN then
    local step = direction_press()
    if step then
      local target = self.pos + step
      if tilemap_at(tilemap, target) == TILE_FLOOR then
        local monster = monsters[target:serialize()]
        if monster then
          -- Trade places with the monster and take damage.
          -- TODO: Feel like this logic should be factored into some sort of
          -- MonsterMap class.
          move_monster(monsters, monster, self.pos)
          monster:player_trade(self)
        end
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
          self.state = Player.STATE_AIMING
          self.aim_dir = v2(0,0)
        else
          -- pickup
          for i=1,#objects do
            if self.pos == objects[i].pos then
              self.state = Player.STATE_PICKING_UP
              assert(not self.held, "Picking up multiple objects?")
              self.held = objects[i]
              deli(objects,i)
              took_action = true
            end
          end
        end
      end
    end
  elseif self.state == Player.STATE_PICKING_UP then
    -- Wait for the player to release the throw button before the pickup is
    -- complete.
    if not btn(4) then
      self.state = Player.STATE_BOPPIN
    end
    -- TODO: Also should let the player move here, just not pick up or throw.
  elseif self.state == Player.STATE_AIMING then
    self.aim_dir = direction_held()
    if btn(4) then
      -- aiming
      if self.aim_dir.x ~= 0 then
        self.facing_left = self.aim_dir.x < 0
      end
    else
      -- throw
      if self.aim_dir == v2(0,0) then
        -- No direction held, don't throw.
      else
        add(objects, self.held)
        self.held:throw(self.pos, self.aim_dir)
        self.held = nil
        took_action = true
      end
      self.state = Player.STATE_BOPPIN
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
    return TURN_FINISHED
  end
  return TURN_UNFINISHED
end

function Player:hurt()
  sfx(6,1)
  self.hurt_ticks = 15
  self.life -= 1
end

function Player:idle_update()
  if self.hurt_ticks > 0 then
    self.hurt_ticks -= 1
  end
end

function Player:animate()
  return ANIMATION_COMPLETE
end
