bullets = {}
dead_bullets = {}

_bullet_def_val = { -- act as default values
  _type   = 1, 
  _g_type = 1, 
  
  damage = 2, -- done to entities
  speed  = 200,
  life   = .5, -- in time
  dist_spawn = 8, -- from center of player
  spawn_time = 0.1,
  death_time = 0.1,
  
  resistance    = 0, -- loss of speed each frame going from 0 to 1 being the max
  spd_loss_col  = 0.75,-- loss of speed on colision 
  life_loss_col = 0.75,-- loss of life on colision  
  wall_dmg      = 2,
  wall_death    = false, -- if true, kill_bullet is called on wall collision
  
  burst_into  = nil,
  burst_count = nil,
  
  shake_mult = 1,
  sfx_vol    = 1,
}

_g_types = { -- bullet graphical types
  { w = 8,  -- (1) regular bullet
    h = 8, 
    spr = { 
            moving  = { s = 0x201, w = 2, h = 1}, 
            stopped = { s = 0x200, w = 1, h = 1}, 
            killed  = { s = 0x203, w = 1, h = 1}
          },
  },
  { w = 6,  -- (2) grenado
    h = 6, 
    spr = { 
            moving  = { s = 0x204, w = 1, h = 1}, 
            stopped = { s = 0x210, w = 2, h = 2}, 
            killed  = { s = 0x213, w = 2, h = 2}
          },
  },
  { w = 10, -- (3) big bullet
    h = 10,
    spr = {
            moving  = { s = 0x212, w = 2, h = 1},
            stopped = { s = 0x210, w = 2, h = 2},
            killed  = { s = 0x214, w = 2, h = 2}
          }
  },
  { w = 8, -- (4) fire ball!
    h = 8,
    spr = {
            moving  = { s = 0x231, w = 2, h = 1},
            stopped = { s = 0x230, w = 1, h = 1},
            killed  = { s = 0x233, w = 1, h = 1}
          }
  },
  { w = 8, -- (5) bazooka missile
    h = 8,
    spr = {
            moving  = { s = 0x205, w = 2, h = 1},
            stopped = { s = 0x210, w = 2, h = 2},
            killed  = { s = 0x214, w = 2, h = 2}
          }
  },
  { w = 8, -- (6) bursting ball
    h = 8,
    spr = {
            moving  = { s = 0x210, w = 2, h = 2},
            stopped = { s = 0x216, w = 2, h = 2},
            killed  = { s = 0x214, w = 2, h = 2}
          }
  }
}
-- bullet types
-- we'll leave g_types just to keep using that useful table for now but in the end, every type of bullet should have its own g_type and we'll delete _g_types

_types = {
  {}, -- gun
  {sfx_vol = .75}, -- ar ,shotgun and mg
  {_g_type = 2, damage = 5, resistance = 3, explosive = true, wall_dmg = 4, speed = 200, life = 1}, -- gl
  {_g_type = 3, sfx_vol = .75, damage = 4}, -- hr
  {_g_type = 4, sfx_vol = .75, damage = 1, speed = 150, life = .25, wall_dmg = 3, resistance = 5, wall_death = true }, -- FIRE
  {_g_type = 5, damage = 5, explosive = true, speed = 170, life = 2, wall_dmg = 5, wall_death = true}, -- bz
  {_g_type = 6, damage = 5, burst_into = 8, burst_count = 6, speed = 170, resistance = 4, wall_dmg = 5, wall_death = true}, -- burster
  {_g_type = 1, damage = 2, speed = 200, life = 0.35, resistance = 7, wall_dmg = 1}, -- burst shots
}


local bullet_nextid = 1

function create_bullet(player_id, id, _type, angle, spd_mult, resistance)
  if id and dead_bullets[id] then return end

  local player = players[player_id]
  if not player then return end
  
  local params = _types[_type] or {}
  
  local _type    = _type or _bullet_def_val._type
  local damage  = params.damage or _bullet_def_val.damage
  local _g_type = _types[_type]._g_type or _bullet_def_val._g_type
  local w       = _g_types[_g_type].w
  local h       = _g_types[_g_type].h
  
  local speed      = (params.speed or _bullet_def_val.speed) * (spd_mult or 1)   
  
  local angle      = angle or ( v_to_angle(player.vx, player.vy) - .015 + rnd(.03) )
  
  local co    = cos(angle)
  local si    = sin(angle)       
  local vx    = params.vx or speed * co
  local vy    = params.vy or speed * si
             
  local x     = params.x or player.x + _bullet_def_val.dist_spawn * co
  local y     = params.y or player.y + _bullet_def_val.dist_spawn * si
  
  local life  = params.life or _bullet_def_val.life -- remaining life (despawns at 0)
  local spawn_time = params.spawn_time or _bullet_def_val.spawn_time
  
  local s = {
    id       = id,
    from     = player_id,
    _type     = _type,
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
    time_left = spawn_time,
    anim_state = "stopped",
    
    update = update_bullet,
    draw   = draw_bullet,
    regs   = {"to_update", "to_draw0", "bullet"},
    
    diff_x = 0,
    diff_y = 0
  }
  
  while check_mapcol(s, s.x, s.y, 2, 2) do
    s.x = s.x - co
    s.y = s.y - si
  end
  
  if IS_SERVER then
    s.id = bullet_nextid
    bullet_nextid = bullet_nextid + 1
  end
  
  if s.id then
    if bullets[s.id] then
      deregister_object(bullets[s.id])
    end
    
    bullets[s.id] = s
  end
  
  register_object(s)
  return s
end

