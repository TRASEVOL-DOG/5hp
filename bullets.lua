bullets = {}

_bullet_def_val = { -- act as default values
  speed = 200,
  life = .5,
  type = 1,
  dist_spawn = 8,
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
           },
    wall_dmg = 2
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
  
  local co    = cos(angle)
  local si    = sin(angle)       
  local vx    = params.vx or speed * co
  local vy    = params.vy or speed * si
             
  local x     = params.x or player.x + _bullet_def_val.dist_spawn * co
  local y     = params.y or player.y + _bullet_def_val.dist_spawn * si
  
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
  
  while check_mapcol(s, s.x, s.y, 2, 2) do
    s.x = s.x - co
    s.y = s.y - si
  end
   
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
    
    bullet_movement(s)
    
  elseif s.state == "stopped" then
  
    s.frame_left = s.frame_left - 1 
    if s.frame_left < 1 then s.state = "moving" end
    
  elseif s.state == "killed" then
  
    s.frame_left = s.frame_left - 1 
    if s.frame_left < 1 then deregister_bullet(s) end  
    
  end
  
end

function bullet_movement(s)

  -- position prevision
  local nx = s.x + s.vx * dt()
  local ny = s.y + s.vy * dt()
  
  -- collision check
  local dirx, diry = sgn(s.vx), sgn(s.vy)
  local col = check_mapcol(s, nx, s.y, 2, 2)
  if col then
    s.vx = -s.vx * 0.75
    s.vy = s.vy * 0.75
    s.angle = -(s.angle - 0.25) + 0.25
    s.life = s.life * 0.75
    
    hurt_wall(
      flr((nx + col.dir_x)/8),
      flr((s.y + col.dir_y)/8),
      _types[s.type].wall_dmg
    )
    
    local cx = nx + dirx * 1
    local tx = cx - cx % 8 + 4
    nx = tx - dirx * (4.25 + 1)
  end
  
  local col = check_mapcol(s, s.x, ny, 2, 2)
  if col then
    s.vx = s.vx * 0.75
    s.vy = -s.vy * 0.75
    s.angle = - s.angle
    s.life = s.life * 0.75
    
    hurt_wall(
      flr((s.x + col.dir_x)/8),
      flr((ny + col.dir_y)/8),
      _types[s.type].wall_dmg
    )
    
    local cy = ny + diry * 1
    local ty = cy - cy % 8 + 4
    ny = ty - diry * (4.25 + 1)
  end
  
  -- apply new positions
  s.x = nx
  s.y = ny
end

function kill_bullet(s)
  add_shake(2)    
  s.state = "killed"
  s.frame_left = _bullet_def_val.nb_frame_death
end

function deregister_bullet(s)
  deregister_object(s)
  bullets[s.id] = nil
end

function draw_bullet(s) 
  local b = _types[s.type].spr[s.state]
  aspr(b.s, s.x, s.y-2, s.angle, b.w, b.h, 0.5, 0.5)
end

















