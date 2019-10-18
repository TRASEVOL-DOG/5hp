bullets = {}

_bullet_def_val = { -- act as default values
  type = 1, 
  damage = 1,
  speed = 200,
  life = .5,
  dist_spawn = 8,
  nb_frame_spawn = 3,
  nb_frame_death = 3,
  sfx_vol = 1,
  
  resistance = 0,
  spd_loss_col = 0.75,
  life_loss_col = 0.75,
  wall_dmg = 2
}

_g_types = { -- bullet graphical types
  { w = 16, 
    h = 8, 
    spr = { 
            moving  = { s = 237, w = 2, h = 1}, 
            stopped = { s = 236, w = 1, h = 1}, 
            killed  = { s = 239, w = 1, h = 1}
           },
  },
  { w = 8, 
    h = 8, 
    spr = { 
            moving  = { s = 236, w = 1, h = 1}, 
            stopped = { s = 236, w = 1, h = 1}, 
            killed  = { s = 236, w = 1, h = 1}
           },
  }
}
-- bullet behavior types
-- type 1 gets all behavior from _bullet_def_val
-- the others gets theirs from what's specified and if a value isn't, from_bullet_def_val

_b_types = {
  {},
  {sfx_vol = .75}, -- ar bullet
  {resistance = .03, explosive = true, wall_dmg = 4, speed = 200, life = 1}, -- gl bullet
}


local bullet_nextid = 1

function create_bullet(player_id, id, _b_type, _g_type, angle, spd_mult, resistance)
  local player = player_list[player_id]
  if not player then return end
  
  local params = _b_types[_b_type] or {}
  
  local type   = params.type or _bullet_def_val.type
  local damage = params.damage or _bullet_def_val.damage
  local w      = _g_types[_g_type].w
  local h      = _g_types[_g_type].h
  
  local speed      = (params.speed or _bullet_def_val.speed) * (spd_mult or 1)   
  
  local angle      = angle or ( v_to_angle(player.vx, player.vy) - .015 + rnd(.03) )
  
  local co    = cos(angle)
  local si    = sin(angle)       
  local vx    = params.vx or speed * co
  local vy    = params.vy or speed * si
             
  local x     = params.x or player.x + _bullet_def_val.dist_spawn * co
  local y     = params.y or player.y + _bullet_def_val.dist_spawn * si
  
  local life  = params.life or _bullet_def_val.life -- remaining life (despawns at 0)
  local nb_frame_spawn = params.nb_frame_spawn or _bullet_def_val.nb_frame_spawn
  
  local s = {
    id       = bullet_nextid,
    from     = player_id,
    _g_type  = _g_type,
    _b_type  = _b_type,
    damage   = damage,
    
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
    s.vx = -s.vx * _bullet_def_val.spd_loss_col
    s.vy = s.vy * _bullet_def_val.spd_loss_col
    s.angle = -(s.angle - 0.25) + 0.25
    s.life = s.life * _bullet_def_val.life_loss_col
    
    hurt_wall(
      flr((nx + col.dir_x)/8),
      flr((s.y + col.dir_y)/8),
      _b_types[s._b_type].wall_dmg
    )
    
    local cx = nx + dirx * 1
    local tx = cx - cx % 8 + 4
    nx = tx - dirx * (4.25 + 1)
  end
  
  local col = check_mapcol(s, s.x, ny, 2, 2)
  if col then
    s.vx = s.vx * _bullet_def_val.spd_loss_col
    s.vy = -s.vy * _bullet_def_val.spd_loss_col
    s.angle = - s.angle
    s.life = s.life * _bullet_def_val.life_loss_col
    
    hurt_wall(
      flr((s.x + col.dir_x)/8),
      flr((ny + col.dir_y)/8),
      _b_types[s._b_type].wall_dmg
    )
    
    local cy = ny + diry * 1
    local ty = cy - cy % 8 + 4
    ny = ty - diry * (4.25 + 1)
  end
  
  s.vx = s.vx * (1 - (get_value("resistance", s) or 0))
  s.vy = s.vy * (1 - (get_value("resistance", s) or 0))
  
  -- apply new positions
  s.x = nx
  s.y = ny
end

function kill_bullet(s)
  add_shake(2)    
  s.state = "killed"
  s.frame_left = _bullet_def_val.nb_frame_death
  if get_value("explosive", s) then
    create_explosion(s.x, s.y, 17+rnd(5), (s.from == my_id and 9 or 8))
    -- sfx("explosion", s.x, s.y)
    
    add_shake(8)
    
    local tx = flr(s.x / 8)
    local ty = flr(s.y / 8)
    
    hurt_wall(tx-1, ty-2, 7)
    hurt_wall(tx,   ty-2, 7)
    hurt_wall(tx+1, ty-2, 7)

    hurt_wall(tx-2, ty-1, 7)
    hurt_wall(tx-1, ty-1, 7)
    hurt_wall(tx,   ty-1, 7)
    hurt_wall(tx+1, ty-1, 7)
    hurt_wall(tx+2, ty-1, 7)

    hurt_wall(tx-2, ty  , 7)
    hurt_wall(tx-1, ty  , 7)
    hurt_wall(tx,   ty  , 7)
    hurt_wall(tx+1, ty  , 7)
    hurt_wall(tx+2, ty  , 7)

    hurt_wall(tx-2, ty+1, 7)
    hurt_wall(tx-1, ty+1, 7)
    hurt_wall(tx,   ty+1, 7)
    hurt_wall(tx+1, ty+1, 7)
    hurt_wall(tx+2, ty+1, 7)

    hurt_wall(tx-1, ty+2, 7)
    hurt_wall(tx,   ty+2, 7)
    hurt_wall(tx+1, ty+2, 7)
  end
end

function get_value(name, s)
  local z = (_b_types[s._b_type] and _b_types[s._b_type][name]) or (s[name]) or _bullet_def_val[name]
  return z
end

function deregister_bullet(s)
  deregister_object(s)
  bullets[s.id] = nil
end

function draw_bullet(s) 
  local b = _g_types[s._g_type].spr[s.state]
  aspr(b.s, s.x, s.y-2, s.angle, b.w, b.h, 0.5, 0.5)
end

















