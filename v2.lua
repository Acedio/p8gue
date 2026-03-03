V2 = {}

function V2:new(x, y)
  o = {x=x, y=y}
  setmetatable(o, self)
  self.__index = self
  return o
end

function V2.__eq(a,b)
  return a.x == b.x and a.y == b.y
end

function V2.__add(a,b)
  return v2(a.x+b.x, a.y+b.y)
end

function V2.__sub(a,b)
  return v2(a.x-b.x, a.y-b.y)
end

function V2.__mul(a,b)
  if type(b) == "number" then
    return v2(a.x * b, a.y * b)
  end
  if type(a) == "number" then
    return v2(b.x * a, b.y * a)
  end
  assert(false, "unsupported multiplication: " .. type(a) .. "*" .. type(b))
end

function V2.__div(a,b)
  assert(type(b) == "number")
  return v2(a.x / b, a.y / b)
end

function V2.__idiv(a,b)
  assert(type(b) == "number")
  return v2(a.x \ b, a.y \ b)
end

function V2:copy()
  return v2(self.x, self.y)
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
