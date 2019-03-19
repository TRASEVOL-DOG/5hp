-- BLAST FLOCK source files
-- by TRASEVOL_DOG (https://trasevol.dog/)

require("maths")
require("shader")
require("drawing")

files={
  sprites = "assets/spritesheet.png",
  title = "assets/title.png"
}

anim_info = {
  player = {
    idle = {
      sheet = "sprites",
      dt = 0.1,
      --sprites = {0,1,2,3}
      --sprites = {192,193,194,195,196,197,198,199,200,201,202,203,204,205,206,207}
      sprites = {192,193,194,195,196,197}
    },
    run = {
      sheet="sprites",
      dt = 0.04,
      --sprites = {8,9,10,11,12,13,14,15},
      --sprites = {192,193,194,195,196,197,198,199,200,201,202,203,204,205,206,207},
      sprites = {208,209,210,211,212,213,214,215,216,217,218,219,220,221,222,223}
    },
    hurt = {
      sheet = "sprites",
      dt = 0.035,
      sprites = {202,201,201,201,202,201,202}
    }
  },
  wind = {
    a = {
      sheet = "sprites",
      dt = 0.06,
      sprites = {64,65,66,67,68,69,70,71,72,73,74,75,76,78}
    },
    b = {
      sheet = "sprites",
      dt = 0.06,
      sprites = {80,81,82,83,84,85,86,87,88,89}
    },
    c = {
      sheet = "sprites",
      dt = 0.06,
      sprites = {96,97,98,99,100,101,102,103,104,105}
    }
  },
  shine = {
    a = {
      sheet = "sprites",
      dt = 0.03,
      sprites = {90,91,92,93,94}
    },
    b = {
      sheet = "sprites",
      dt = 0.03,
      sprites = {106,107,108,109,110}
    }
  }
}



function init_sprite_mgr()
  sprite={}
  init_spritesheets(files)
  init_anims(anim_info)
 
  sprite.paltrsp={}
  for i=1,#palette do
    sprite.paltrsp[i]=false
  end
  sprite.paltrsp[0]=true
  
  sprite.rev_pal={}
  for i=0,#palette-1 do
    local c = palette_norm[i]
    sprite.rev_pal[""..c[1]..c[2]..c[3]] = i
  end

  sprite_tilesize(8,8)
  spritesheet("sprites")
end



function refresh_spritesheets()
  init_spritesheets(files)
  init_anims(anim_info)
  spritesheet("sprites")
end

function palt(c,trsp)
  sprite.paltrsp[c]=trsp
end

function spritesheet(n)
--  local str=""
--  for i,n in pairs(sprite.sheets) do
--    str = str..i.." = "..(n:type()).." - "
--  end
--  error(str)

  sprite.sheet = sprite.sheets[n]
  sprite.sheet_id = n
  
--  error(sprite.sheet:type())
  local sw, sh = sprite.sheet:getPixelDimensions()
  sprite.nw = flr(sw/sprite.tw)
  sprite.nh = flr(sh/sprite.th)
end

function sprite_tilesize(w,h)
  if not w then
    return sprite.tw, sprite.th, sprite.nw, sprite.nh
  end
  
  sprite.tw = w
  sprite.th = h
  
  if sprite.sheet then
    local sw, sh = sprite.sheet:getPixelDimensions()
    sprite.nw = flr(sw/sprite.tw)
    sprite.nh = flr(sh/sprite.th)
  end
end

function sprite_coordinates(s)
  return (s % sprite.nw) * sprite.tw, flr(s / sprite.nw) * sprite.th
end

function sget(x, y, sheet)
  sheet = sheet or sprite.sheet_id
  local r,g,b = sprite.sheet_data[sheet]:getPixel(x,y)
  return sprite.rev_pal[""..r..g..b]
end

function spr(s,x,y,w,h,r,flipx,flipy,cx,cy)
  local w=w or 1
  local h=h or 1
  local r=r or 0
  local flipx=flipx and -1 or 1
  local flipy=flipy and -1 or 1
  local cx=(cx or 0.5)*w*sprite.tw
  local cy=(cy or 0.5)*h*sprite.th
  
  local sx=s%sprite.nw*sprite.tw
  local sy=flr(s/sprite.nw)*sprite.th
  
  local quad=love.graphics.newQuad(sx,sy,w*8,h*8,sprite.sheet:getDimensions())
  
  plt_shader()
  love.graphics.draw(sprite.sheet,quad,x,y,r*2*math.pi,flipx,flipy,cx,cy)
  set_shader()
end

function sspr(sx,sy,sw,sh,dx,dy,dw,dh,r,cx,cy)
  local dw=dw or sw
  local dh=dh or sh
  
  local r=r or 0
  
  local cx=(cx or 0.5)*sw
  local cy=(cy or 0.5)*sh
  
  local quad=love.graphics.newQuad(sx,sy,sw,sh,sprite.sheet:getDimensions())
  
  plt_shader()
  love.graphics.draw(sprite.sheet,quad,dx,dy,r*2*math.pi,dw/sw,dh/sh,cx,cy)
  set_shader()
end


function draw_spr_outline(s,x,y,w,h,outline_c,r,flipx,flipy,cx,cy)
  local w=w or 1
  local h=h or 1
  local r=r or 0
  local flipx=flipx and -1 or 1
  local flipy=flipy and -1 or 1
  local cx=(cx or 0.5)*w*sprite.tw
  local cy=(cy or 0.5)*h*sprite.th
  
  local sx=s%sprite.nw*sprite.tw
  local sy=flr(s/sprite.nw)*sprite.th
  
  local quad=love.graphics.newQuad(sx,sy,w*8,h*8,sprite.sheet:getDimensions())
  
  all_colors_to(outline_c)
  plt_shader()
  love.graphics.draw(sprite.sheet,quad,x-1,y,r*2*math.pi,flipx,flipy,cx,cy)
  love.graphics.draw(sprite.sheet,quad,x+1,y,r*2*math.pi,flipx,flipy,cx,cy)
  love.graphics.draw(sprite.sheet,quad,x,y-1,r*2*math.pi,flipx,flipy,cx,cy)
  love.graphics.draw(sprite.sheet,quad,x,y+1,r*2*math.pi,flipx,flipy,cx,cy)
  set_shader()
  all_colors_to()
end

function draw_spr_outlined(s,x,y,w,h,outline_c,r,flipx,flipy,cx,cy)
  local w=w or 1
  local h=h or 1
  local r=r or 0
  local flipx=flipx and -1 or 1
  local flipy=flipy and -1 or 1
  local cx=(cx or 0.5)*w*sprite.tw
  local cy=(cy or 0.5)*h*sprite.th
  
  local sx=s%sprite.nw*sprite.tw
  local sy=flr(s/sprite.nw)*sprite.th
  
  local quad=love.graphics.newQuad(sx,sy,w*8,h*8,sprite.sheet:getDimensions())
  
  all_colors_to(outline_c)
  plt_shader()
  love.graphics.draw(sprite.sheet,quad,x-1,y,r*2*math.pi,flipx,flipy,cx,cy)
  love.graphics.draw(sprite.sheet,quad,x+1,y,r*2*math.pi,flipx,flipy,cx,cy)
  love.graphics.draw(sprite.sheet,quad,x,y-1,r*2*math.pi,flipx,flipy,cx,cy)
  love.graphics.draw(sprite.sheet,quad,x,y+1,r*2*math.pi,flipx,flipy,cx,cy)
  set_shader()
  all_colors_to()
  plt_shader()
  love.graphics.draw(sprite.sheet,quad,x,y,r*2*math.pi,flipx,flipy,cx,cy)
  set_shader()
end

function draw_anim(x,y,object,state,t,r,flipx,flipy)
  local state=state or "only"
  local flipx=flipx and -1 or 1
  local flipy=flipy and -1 or 1
  local r=r or 0
  local info=sprite.anims[object][state]
  
  local quad=info.quads[flr(t/info.dt)%#info.quads+1]
  
  plt_shader()
  love.graphics.draw(info.sheet,quad,x,y,r*2*math.pi,flipx,flipy,info.cx,info.cy)
  set_shader()
end

function draw_anim_outline(x,y,object,state,t,outline_c,r,flipx,flipy)
  local state=state or "only"
  local flipx=flipx and -1 or 1
  local flipy=flipy and -1 or 1
  local r=r or 0
  local info=sprite.anims[object][state]
  
  local quad=info.quads[flr(t/info.dt)%#info.quads+1]
  
  all_colors_to(outline_c)
  plt_shader()
  love.graphics.draw(info.sheet,quad,x-1,y,r*2*math.pi,flipx,flipy,info.cx,info.cy)
  love.graphics.draw(info.sheet,quad,x+1,y,r*2*math.pi,flipx,flipy,info.cx,info.cy)
  love.graphics.draw(info.sheet,quad,x,y-1,r*2*math.pi,flipx,flipy,info.cx,info.cy)
  love.graphics.draw(info.sheet,quad,x,y+1,r*2*math.pi,flipx,flipy,info.cx,info.cy)
  set_shader()
  all_colors_to()
end

function draw_anim_outlined(x,y,object,state,t,outline_c,r,flipx,flipy)
  local state=state or "only"
  local flipx=flipx and -1 or 1
  local flipy=flipy and -1 or 1
  local r=r or 0
  local info=sprite.anims[object][state]
  
  local quad=info.quads[flr(t/info.dt)%#info.quads+1]
  
  all_colors_to(outline_c)
  plt_shader()
  love.graphics.draw(info.sheet,quad,x-1,y,r*2*math.pi,flipx,flipy,info.cx,info.cy)
  love.graphics.draw(info.sheet,quad,x+1,y,r*2*math.pi,flipx,flipy,info.cx,info.cy)
  love.graphics.draw(info.sheet,quad,x,y-1,r*2*math.pi,flipx,flipy,info.cx,info.cy)
  love.graphics.draw(info.sheet,quad,x,y+1,r*2*math.pi,flipx,flipy,info.cx,info.cy)
  set_shader()
  all_colors_to()
  plt_shader()
  love.graphics.draw(info.sheet,quad,x,y,r*2*math.pi,flipx,flipy,info.cx,info.cy)
  set_shader()
end

function anim_step(object, state, t)
 local info=anim_info[object][state]
 
 local v=flr(t/info.dt%#info.sprites)
 local k=flr((t/info.dt)/#info.sprites)
 
 return v,(t%info.dt<0.01),k
end



function draw_frame(s, xa, ya, xb, yb, stretch)
  local tw,th,nw,nh = sprite_tilesize()

  if stretch then
    local sx,sy = sprite_coordinates(s)
    sspr(sx+tw, sy+th, tw, th,
         xa+tw, ya+th, xb-xa-2*tw, yb-ya-2*th, 0, 0, 0)
    
    sspr(sx+tw, sy, tw, th,
         xa+tw, ya, xb-xa-2*tw, th, 0, 0, 0)
    sspr(sx+tw, sy+2*th, tw, th,
         xa+tw, yb-th, xb-xa-2*tw, th, 0, 0, 0)
    
    sspr(sx, sy+th, tw, th,
         xa, ya+th, tw, yb-ya-2*th, 0, 0, 0)
    sspr(sx+2*tw, sy+th, tw, th,
         xb-tw, ya+th, tw, yb-ya-2*th, 0, 0, 0)
  else
    for x=xa,xb-th,th do
      for y=ya,yb-th,th do
        spr(s+nw+1, x, y, 1, 1, 0, false, false, 0, 0)
      end
      
      spr(s+1,      x, ya,    1, 1, 0, false, false, 0, 0)
      spr(s+nw*2+1, x, yb-th, 1, 1, 0, false, false, 0, 0)
    end
    
    for y=ya,yb-th,th do
      spr(s+nw,   xa,    y, 1, 1, 0, false, false, 0, 0)
      spr(s+nw+2, xb-tw, y, 1, 1, 0, false, false, 0, 0)
    end
  end

  spr(s,        xa,    ya,    1, 1, 0, false, false, 0, 0)
  spr(s+2,      xb-tw, ya,    1, 1, 0, false, false, 0, 0)
  spr(s+nw*2,   xa,    yb-th, 1, 1, 0, false, false, 0, 0)
  spr(s+nw*2+2, xb-tw, yb-th, 1, 1, 0, false, false, 0, 0)
--  spr(s,        xa,    ya,    1, 1, 0, false, false, 0, 0)
--  spr(s+2,      xb-tw, ya,    1, 1, 0, false, false, 0, 0)
--  spr(s+nw*2,   xa,    yb-th, 1, 1, 0, false, false, 0, 0)
--  spr(s+nw*2+2, xb-tw, yb-th, 1, 1, 0, false, false, 0, 0)
end



function init_spritesheets(files)
  sprite.sheets={}
  sprite.sheet_data={}
  
  for i,file in pairs(files) do
    local sheet_data = love.image.newImageData(file)
    sprite.sheets[i]     = love.graphics.newImage(sheet_data)
    sprite.sheet_data[i] = sheet_data
  end
end

function init_anims(anim_info)
  local anims={}
  
  for onam,o in pairs(anim_info) do
    local ob={}
    for name,state in pairs(o) do
      local a={}
      a.sheet=sprite.sheets[state.sheet]
      a.dt=state.dt
      
      a.w=(state.w or 1)*8
      a.h=(state.h or 1)*8
      
      a.cx=state.cx or a.w/2
      a.cy=state.cy or a.h/2
      
      local shtw,shth=a.sheet:getDimensions()
      
      local q={}
      for s in all(state.sprites) do
        local sx=s%16*8
        local sy=flr(s/16)*8
        local sw=a.w
        local sh=a.h
        
        add(q,love.graphics.newQuad(sx,sy,sw,sh,shtw,shth))
      end
      
      a.quads=q
      
      ob[name]=a
    end
    
    anims[onam]=ob
  end
  
  sprite.anims=anims
end
