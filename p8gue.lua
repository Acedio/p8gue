function make_one_choice_scene(machine, make_next)
  return {
    machine = machine,
    update = function(self)
      if self.machine:update() then
        SCENE = make_next()
      end
    end,
    draw = function(self)
      self.machine:draw()
    end,
  }
end

function make_title_scene()
  return make_one_choice_scene(Title:new(), make_game_scene)
end

function make_win_scene()
  return make_one_choice_scene(WinScene:new(), make_title_scene)
end

function make_game_scene()
  return {
    machine = Game:new(),
    update = function(self)
      local result = self.machine:update() 
      if result == Game.GAME_LOSE then
        SCENE = make_title_scene()
      elseif result == Game.GAME_WIN then
        SCENE = make_win_scene()
      end
    end,
    draw = function(self)
      self.machine:draw()
    end,
  }
end

function _init()
  menuitem(1, "restart game", _init)
  SCENE = make_one_choice_scene(Title:new(), make_game_scene)
end

function _draw()
  SCENE:draw()
end

function _update()
  SCENE:update()
end