function update_bullet(s) 
  s.animt = s.animt + dt()

  if s.state == "moving" then 
  
    s.life = s.life - dt()  
    if s.life < 0 then kill_bullet(s) return end
    
    bullet_movement(s)
    
  elseif s.state == "stopped" then
  
    s.time_left = s.time_left - dt()
    if s.time_left <= 0 then s.state = "moving" end
    
  elseif s.state == "killed" then
  
    s.time_left = s.time_left - dt() 
    if s.time_left <= 0 then deregister_bullet(s) end  
    
  end
  
  bullet_collisions(s)
  
  s.diff_x = lerp(s.diff_x, 0, dt())
  s.diff_y = lerp(s.diff_y, 0, dt())
  
  if not IS_SERVER and get_maptile(s.x/8, s.y/8) == 12 and s.animt % 0.03 < dt() then
    create_ripple(s.x, s.y)
  end
end

function bullet_movement(s)

  -- position prevision
  local nx = s.x + s.vx * dt()
  local ny = s.y + s.vy * dt()
  
  -- collision check
  local dirx, diry = sgn(s.vx), sgn(s.vy)
  local xcol = check_mapcol(s, nx, s.y, 2, 2)
  if xcol then
    s.vx = -s.vx * _bullet_def_val.spd_loss_col
    s.vy = s.vy * _bullet_def_val.spd_loss_col
    s.angle = -(s.angle - 0.25) + 0.25
    s.life = s.life * _bullet_def_val.life_loss_col
    
    hurt_wall(
      flr((nx + xcol.dir_x)/8),
      flr((s.y + xcol.dir_y)/8),
      get_value("wall_dmg", s)
    )
    
    local cx = nx + dirx * 1
    local tx = cx - cx % 8 + 4
    nx = tx - dirx * (4.25 + 1)
  end
  
  local ycol = check_mapcol(s, s.x, ny, 2, 2)
  if ycol then
    s.vx = s.vx * _bullet_def_val.spd_loss_col
    s.vy = -s.vy * _bullet_def_val.spd_loss_col
    s.angle = - s.angle
    s.life = s.life * _bullet_def_val.life_loss_col
    
    hurt_wall(
      flr((s.x + ycol.dir_x)/8),
      flr((ny + ycol.dir_y)/8),
      get_value("wall_dmg", s)
    )
    
    local cy = ny + diry * 1
    local ty = cy - cy % 8 + 4
    ny = ty - diry * (4.25 + 1)
  end
  
  s.vx = s.vx * (1 - (get_value("resistance", s) or 0) * dt())
  s.vy = s.vy * (1 - (get_value("resistance", s) or 0) * dt())
  
  -- apply new positions
  s.x = nx
  s.y = ny
  
  -- kill bullet if relevant
  if (xcol or ycol) and get_value("wall_death", s) then
    kill_bullet(s)
  end
end

function bullet_collisions(s)
  local pla = collide_objgroup(s, "player")
  if pla and pla.id ~= s.from and not pla.dead then
    kill_bullet(s)
    hit_player(pla, s)
    return
  end

  local enem = collide_objgroup(s, "enemy")
  if enem then
    kill_bullet(s)
    hit_enemy(enem, s.id)
    return
  end

  local destr = all_collide_objgroup(s, "destructible")
  for _, d in pairs(destr) do
    if not d.dead then
      kill_bullet(s)
      kill_destructible(d, s.id)
      return
    end
  end
end

local bullet_explosion, bullet_burst
function kill_bullet(s)
  if s.id and dead_bullets[s.id] then -- to avoid double explosions
    deregister_object(s)
    bullets[s.id] = nil
    return
  end
  
  if s.dead then return end

  s.dead = true
  s.state = "killed"
  s.time_left = _bullet_def_val.death_time
  
  if get_value("explosive", s) then
    bullet_explosion(s)
  end
  
  if get_value("burst_into", s) then
    bullet_burst(s)
  end
  
  if s.id then
    dead_bullets[s.id] = true
  end
end

function bullet_explosion(s)
  create_explosion(s.x, s.y, 18+rnd(3), (s.from == my_id and 9 or 8))
  sfx("explosion", s.x, s.y)
  
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
  
  s.w = 17
  s.h = 17
  
  local pla = all_collide_objgroup(s, "player")
  for _, p in pairs(pla) do
    if not p.dead then
      hit_player(p, s)
    end
  end
  
  local enem = all_collide_objgroup(s, "enemy")
  for _, e in pairs(enem) do
    hit_enemy(e, s.id)
  end
  
  local destr = all_collide_objgroup(s, "destructible")
  for _, d in pairs(destr) do
    if not d.dead then
      kill_destructible(d, s.id)
    end
  end

  local l = 18
  for i = 1, 7 do
    local a = i/7 + give_or_take(0.05)
    create_ripple(
      s.x + l*cos(a),
      s.y + l*sin(a)
    ).animt = rnd(0.2)
  end
end

function bullet_burst(s)
  local t = get_value("burst_into", s)
  local n = get_value("burst_count", s)
  
  for i = 1, n do
    local a = i/n + give_or_take(0.5/n)
    local b = create_bullet(s.from, nil, t, a)
    
    b.x = s.x
    b.y = s.y
  end
end

function get_value(name, s)
  local z = (_types[s._type] and _types[s._type][name]) or (s[name]) or _bullet_def_val[name]
  return z
end

function deregister_bullet(s)
  deregister_object(s)
  
  if s.id then
    bullets[s.id] = nil
--    dead_bullets[s.id] = true
  end
end

function draw_bullet(s) 
  local b = _g_types[get_value("_g_type", s)].spr[s.state]
  aspr(b.s, s.x, s.y-2, s.angle, b.w, b.h, 0.5, 0.5)
end

















