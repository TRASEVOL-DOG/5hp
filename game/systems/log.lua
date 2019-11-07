
local logs = {}
local font = "big"

function new_log(str, c)
  if IS_SERVER then return end

  use_font(font)
  add(logs, {
    str = str,
    c   = c,
    y   = 64,
    w   = str_px_width(str),
    l   = 5
  })
end

function update_log()
  for i = 1, #logs do
    local l = logs[i]
    
    l.y = lerp(l.y, -(#logs-i) * 16, 5*dt())
    
    l.l = l.l - dt()
    if l.l <= 0 then
      del_at(logs, i)
      return
    end
  end
end

function draw_log()
  use_font(font)
  
  printp(0x0300, 0x3130, 0x3230, 0x0300)
  local y = screen_h() - 24
  
  for i = #logs, 1, -1 do
    local l = logs[i]
    
    local c = l.c or 9
    if l.l < 0.1 then
      printp_color(c_drk[c], c_drk[c_drk[c]], 6)
    elseif l.l < 0.2 then
      printp_color(c, c_drk[c], 6)
    else
      printp_color(14, c, 6)
    end
    
    local x = screen_w()/2 - l.w/2
    local y = y + l.y
    pprint(l.str, x, y)
  end
end