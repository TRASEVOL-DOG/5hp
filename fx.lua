-- BLAST FLOCK source files
-- by TRASEVOL_DOG (https://trasevol.dog/)

require("drawing")
require("maths")
require("table")
require("object")
require("sprite")



function update_leaf(s)
  s.x = s.x+s.vx*dt30f
  s.y = s.y+s.vy*dt30f
  s.z = s.z + s.vz*dt30f
  
  s.vx = lerp(s.vx, 0, 0.15 * dt30f)
  s.vy = lerp(s.vy, 0, 0.15 * dt30f)
  
  s.vz = min(s.vz + 0.1*dt30f, 0.5)
  
  s.animt = s.animt + delta_time
  if s.animt > 2 then
    deregister_object(s)
  end
end

function update_floatingtxt(s)
  s.t=s.t+1*dt30f
--  if s.t>=48 then
--    deregister_object(s)
--  end
end

function update_smoke(s)
  s.x=s.x+s.vx*dt30f
  s.y=s.y+s.vy*dt30f
  
  s.vx=lerp(s.vx, 0,0.1*dt30f)
  s.vy=lerp(s.vy,-0.25,0.1*dt30f)
  
  s.r=s.r-0.025*dt30f
  if s.r<0 then
    deregister_object(s)
  end
end

--function add_shake(p)
--  local a=rnd(1)
--  shkx=shkx+p*cos(a)
--  shky=shky+p*sin(a)
--end
--
--shkt = 0
--function update_shake()
--  shkt = shkt - love.timer.getDelta()
--  if shkt < 0 then
--    if abs(shkx)<0.5 and abs(shky)<0.5 then
--      shkx,shky=0,0
--    end
--    
--    shkx=-(0.5+rnd(0.2))*shkx
--    shky=-(0.5+rnd(0.2))*shky
--    shkt = 0.033
--  end
--end


function draw_leaf(s)
  if s.animt > 1.5 and s.animt % 0.3 < 0.1 then
    return
  end

  spr(54+flr(s.animt * 10)%2, s.x, s.y+s.z, 1, 1, s.a+s.animt*0.5, s.left)
end

function draw_floatingtxt(s)
  local c = s.c
  local k=flr(s.t/2)+1
  local n=({3,2,1,0,0,0,0,0,1,2,3,4})[k]
  if not n then
    deregister_object(s)
    return
  end
  
  local c0, c1, c2 = lighter(c, n-2), lighter(c, n), lighter(c, n+3) 
  
  font("small")
  draw_text(s.txt,s.x,s.y-s.t, 1, c0, c1, c2)
end

function draw_explosion(s)
  local c=({6,6,14,14,14,14,14,s.c,s.c})[flr(s.p)+1]
  local r=s.r+max(s.p/4-1,0)
  local foo
  if s.p<7 then foo=circfill
  else foo=circ end
  
  foo(s.x,s.y,r,c)
  
  s.p=s.p+2*dt30f
  
  local p = flr(s.p)
  if p==1 and s.p%1 < 1.5*dt30f and s.recursive then
    if s.r>4 then
      for i=0,1 do
        local a,l=rnd(1),(0.8+rnd(0.4))*s.r
        local x = s.x + l*cos(a)
        local y = s.y + l*sin(a)
        --local x=s.x+rnd(2.2*s.r)-1.1*s.r
        --local y=s.y+rnd(2.2*s.r)-1.1*s.r
        local r=0.25*s.r+rnd(0.5*s.r)
        create_explosion(x,y,r,s.c)
      end
      
      for i=0,2 do
        create_smoke(s.x, s.y, chance(50) and s.c)
      end
    end
  end
  
  if s.p>=8 then
    deregister_object(s)
  end
end

function draw_smoke(s)
--  if s.x+s.r<xmod or s.x-s.r>xmod+screen_width or s.y+s.r<ymod or s.y-s.r>ymod+screen_height then
--    return
--  end
  circfill(s.x,s.y,s.r,s.c)
end



function create_leaf(x,y)
  if server_only then return end

  local a = rnd(1)
  local spd = 1.25+rnd(0.75)
  
  local s = {
    x = x + rnd(4)-2,
    y = y + rnd(4)-2,
    vx = spd*cos(a),
    vy = spd*sin(a),
    z = -rnd(3),
    vz = -0.5-rnd(1),
    animt = rnd(0.5),
    left = chance(50),
    a = rnd(1),
    update = update_leaf,
    draw = draw_leaf,
    regs = {"to_update", "to_draw4"}
  }
  
  register_object(s)
  
  return s
end

function create_floatingtxt(txt,x,y,c)
  if server_only then return end

  local s={
    x=x,
    y=y,
    txt=txt,
    t=t,
    c=c,
    update=update_floatingtxt,
    draw=draw_floatingtxt,
    regs={"to_update","to_draw4"}
  }
  
  register_object(s)
  
  return s
end

function create_explosion(x,y,r,c)
  if server_only then return nil end

  local e={
    x=x,
    y=y,
    r=r,
    p=0,
    recursive = true,
    c=c or 14,
    draw=draw_explosion,
    regs={"to_draw4"}
  }
  
  register_object(e)
  
  return e
end

function create_smoke(x,y,spd,r,c,a)
  if server_only then return nil end

  local a=a or rnd(1)
  local spd=0.75*spd+rnd(0.5*spd)
  
  local s={
    x=x,
    y=y,
    vx=spd*cos(a),
    vy=spd*sin(a),
    r=r or 1+rnd(3),
    c=c or pick{0,1,6},
    update=update_smoke,
    draw=draw_smoke,
    regs={"to_update","to_draw4"}
  }
  
--  if rnd(2)<1 then s.c=drk[s.c] end
  
  register_object(s)
  
  return s
end


