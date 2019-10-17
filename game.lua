
require("object")
require("anim")

require("map")
require("player")
require("weapons")
require("bullets")
require("fx")


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
    cam = create_camera(0, 0)
  end
  
  init_anims(get_anims())
  
  init_map()
  
  init_game()
end

function _update()
  if not IS_SERVER and btnp("mouse_lb") then
    add_shake(4)
  end
  
  if my_id then
    cam.follow = player_list[my_id]
  end
  
  grow_walls()

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

--  cam.follow = create_player(nil, 64, 64)
  
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
    --local x, y = ceil(s.x-camx), ceil(s.y-camy)
    local x, y = s.x-camx, s.y-camy
    
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
      s.x = lerp(s.x, s.follow.x-scrnw/2, dt()*10)
      s.y = lerp(s.y, s.follow.y-scrnh/2, dt()*10)
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
  
  local _sfx = sfx
  function sfx(id, x, y, pitch, volume)
    local camx, camy = get_camera_pos()
    x = x - camx
    y = y - camy
    
    _sfx(id, dist(x, y), atan2(x, y), pitch)
  end
end



function get_anims()
  return {
    player = {
      idle = {
        dt = 0.1,
        sprites = {128, 130, 132, 134, 136, 138},
        w = 2,
        h = 2
      },
      run = {
        dt = 0.04,
        sprites = {160,162,164,166,168,170,172,174,192,194,196,198,200,202,204,206},
        w = 2,
        h = 2
      },
      hurt = {
        dt = 0.035,
        sprites = {140,140,140,140,140,140,140},
        w = 2,
        h = 2
      }
    },
    
    helldog = {
      idle = {
        dt = 0.04,
        sprites = {292, 294, 296, 294, 292, 290, 288, 290, 292, 294, 296, 294, 292, 290, 288, 290, 292, 294, 296, 294, 292, 290, 288, 290, 292, 294, 296, 294, 292, 290, 288, 290, 292, 294, 296, 294, 292, 290, 288, 290, 292, 294, 296, 294, 292, 290, 288, 290, 292, 294, 296, 294, 292, 290, 288, 290, 292, 294, 296, 294, 292, 290, 288, 290, 292, 294, 296, 294, 292, 290, 288, 290, 292, 294, 296, 294, 292, 290, 288, 290, 292, 294, 296, 294, 292, 290, 288, 290, 
                   292, 294, 296, 294, 292, 290, 288, 290, 292, 294, 296, 294, 292, 290, 288, 290, 292, 294, 296, 294, 292, 290, 288, 290, 292, 294, 296, 294, 292, 290, 288, 290, 292, 294, 296, 294, 292, 290, 288, 290, 292, 294, 296, 294, 292, 290, 288, 290, 292, 294, 296, 294, 292, 290, 288, 290, 292, 294, 296, 294, 292, 290, 288, 290, 292, 294, 296, 294, 292, 290, 288, 290, 292, 294, 296, 294, 292, 290, 288, 290, 292, 294, 296, 294, 292, 290, 288, 290, 
                   292, 294, 296, 294, 292, 290, 288, 290, 292, 294, 296, 294, 292, 290, 288, 290, 292, 294, 296, 294, 292, 290, 288, 290, 292, 294, 296, 294, 292, 290, 288, 290, 292, 294, 296, 294, 292, 290, 288, 290, 292, 294, 296, 294, 292, 290, 288, 290, 292, 294, 296, 294, 292, 290, 288, 290, 292, 294, 296, 294, 292, 290, 288, 290, 292, 294, 296, 294, 292, 290, 288, 290, 292, 294, 296, 294, 292, 290, 288, 290, 292, 294, 296, 294, 292, 290, 288, 290, 
                   298, 298, 300, 300, 300, 300, 300, 300, 300, 300, 300, 300, 300, 300, 300, 300, 302, 302, 302},
        w = 2,
        h = 2
      },
      run = {
        dt = 0.06,
        sprites = {324, 326, 328, 330, 332, 334, 320, 322},
        w = 2,
        h = 2
      },
      hurt = {
        dt = 0.035,
        sprites = {352, 352, 352, 352, 352, 352, 352},
        w = 2,
        h = 2
      },
      attack = {
        dt = 1.3/28,
        sprites = {328, 228, 228, 228, 228, 228, 228,228, 228, 228, 228, 228, 228, 228},
        w = 2,
        h = 2
      },
      bush = {
        dt = 0.15,
        sprites = {354, 356, 358},
        w = 2,
        h = 2
      }
    },
    
    wind = {
      a = {
        dt = 0.06,
        sprites = {64,65,66,67,68,69,70,71,72,73,74,75,76,78}
      },
      b = {
        dt = 0.06,
        sprites = {80,81,82,83,84,85,86,87,88,89}
      },
      c = {
        dt = 0.06,
        sprites = {96,97,98,99,100,101,102,103,104,105}
      }
    },
    
    shine = {
      a = {
        dt = 0.03,
        sprites = {90,91,92,93,94}
      },
      b = {
        dt = 0.03,
        sprites = {106,107,108,109,110}
      }
    }
  }
end