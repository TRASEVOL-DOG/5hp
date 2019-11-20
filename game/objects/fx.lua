

do -- leaf

  function create_leaf(x, y, ca, cb)
    if IS_SERVER then return end
  
    local a = rnd(1)
    local spd = 40+rnd(20)
    
    local s = {
      x  = x + rnd(4) - 2,
      y  = y + rnd(4) - 2,
      vx = spd * cos(a),
      vy = spd * sin(a),
      z  = -rnd(3),
      vz = -15 - rnd(30),
      
      animt = rnd(0.5),
      left  = chance(50) and -1 or 1,
      a     = rnd(1),
      ca    = ca,
      cb    = cb,
      
      update = update_leaf,
      draw   = draw_leaf,
      regs   = {"to_update", "to_draw4", "particles"}
    }
    
    register_object(s)
    
    return s
  end
  
  function update_leaf(s)
    s.x = s.x + s.vx * dt()
    s.y = s.y + s.vy * dt()
    s.z = s.z + s.vz * dt()
    
    s.vx = lerp(s.vx, 0, 4.5 * dt())
    s.vy = lerp(s.vy, 0, 4.5 * dt())
    
    s.vz = min(s.vz + 90 * dt(), 15)
    
    s.animt = s.animt + dt()
    if s.animt > 2 then
      deregister_object(s)
    end
  end
  
  function draw_leaf(s)
    if s.animt > 1.5 and s.animt % 0.3 < 0.1 then
      return
    end
  
    if s.ca then
      pal(10, s.ca)
      pal(2, s.cb)
      pal(1, c_drk[s.cb])
      
      aspr(
        54+flr(s.animt * 10)%2,
        s.x,
        s.y + s.z,
        s.a + s.animt*0.5,
        1, 1,
        0.5, 0.5,
        s.left
      )
      
      pal(10, 10)
      pal(2, 2)
      pal(1, 1)
    else
      aspr(
        54+flr(s.animt * 10)%2,
        s.x,
        s.y + s.z,
        s.a + s.animt*0.5,
        1, 1,
        0.5, 0.5,
        s.left
      )
    end
  end

end


do -- smoke

  function create_smoke(x, y, spd, r, c, a)
    if IS_SERVER then return end
  
    local a = a or rnd(1)
    local spd = (0.75 + rnd(0.5)) * spd * 30
    
    local s={
      x  = x,
      y  = y,
      vx = spd * cos(a),
      vy = spd * sin(a),
      r  = r or 1+rnd(3),
      c  = c or pick{0,1,6},
      update = update_smoke,
      draw   = draw_smoke,
      regs   = {"to_update","to_draw4", "particles"}
    }

    register_object(s)
    
    return s
  end
  
  function update_smoke(s)
    s.x = s.x + s.vx * dt()
    s.y = s.y + s.vy * dt()
    
    s.vx = lerp(s.vx, 0, 3*dt())
    s.vy = lerp(s.vy, -7.5, 3*dt())
    
    s.r = s.r - 0.75 * dt()
    if s.r < 0 then
      deregister_object(s)
    end
  end

  function draw_smoke(s)
    circfill(s.x, s.y, s.r, s.c)
  end

end


do -- explosion

  function create_explosion(x, y, r, c)
    if IS_SERVER then return end
  
    local e={
      x = x,
      y = y,
      r = r,
      p = 0,
      c = c or 14,
      recursive = true,
      draw = draw_explosion,
      regs = {"to_draw4"}
    }
    
    register_object(e)
    
    return e
  end
  
  function draw_explosion(s)
    local c = ({6,6,14,14,14,14,14,s.c,s.c})[flr(s.p)+1]
    local r = s.r + max(s.p/4-1,0)
    
    local foo
    if s.p<7 then foo=circfill
    else foo=circ end
    
    foo(s.x, s.y, r, c)
    
    s.p = s.p + 60*dt()
    
    local p = flr(s.p)
    if p == 1 and s.p % 1 < 60 * dt() and s.recursive then
      if s.r > 4 then
        for i = 0,1 do
          local a, l = rnd(1), (0.8+rnd(0.4)) * s.r
          local x = s.x + l*cos(a)
          local y = s.y + l*sin(a)
          local r = (0.25 + rnd(0.5)) * s.r
          create_explosion(x, y, r, s.c)
        end
        
        for i=0,2 do
          create_smoke(s.x, s.y, 1, nil, chance(50) and s.c)
        end
      end
    end
    
    if s.p >= 8 then
      deregister_object(s)
    end
  end

end


do -- wind

  local wind_dir = 1
  local last_sfx = nil
  local timer, timerb, timerc = 0, 0, 0
  function wind_maker()
    if IS_SERVER then return end
    
    timer = timer - dt()
    if timer < 0 then
      create_wind()
      timer = 0.01 + rnd(0.14)
    end
    
    timerb = timerb - dt()
    if timerb <= 0 then
      wind_dir = -wind_dir
      timerb = 5 + rnd(30)
    end
    
    timerc = timerc - dt()
    if timerc <= 0 then
      sfx("wind_"..pick({'a', 'b', 'c', 'd', 'e'}), nil, nil, 0.7 + rnd(0.4), 5+rnd(10))
      timerc = 1.5 + rnd(1)
    end
  end
  
  function create_wind()
    local cx, cy = get_camera_pos()
    
    local x, y, m1, m2
    repeat
      x = flr((cx + rnd(screen_w() + 32) - 16) / 8)
      y = flr((cy + rnd(screen_h() + 32) - 16) / 8)
      m1 = get_maptile(x, y)
      m2 = get_maptile(x + wind_dir, y)
    until m1 and m2 and m1 ~= 2 and m2 ~=2
    x = x * 8 + 2 + rnd(4)
    y = y * 8 + 2 + rnd(4)
    
    local s = {
      x = x,
      y = y,
      dir   = wind_dir,
      state = pick{'a', 'b', 'c'},
      animt = 0,
      flipx = wind_dir < 0,
      flipy = chance(50),
      update = update_wind,
      draw   = draw_wind,
      regs   = {"to_update", "to_draw0", "particles"}
    }
    
    s.life = anim_length("wind", s.state)
    
    register_object(s)
    return s
  end
  
  function update_wind(s)
    s.animt = s.animt + dt()
    
    if s.animt >= s.life then
      deregister_object(s)
    end
  end
  
  function draw_wind(s)
    local x = s.x + s.dir * s.animt/0.06 * 0.5
    draw_anim(x, s.y, "wind", s.state, s.animt, s.flipx, s.flipy)
  end

end


do -- ripples

  function create_ripple(x, y)
    if IS_SERVER then return end
    
    local s = {
      x = x,
      y = y,
      a = rnd(1),
      animt = 0,
      update = update_ripple,
      draw = draw_ripple,
      regs = {"to_update", "water", "particles"}
    }
    
    register_object(s)
    return s
  end
  
  function update_ripple(s)
    s.animt = s.animt + dt()
    if s.animt/0.1 > 5 then
      deregister_object(s)
    end
  end
  
  function draw_ripple(s)
    local n = flr(min(s.animt/0.1, 5))
    aspr(0x280+n*3, s.x, s.y, s.a, 3, 3)
  end
end