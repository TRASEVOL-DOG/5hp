
local utf8 = require("game/systems/utf")

local slider_width = 64

local menus      = {}
local curmenu    = nil
local prevmenus  = {}
local menuchange = false

local interact = {}
local draw     = {}

function init_menu_system(menu_data)
  if not menu_data or IS_SERVER then
    return
  end
  
  for n, m in pairs(menu_data) do
    init_menu(m, n)
  end
end


function init_menu(data, name)
  local m = {}
  
  local maxw = 0
  local toth = 0
  
  use_font("big")
  
  for o in all(data) do
    local n = {
      name = o[1],
      call = o[2],
      type = o[3] or "button"
    }
    
    local mod
    if n.type == "button" then
      merge_tables(n, {
        w = str_px_width(n.name),
        h = 20
      })
    elseif n.type == "slider" then
      merge_tables(n, {
        slidmax = o[4] or 1,
        slidmin = o[5] or 0,
        slidv   = n.call(),
        w       = max(str_px_width(n.name), slider_width),
        h       = 32
      })
    elseif n.type == "text_field" then
      merge_tables(n, {
        mlen    = o[4] or 24,
        txt     = o[5] or "",
        w       = max(str_px_width(n.name), o[4]*6),
        h       = 34
      })
    end
    
    maxw = max(maxw, n.w)
    toth = toth + n.h
    add(m, n)
  end
  
  local spacing = 8
  
  m.params = {
    chosen  = nil,
    w       = maxw + 32,
    h       = toth + (#m-1) * spacing,
    spacing = spacing
  }
  
  menus[name] = m
end


function update_menu()
  if IS_SERVER or not curmenu then return end
  
  if menuchange then
    menuchange = btn("mouse_lb")
    return
  end

  local m = menus[curmenu]
  local p = m.params
  
  -- define menu positions (should be consistent with draw_menu())
  local cx = (p.anc_x or 0.5) * screen_w()
  local cy = (p.anc_y or 0.5) * screen_h()
  local x = cx - p.w/2
  local y = cy - p.h/2
  
  -- is the cursor inside the menu box at all?
  local mx, my = btnv("mouse_x"), btnv("mouse_y")
  if mx < x or mx > x+p.w or my < y or my > y+p.h then
    if menulock and btnp("mouse_lb") then
      interact[p.chosen.type](p.chosen, -256, -128)
    end
    
    return
  end
  
  -- find current hovered entry
  local yy = y-p.spacing/2
  
  if menulock then
    for _, n in ipairs(m) do
      yy = yy + n.h + p.spacing
      if n == p.chosen then
        break
      end    
    end
  else
    for _, n in ipairs(m) do
      yy = yy + n.h + p.spacing
      if my < yy then
        if p.chosen ~= n then
          sfx("menu_select")
          p.chosen = n
        end
        break
      end    
    end
  end
  
  
  -- update interaction with hovered entry
  local n = p.chosen
  if n then
    yy = yy - n.h/2 - p.spacing/2
    interact[n.type](n, mx-cx, my-yy)
  end
  
end

function draw_menu()
  if IS_SERVER or not curmenu then return end
  
  local m = menus[curmenu]
  local p = m.params
  
  local cx = (p.anc_x or 0.5) * screen_w()-1
  local cy = (p.anc_y or 0.5) * screen_h()
  local x = cx - p.w/2
  local y = cy - p.h/2
  
  printp(0x0300, 0x3130, 0x3230, 0x0300)
  printp_color(14, 9, 6)
  use_font("big")
  
  palt(6, false)
  palt(1, true)
  
  local chosen_y, chosen_x
  for i, n in ipairs(m) do
    local dx = 0--8 * cos(t()*0.15 + i*0.05)
    
    draw[n.type](n, cx+dx, y)
    
    if n == p.chosen then
      chosen_y = y
      chosen_x = dx
    end
    
    y = y + n.h + p.spacing
  end
  
  if chosen_y then
    local x = x + chosen_x/2
    frame(0x1C3, x, chosen_y-8, x+p.w+4, chosen_y + p.chosen.h+6, true)
  end
  
  palt(6, true)
  palt(1, false)
end



function interact.button(s)
  if btnp("mouse_lb") then
    sfx("menu_confirm")
    s.call()
  end
end

function interact.slider(s, rx)
  if not btn("mouse_lb") then
    return
  end

  local v = mid(rx / slider_width + 0.5, 0, 1)
  v = round(s.slidmin + v * (s.slidmax - s.slidmin))
  
  if v ~= s.slidv or btnp("mouse_lb") then
    sfx("menu_slider")
    s.call(v)
    s.slidv = v
  end
end

local catch_text, catch_keys, text_n
function interact.text_field(s, rx, ry)
  if not menulock and btnp("mouse_lb") then
    sfx("menu_confirm")
    menulock = true
    love.keyboard.setTextInput(true)
    love.textinput = catch_text
    text_n = s
  elseif btnr("mouse_lb") and abs(ry) > s.h/2 then
    sfx("menu_confirm")
    menulock = false
    menuchange = true
    love.keyboard.setTextInput(false)
    love.textinput = nil
    text_n = nil
  end
  
  if menulock then
    if btnp("backspace") and #s.txt > 0 then
      s.txt = utf8.sub(s.txt, 1, utf8.len(s.txt)-1)
      s.call(s.txt)
    end
    
    if btnp("v") and btn("ctrl") then
      s.txt = s.txt..read_clipboard()
      
      if utf8.len(s.txt) > s.mlen then
        s.txt = utf8.sub(s.txt, 1, s.mlen)
      end
      
      s.call(s.txt)
    end
  end
end

function catch_text(str)
  local s = text_n
  s.txt = s.txt..str
  
  if utf8.len(s.txt) > s.mlen then
    s.txt = utf8.sub(s.txt, 1, s.mlen)
  end
  
  s.call(s.txt)
end



function draw.button(s, cx, y)
  local x = cx - str_px_width(s.name)/2
  pprint(s.name, x, y)
end

function draw.slider(s, cx, y)
  local x = cx - str_px_width(s.name)/2
  pprint(s.name, x, y-2)
  
  local w = slider_width
  y = y + 19
  x = flr(cx - w/2)
  
  sspr(56, 224, 8, 8, x, y-4, w, 8)
  spr(0x1C6, x-4, y-4)
  spr(0x1C8, x+w-4, y-4)
  
  x = (s.slidv - s.slidmin) / (s.slidmax - s.slidmin) * w + x
  spr(0x1D6, x-8, y-9, 2, 2)
  
  use_font("small")
  local str = ""..s.slidv
  pprint(str, x-str_px_width(str)/2-2, y-3)
  use_font("big")
end

function draw.text_field(s, cx, y)
  local x = cx - str_px_width(s.name)/2
  pprint(s.name, x, y)
  
  local txt = s.txt
  if s == text_n then
    if menulock then
      txt = txt..(({"|","/","-","\\"})[flr(t()*8)%4+1])
    else
      txt = "[ "..txt.." ]"
    end
  else
    txt = '"'..txt..'"'
  end
  
  pprint(txt, cx - str_px_width(txt)/2, y + 14)
end



function menu(name)
  if IS_SERVER then return end

  if not name then
    -- go back
    curmenu = prevmenus[#prevmenus]
    if curmenu then
      prevmenus[#prevmenus] = nil
    end
    
    return
  end

  if not menus[name] then
    w_log("Attempt to use undefined menu "..name)
    return
  end
  
  if curmenu then
    add(prevmenus, curmenu)
  end
  
  curmenu = name
  menuchange = true
end

function get_menu()
  return curmenu
end

function update_menu_entry(menu, i, name, v)
  local m = menus[menu]
  if not m or not m[i] then return end
  
  local n = m[i]
  
  if name then
    n.name = name
  end
  
  if v then
    if n.type == "slider" then
      n.slidv = v
    elseif n.type == "text_field" then
      n.txt = v
    end
  end
end