
bullet_list = {} -- { id : bullet }
dead_bullets = {}
local bullet_nextid = 1

function create_bullet(player_id, id)
  if dead_bullets[id] then return end
  
  if player_id == my_id then
    if id then
      for b in group("bullet") do
        if b.from == player_id and not b.id then
          b.id = id
          bullet_list[id] = b
          
          bullet_nextid = max(bullet_nextid, id + 1)
          return
        end
      end
    end
  end
  bullet_const = {
    speed_lost_rebound  = 1/4,
  
  }
  local s = {
    from                = player_id, -- player id
    type                = 0,
    w                   = 4,
    h                   = 4,
    animt               = 0,
    anim_state          = "stopped",
    kill_anim_t         = .1,
    update              = update_bullet,
    draw                = draw_bullet,
    regs                = {"to_update", "to_draw1", "bullet"},
    speed               = 18, -- per second
    speed_lost_rebound  = 1/4,
    v                   = { x = 0, y = 0}, -- movement vector
    time_despawn        = 0.8, -- seconds a bullet would have at spawn before despawn
    timer_despawn       = 0, -- seconds remaining before despawn
    time_hold           = player_id == my_id and delay or 0, -- time to hold the bullet before it shoots off (should make server sync look smoother)
    diff_x              = 0, -- difference with server position (used to smoothen syncing)
    diff_y              = 0  -- ^^^
  }
  
  local player = player_list[player_id]
  if not player then return end
  
  -- setting id
  
  if id then -- assigned by server
    if bullet_list[id] then
      deregister_object(bullet_list[id])
    end
  
    s.id = id
    bullet_nextid = max(bullet_nextid, id + 1)
    
  elseif server_only then -- assigning id now
    s.id = bullet_nextid
    bullet_nextid = bullet_nextid + 1
  end
  
  if s.id then
    bullet_list[s.id] = s
  end
  
  --spawn according to vector

  local angle = player.angle - .015 + rnd(.03)
  
  s.v.x = cos(angle)
  s.v.y = sin(angle)
  s.x = player.x + player.diff_x + (player.w + s.w) * s.v.x 
  s.y = player.y + player.diff_y + (player.h + s.h) * s.v.y - 2 -- offset to line up with gun
    
  -- check if in wall
  s.anim_state = "stopped"
  
  local col = check_mapcol(s,s.x,s.y)
  while col do
    s.x = s.x - s.v.x
    s.y = s.y - s.v.y
    col = check_mapcol(s)
  end
  
  s.timer_despawn = s.time_despawn
  register_object(s)
  
  if s.from == my_id then 
    sfx("shoot", s.x, s.y, 0.95+rnd(0.1)) 
  else
    sfx("enemy_shoot", s.x, s.y)
  end
  
  return s
end

function update_bullet(s)
  if s.time_hold > 0 then
    s.time_hold = s.time_hold - delta_time
    return
  end
  
  if not server_only then
    s.diff_x = lerp(s.diff_x, 0, 7*delta_time)
    s.diff_y = lerp(s.diff_y, 0, 7*delta_time)
  end
  

  s.timer_despawn = s.timer_despawn - delta_time
  
  
  if( s.timer_despawn < 0 and s.anim_state ~= "killed") then 
    kill_bullet(s)
  elseif( s.timer_despawn >  s.time_despawn - 0.05 ) then 
    s.anim_state = "stopped" 
  elseif s.anim_state == "killed" then 
    s.kill_anim_t = s.kill_anim_t - delta_time
    if s.kill_anim_t < 0 then
      deregister_bullet(s)
    end
  else
    s.anim_state = "moving"
    update_move_bullet(s)
  end
  
  do_collisions_obj(s) -- collision with objects
  
end

function update_move_bullet(s)
  -- client syncing stuff
  s.x, s.y = s.x + s.diff_x, s.y + s.diff_y

  local ow, oh = s.w, s.h
  s.w, s.h = 2,2
  
  -- actual move update
  local nx = s.x + s.v.x * s.speed * delta_time * 10
  local col = check_mapcol(s,nx)
  if col then
    local tx = flr((nx + col.dir_x * s.w * 0.5) / 8)
    s.x = tx * 8 + 4 - col.dir_x * (8 + s.w + 0.5) * 0.5
    s.v.x = s.v.x *-1
    s.speed = s.speed * ( 1 - s.speed_lost_rebound )
    s.timer_despawn = s.timer_despawn * ( 1 - s.speed_lost_rebound ) -- Remy was here: made bullet lose lifetime on bounce
    sfx("bullet_wall_bounce", s.x, s.y, 0.9+rnd(0.2))
  else
    s.x = nx
  end
  
  local ny = s.y + s.v.y * s.speed * delta_time * 10
  local col = check_mapcol(s,s.x,ny)
  if col then
    local ty = flr((ny + col.dir_y * s.h * 0.5) / 8)
    s.y = ty * 8 + 4 - col.dir_y * (8 + s.h + 0.5) * 0.5
    s.v.y = s.v.y *-1
    s.speed = s.speed * ( 1 - s.speed_lost_rebound )
    s.timer_despawn = s.timer_despawn * ( 1 - s.speed_lost_rebound )
    sfx("bullet_wall_bounce", s.x, s.y, 0.9+rnd(0.2))
  else
    s.y = ny
  end
  
  s.w, s.h = ow, oh
  
  -- more client syncing bullshit
  s.x, s.y = s.x - s.diff_x, s.y - s.diff_y
end

function do_collisions_obj(s) -- collision with objects
  local killed = collide_objgroup(s,"player")
  if killed and killed.id ~= s.from and killed.alive then
    local killer = player_list[s.from]
    send_player_off(killed, s.v.x, s.v.y )
    -- debuggg = "did colision, found killer" .. s.from .." xxxxxx"
    hurt_player(killed, killer.id, s.type)
    -- kill_player(killed, killer.id)
    kill_bullet(s)
  end
  
  local destr = all_collide_objgroup(s,"destroyable")
  if(#destr>0) then
    for i=1, #destr do
      if destr[i].alive then
        kill_bullet(s)
        kill_destroyable(destr[i], s.id)
      end
    end
  end
end

function draw_bullet(s)
  local x = s.x + s.diff_x
  local y = s.y + s.diff_y - 1
  
  if s.from == my_id then
    pal(13,12)
    pal(11,9)
  else
    pal(13,11)
    pal(11,8)
  end

  if s.anim_state == "stopped" then
    spr(236, x, y, 1, 1, atan2(s.v.x, s.v.y))
  elseif s.anim_state == "killed" then 
    spr(239, x, y, 1, 1, atan2(s.v.x, s.v.y))
  else
    spr(237, x, y, 2, 1, atan2(s.v.x, s.v.y))
  end
  
  all_colors_to()
  
  if debug_mode then
    all_colors_to(14)
    spr(57, s.x, s.y-2, 2, 1, atan2(s.v.x, s.v.y))
    all_colors_to()
  end
end

function kill_bullet(s)
  s.anim_state = "killed"
end

function deregister_bullet(s)
  deregister_object(s)
  
  if s.id then
    bullet_list[s.id] = nil
    dead_bullets[s.id] = true
  end
end