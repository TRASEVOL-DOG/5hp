
local utf8 = require("utf")

local slider_width = 64

local menus = {}
local curmenu = nil
local prevmenus = {}

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
  
  font("big")
  
  for o in all(data) do
    local n = {
      name = o[1],
      call = o[2],
      typ  = o[3] or "button"
    }
    
    local mod
    if n.typ == "button" then
      merge_tables(n, {
        w = str_px_width(n.name),
        h = 14
      })
    elseif n.typ == "slider" then
      merge_tables(n, {
        slidmax = o[4] or 1,
        slidmin = o[5] or 0,
        slidv   = n.call(),
        w       = max(str_px_width(n.name), slider_width),
        h       = 26
      })
    elseif n.typ == "text_field" then
      merge_tables(n, {
        mlen    = o[4] or 24,
        txt     = o[5] or "",
        w       = max(str_px_width(n.name), 24*6),
        h       = 28
      })
    end
    
    maxw = max(maxw, n.w)
    toth = toth + n.h
    add(m, n)
  end
  
  m.w = maxw + 16
  m.chosen = nil
  
  menus[name] = m
end


function update_menu()
  if IS_SERVER then return end

  
end

function draw_menu()
  if IS_SERVER then return end
  
--  palt(6, false)
--  palt(1, true)
--  frame(0x1C3, 8, 8, screen_w()-8, screen_h()-8, true)
--   ^^^ frame for highlighted button
end







