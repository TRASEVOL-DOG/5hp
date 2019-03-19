-- BLAST FLOCK source files
-- by TRASEVOL_DOG (https://trasevol.dog/)

require("drawing")
require("maths")


local menu_x, menu_y = 0,0

function init_menu_system()
  if not define_menus then
    return
  end
  
  menu_linespace={}
  menu_positions={}
  
  local l=define_menus()
  
  menus={}
  for n,m in pairs(l) do
    menus[n]=init_menu(m, n)
  end
  
  curmenu=nil
  prevmenus={}
  
  menuchange=0
  menulock = false
end


function init_menu(l, name)
  local m={}
  
  local maxw=0
  local toth=0
  for o in all(l) do
    local n={
      name = o[1],
      call = o[2],
      typ  = o[3] or "button"
    }
    
    if n.typ=="button" then
      n.w=#n.name*6+8
      n.h=14
    elseif n.typ=="slider" then
      n.slidmax=o[4] or 1
      n.slidmin=o[5] or 0
      n.slidw=o[6] or 64
      n.slidv=n.call()
      n.w=max(#n.name*6+8,n.slidw+8)
      n.h=26
    elseif n.typ=="text_field" then
      n.mlen = o[4] or 24
      n.txt = o[5] or ""
      n.w = max(#n.name*6, n.mlen*6)+8
      n.h = 28
    end
    
    maxw=max(maxw,n.w+4)
    toth=toth+n.h
    add(m,n)
  end
  
  m.linespace = menu_linespace[name] or 14
  
  m.h=toth+(#m-1)*m.linespace
  m.w=maxw+32
  m.chosen=nil
  
  return m
end

function update_menu(x,y)
  if not x then
    local scrnw,scrnh = screen_size()
    local pos = menu_positions[curmenu] or {x = 0.5, y = 0.5}
    x = pos.x * scrnw
    y = pos.y * scrnh
  end

  menuchange=max(menuchange-0.01,0)
  
  if not curmenu then return end
  m=menus[curmenu]
  
  local curx,cury=mouse_pos()
  
  if menulock or curx>x-m.w/2 and curx<x+m.w/2 and cury>y-m.h/2 and cury<y+m.h/2+m.linespace then
    local oy=y-m.h/2+8
    
    if not menulock then
      for o in all(m) do
        oy=oy+o.h+m.linespace
        if cury<oy then
          if m.chosen~=o then
           sfx("menu_select")
          end
          m.chosen=o
          break
        end
      end
    end
    
    if mouse_btn(0) and m.chosen and menuchange==0 then
      local o=m.chosen
      if o.typ=="button" and mouse_btnp(0) then
       sfx("menu_confirm")
        o.call()
      elseif o.typ=="slider" then
        local v
        v=(curx-(x-o.slidw/2))/o.slidw
        v=v*(o.slidmax-o.slidmin)+o.slidmin
        v=clamp(v,o.slidmin,o.slidmax)
        v=round(v)
        
        if v~=o.slidv or mouse_btnp(0) then
          sfx("menu_slider")
        end
        
        o.call(v)
        o.slidv=v
      elseif o.typ=="text_field" and mouse_btnp(0) then
       sfx("menu_confirm")
        if (menulock) then
          menulock = false
          love.keyboard.setTextInput(false)
        else
          menulock = true
          love.keyboard.setTextInput(true, x, oy, o.w, o.h)
        end
      end
    end
    
    if m.chosen and m.chosen.typ == "text_field" then
      if menulock then
        if btnp(8) or btnp(7) then
          sfx("menu_confirm")
          menulock = false
          love.keyboard.setTextInput(false)
        end
      end
    end
  end
end

function draw_menu(x,y)
  if not x then
    local scrnw,scrnh = screen_size()
    local pos = menu_positions[curmenu] or {x = 0.5, y = 0.5}
    x = pos.x * scrnw
    y = pos.y * scrnh
  end

  if not curmenu then return end
  m=menus[curmenu]
  
  local c0,c1,c2 = 0,2,3
  
  y=y-m.h/2
  
  font("big")
  for i,o in ipairs(m) do
    ofx=8*cos(t*0.15+i*0.15)
    
    if o.typ=="button" then
      draw_text(o.name,x+ofx,y+o.h*0.5+2, 1, c0, c1, c2)
    elseif o.typ=="slider" then
      draw_text(o.name,x+ofx,y+o.h*0.25+2, 1, c0, c1, c2)
      
      local x1,x2,y=x-o.slidw/2,x+o.slidw/2,y+o.h*1+1
      rectfill(x1-1,y-2,x2,y+2,c2)
      line(x1,y,x2-1,y,c1)
      line(x1,y-1,x2-1,y-1,c0)
      
      local x=x1+(o.slidv/(o.slidmax-o.slidmin))*o.slidw
      local r=4
      color(c2)
      circfill(x,y-2,r)
      circfill(x,y+1,r)
      circfill(x-1,y-1,r)
      circfill(x+1,y-1,r)
      circfill(x-1,y,r)
      circfill(x+1,y,r)
      circfill(x,y,r,c1)
      circfill(x,y-1,r,c0)
      
      font("small")
      draw_text(o.slidv,x,y-13, 1, c0, c1, c2)
      font("big")
    elseif o.typ=="text_field" then
      draw_text(o.name,x+ofx,y+o.h*0.25+2, 1, c0, c1, c2)
      local txt = o.txt
      if o == m.chosen then
        if menulock then
          txt = txt..(({"|","/","-","\\"})[flr(love.timer.getTime()*8)%4+1])
        else
          txt = "[ "..txt.." ]"
        end
      else
        txt = "\""..txt.."\""
      end
      draw_text(txt,x,y+o.h*0.75+2, 1, c0, c1, c2)
    end
    
    if o==m.chosen then
      local x1,y1,x2,y2=x-m.w/2-1,y,x+m.w/2,y+o.h+6
      rect(x1,y1+1,x2,y2+1,c1)
      rect(x1,y1,x2,y2,c0)
      rect(x1-1,y1-1,x2+1,y2+2,c2)
      rect(x1+1,y1+2,x2-1,y2-1,c2)
    end
    
    y=y+o.h+m.linespace
  end
  font("small")
end


function menu(name)
  if curmenu then
    add(prevmenus,curmenu)
  end
  
  curmenu=name
  menuchange=0.1
end

function querry_menu()
  return curmenu
end

function menu_position(name,x,y)
  menu_positions[name] = {x=x, y=y}
end

function set_menu_linespace(name, space) -- to call inside define_menus()
  menu_linespace[name] = space
end

function menu_back()
  if #prevmenus>0 then
    curmenu=prevmenus[#prevmenus]
    del(prevmenus,curmenu)
  else
    curmenu=nil
  end
end


function menu_textinput(text)
  local o = menus[curmenu].chosen
  if not o.txt or not menulock then return end
  
  o.txt = o.txt..text
  if #o.txt>o.mlen then o.txt=o.txt:sub(1,o.mlen) end
  
  o.call(o.txt)
end

function menu_keypressed(key)
  if curmenu and menus[curmenu] and menus[curmenu].chosen then
    local o = menus[curmenu].chosen
    if o.txt and menulock then
      if key == "backspace" then
        o.txt = o.txt:sub(1, #o.txt-1)
        o.call(o.txt)
      elseif key == "v" and (love.keyboard.isDown("rctrl") or love.keyboard.isDown("lctrl") or love.keyboard.isDown("rgui") or love.keyboard.isDown("lgui")) then
        o.txt = o.txt..love.system.getClipboardText()
        if #o.txt>o.mlen then o.txt = o.txt:sub(1,o.mlen) end
        o.call(o.txt)
      end
    end
  end
end


function menu_height()
  return menus[curmenu].h
end