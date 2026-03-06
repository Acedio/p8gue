-- Create with this function, then add update() and draw() to the respetive
-- sections. Set pos.x to nil to center.
function bubbletext(text, pos)
  if pos.x == nil then
    pos.x = 128/2 - 2*#text
  end
  return {
    t=0,
    pos=pos,
    text=text,
    char_ticks=2,
    update=function(self)
      self.t += 1
    end,
    draw=function(self)
      local dx,dy = 0,0
      last_char = flr(self.t/self.char_ticks)
      for i=1,#self.text do 
        if i > last_char then
          break
        end
        text_x = self.pos.x+dx
        text_y = self.pos.y+dy+2*cos((4*i+self.t*2)/80)
        printbg(self.text[i], text_x, text_y, 7, 0)
        if self.text[i] == '\n' then
          dx = 0
          dy += 7
        else
          dx += 4
        end
      end
    end,
  }
end

function printbg(text, x, y, fg, bg)
  print(text, x-1, y, bg)
  print(text, x+1, y, bg)
  print(text, x, y-1, bg)
  print(text, x, y+1, bg)
  print(text, x, y, fg)
end
