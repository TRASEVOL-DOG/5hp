bullets = {}

_bullet_def_val = { -- act as default values
  speed = 200,
  life = .5,
  type = 1,
  dist_spawn = 13,
  nb_frame_spawn = 3,
  nb_frame_death = 3,
}

_types = { -- bullet types
  { w = 16, 
    h = 8, 
    spr = { 
            moving  = { s = 237, w = 2, h = 1}, 
            stopped = { s = 236, w = 1, h = 1}, 
            killed  = { s = 239, w = 1, h = 1}
           }
  }
}


local bullet_nextid = 1

function create_bullet(player_id, id, params)

  player_id = 0
  
  local player = player_list[player_id]
  if not player then return end
  
  local type = params.type or _bullet_def_val.type
  local w     = _types[type].w
  local h     = _types[type].h
  
  local speed = params.speed or _bullet_def_val.speed   
  local angle = params.angle or ( v_to_angle(player.vx, player.vy) - .015 + rnd(.03) )
  
  local c     = cos(angle)
  local s     = sin(angle)       
  local vx    = params.vx or speed * c
  local vy    = params.vy or speed * s
             
  local x     = params.x or player.x + _bullet_def_val.dist_spawn * c
  local y     = params.y or player.y + _bullet_def_val.dist_spawn * s
  
  local life  = params.life or _bullet_def_val.life -- remaining life (despawns at 0)
  local nb_frame_spawn = params.nb_frame_spawn or _bullet_def_val.nb_frame_spawn
  
  local s = {
    id = bullet_nextid,
    from = player_id,
    type = type,
    
    x  = x,
    y  = y,
    vx = vx,
    vy = vy,
    
    angle = angle,
    
    w  = w,
    h  = h,
    
    speed = speed,
    life = life,
    
    state = "stopped",
    animt = 0,
    frame_left = nb_frame_spawn,
    anim_state = "stopped",
    
    update = update_bullet,
    draw   = draw_bullet,
    regs   = {"to_update", "to_draw0", "bullet"}
  }
   
  if s.id then
    bullets[s.id] = s
  end
  
  bullet_nextid = bullet_nextid + 1
  
  register_object(s)
  return s
end

function update_bullet(s) 
  
  if s.state == "moving" then 
  
    s.life = s.life - dt()  
    if s.life < 0 then kill_bullet(s) end
    
    s.x = s.x + s.vx * dt()
    s.y = s.y + s.vy * dt()
    
  elseif s.state == "stopped" then
  
    s.frame_left = s.frame_left - 1 
    if s.frame_left < 1 then s.state = "moving" end
    
  elseif s.state == "killed" then
  
    s.frame_left = s.frame_left - 1 
    if s.frame_left < 1 then deregister_bullet(s) end  
    
  end
  
end

function kill_bullet(s)
  add_shake(8)    
  s.state = "killed"
  s.frame_left = _bullet_def_val.nb_frame_death
end

function deregister_bullet(s)
  deregister_object(s)
  bullets[s.id] = nil
end

function draw_bullet(s) 
  local b = _types[s.type].spr[s.state]  
  aspr(b.s, s.x, s.y, s.angle, b.w, b.h, b.w/2, b.h/2)
end

















