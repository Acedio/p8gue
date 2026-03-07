Camera = {}

function Camera:new(o)
  o = o or {}
  o.shake_vec = v2(0,0)
  o.shake_freq = 0
  o.shake_ticks = 0
  o.shake_ttl = 0
  setmetatable(o, self)
  self.__index = self
  return o
end

function Camera:update(player)
  self.shake_ticks += 1
end

function Camera:point()
  local cam_pos = self.pos - v2(64,64)
  if self.shake_ticks < self.shake_ttl then
    local attenutation = 1 - self.shake_ticks / self.shake_ttl
    cam_pos += self.shake_vec * sin(self.shake_ticks * self.shake_freq / UPDATE_FREQ) * attenutation
  end
  camera(cam_pos.x, cam_pos.y)
end

function Camera:shake(vec, freq, ttl)
  self.shake_vec = vec
  self.shake_freq = freq
  self.shake_ticks = 0
  self.shake_ttl = ttl
end

