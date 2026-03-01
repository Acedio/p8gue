V2 = {}

function V2:new(x, y)
  o = {x=x, y=y}
  setmetatable(o, self)
  self.__index = self
  return o
end

-- Serializes an (integer) vector into a single number, for use as table keys.
function V2:serialize()
  return bor(
    band(0xFFFF, self.x),
    lshr(self.y, 16))
end

function V2.from_serialized(serialized)
  return v2(band(serialized, 0xFFFF), shl(serialized, 16))
end

-- Convenience constructor.
function v2(x, y)
  return V2:new(x,y)
end
