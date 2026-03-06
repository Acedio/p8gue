function _init()
  title = Title:new()
  game = nil
end

function _draw()
  if game then
    game:draw()
  else
    title:draw()
  end
end

function _update()
  if game then
    if game:update() then
      title = Title:new()
      game = nil
    end
  else
    if title:update() then
      game = Game:new()
      title = nil
    end
  end
end
