
require("object")
require("anim")

require("map")


c_drk = {[0]=1, 6, 1, 0, 1, 2, 6, 3, 0, 4, 5, 3, 9, 11, 13}
c_lit = {[0]=3, 4, 5, 11, 9, 10, 1, 13, 11, 12, 14, 13, 14, 14, 14}

function _init()
  init_network()

  init_object_mgr(
    "player",
    "enemy",
    "bullet",
    "destroyable",
    "loot",
    "wind"
  )
  
  if not IS_SERVER then
    cursor = create_cursor()
    cam = create_camera(256, 256)
  end
  
  init_map()
  
  init_game()
  
  
end

function _update()

  update_objects()

  update_network()
end

function _draw()
  cls(10)  
  camera()
  
  draw_map()
  
  palt(0,false)
  palt(6,true)
  
  apply_camera()
  
  draw_objects(0, 3)
  
  camera()
  draw_map_top()
  apply_camera()
  
  draw_objects(4)
  
  camera()
  
  cursor:draw()
end



function init_game()

end



do -- cursor

  function update_cursor(s)
    s.animt = max(s.animt - dt()*30, 0)
    
    local x, y = btnv("mouse_x"), btnv("mouse_y") 
    s.x = x + cam.x
    s.y = y + cam.y
    
    if btnp("mouse_lb") then
      s.animt = 5
    end
  end
  
  function draw_cursor(s)
    local sp = 256+ceil(s.animt)*2
    local camx, camy = get_camera_pos()
    local x, y = round(s.x-camx), round(s.y-camy)
    
    palt(6, false)
    palt(1, true)
  
    spr(sp, x-16, y-16, 2, 2)
    spr(sp, x, y-16, 2, 2, true, false)
    spr(sp, x-16, y, 2, 2, false, true)
    spr(sp, x, y, 2, 2, true, true)
    
    palt(1, false)
  end
  
  function create_cursor()
    local s = {
      x      = 0,
      y      = 0,
      animt  = 0,
      update = update_cursor,
      draw   = draw_cursor,
      regs   = {"to_update"}
    }

    register_object(s)
    
    return s
  end

end



do -- camera

  function apply_camera()
    local shk = cam.shkp/100
    camera(round(cam.x+cam.shkx*shk), round(cam.y+cam.shky*shk))
  end
  
  function get_camera_pos()
    local shk = cam.shkp/100
    return round(cam.x+cam.shkx*shk), round(cam.y+cam.shky*shk)
  end
  
  function add_shake(powr)
    if server_only then return end
  
    local powr = powr or 3
    local a = rnd(1)
    cam.shkx = powr*cos(a)
    cam.shky = powr*sin(a)
  end
  
  function update_camera(s)
    s.shkt = s.shkt - dt()
    if s.shkt < 0 then
      if abs(s.shkx)+abs(s.shky) < 0.5 then
        s.shkx, s.shky = 0,0
      else
        s.shkx = s.shkx * (-0.5-rnd(0.2))
        s.shky = s.shky * (-0.5-rnd(0.2))
      end
      
      s.shkt = 1/30
    end
    
    if s.follow then
      local scrnw, scrnh = screen_size()
      s.x = lerp(s.x, s.follow.x-scrnw/2, delta_time*10)
      s.y = lerp(s.y, s.follow.y-scrnh/2, delta_time*10)
    end
  end
  
  function create_camera(x, y)
    local s = {
      x      = x or 0,
      y      = y or 0,
      shkx   = 0,
      shky   = 0,
      shkt   = 0,
      shkp   = 100,
      follow = nil,
      update = update_camera,
      regs   = {"to_update"}
    }
    
    register_object(s)
    
    return s
  end

end




do -- utility stuff
  
  function chance(n)
    return rnd(100) < n
  end

end