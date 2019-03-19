-- BLAST FLOCK source files
-- by TRASEVOL_DOG (https://trasevol.dog/)

require("drawing")
require("maths")
require("table")
require("object")
require("sprite")



function update_skull(s)
  s.t=s.t+0.01*dt30f
  
  if s.t>=0.230 then
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


function draw_floatingtxt(s)
  local c = s.c
  local k=flr(s.t/2)+1
  local n=({3,2,1,0,0,0,0,0,1,2,3,3})[k]
  if not n then
    deregister_object(s)
    return
  end
  
  local c0, c1, c2 = n, min(3+n,3), min(1+n,3) 
  
  font("small")
  draw_text(s.txt,s.x,s.y-s.t, 1, c0, c1, c2)
end

function draw_explosion(s)
  local c=({0,0,3,3,3,3,3,s.c,s.c})[flr(s.p+dt30f)]
  local r=s.r+max(s.p-2,0)
  local foo
  if s.p<7 then foo=circfill
  else foo=circ end
  
  foo(s.x,s.y,r,c)
  
  if s.p==1 then
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
        create_smoke(s.x,s.y,1,nil,s.c)
      end
    end
  end
  
  s.p=s.p+1*dt30f
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



function create_floatingtxt(x,y,amount,c)
  if server_only then return end

  local s={
    x=x,
    y=y,
    txt="+"..amount,
    t=t,
    c=c,
    update=update_scoretxt,
    draw=draw_scoretxt,
    regs={"to_update","to_draw3"}
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
    c=c,
    draw=draw_explosion,
    regs={"to_draw3"}
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
    c=c or (-1+irnd(2)),
    update=update_smoke,
    draw=draw_smoke,
    regs={"to_update","to_draw4"}
  }
  
--  if rnd(2)<1 then s.c=drk[s.c] end
  
  register_object(s)
  
  return s
end


