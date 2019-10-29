

function chance(n)
  return rnd(100) < n
end

function give_or_take(n) -- returns random number between -n and n
  return rnd(2*n)-n
end



function all_colors_to(c)
  if c then
    for i = 0, 14 do
      pal(i, c)
    end
  else
    for i = 0, 14 do
      pal(i, i)
    end
  end
end

function lighten(c, n)
  local cc = c
  for i = 1, n do
    cc = c_lit[cc]
  end
  
  pal(c, cc)
end

function darken(c, n)
  local cc = c
  for i = 1, n do
    cc = c_drk[cc]
  end
  
  pal(c, cc)
end



function frame(s, xa, ya, xb, yb, stretch)
  xa, ya = flr(xa), flr(ya)
  xb, yb = flr(xb), flr(yb)

  local tw, th = 8, 8
  local iw = xb-xa-2*tw
  local ih = yb-ya-2*th

  if stretch then
    local sx = (s%16) * 8
    local sy = flr(s/16) * 8
    
    sspr(sx+tw, sy+th, tw, th, xa+tw, ya+th, iw, ih)
    
    sspr(sx+tw, sy,      tw, th, xa+tw, ya,    iw, th)
    sspr(sx+tw, sy+2*th, tw, th, xa+tw, yb-th, iw, th)
    
    sspr(sx,      sy+th, tw, th, xa,    ya+th, tw, ih)
    sspr(sx+2*tw, sy+th, tw, th, xb-tw, ya+th, tw, ih)
  else
    clip(xa+tw, ya+th, iw, ih)
    for y = ya+th, yb-th-0.1, th do
      for x = xa+tw, xb-tw-0.1, tw do
        spr(s+17, x, y)
      end
    end
    
    clip(xa+tw, ya, iw, yb-ya)
    for x = xa+tw, xb-tw-0.1, tw do
      spr(s+1,  x, ya)
      spr(s+33, x, yb-th)
    end
    
    clip(xa, ya+th, xb-xa, ih)
    for y = ya+th, yb-th-0.1, th do
      spr(s+16, xa,    y)
      spr(s+18, xb-tw, y)
    end
    
    clip()
  end
  
  spr(s,    xa,    ya)
  spr(s+2,  xb-tw, ya)
  spr(s+32, xa,    yb-th)
  spr(s+34, xb-tw, yb-th)
end



local _sfx = sfx
function sfx(id, x, y, pitch, volume)
  if not x then
    _sfx(id, 0, 0, pitch)
    return
  end

  local camx, camy = get_camera_pos()
  local scrw, scrh = screen_size()
  x = x - camx - scrw/2
  y = y - camy - scrh/2
  
  _sfx(id, dist(x, y), atan2(x, y), pitch)
end

