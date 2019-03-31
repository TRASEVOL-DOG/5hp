-- --enemies

-- --enemies are player that have auto behavior and no input check

-- --go to player

enemy_list = {} -- { id : enemy }
local enemy_nextid = 1
              
enemy_const = {
  view_range = 47,
  hit_range = 15,
  idle_range = 11,
  follow_speed = 60,
  attack_time = .5,
  hit_time = .2
}

function create_enemy(id, x, y, vx, vy, alive, angle, hp, behavior)
  
  local s = {
    id                  = id,
    update              = update_enemy,
    draw                = draw_enemy,
    regs                = {"to_update", "to_draw0", "enemy"},
    behave              = idle,
    v                   = { x = vx or 0, y = vy or 0 },-- movement vector 
    alive               = alive or true,
    angle               = angle or 0,
    hp                  = hp or 2,
    behavior            = behavior or "idle",
    target              = nil,
    
    animt               = 0,
    hit_timer           = 0,
    anim_state          = "idle",
    face_left           = chance(50),
    dead_sfx_player     = false,
    bounce              = false,
    last_hit_bullet     = -1,
    
    w                   = 6,
    h                   = 4,
    
    timer_attack        = 0, -- cooldown (seconds) left for bullet fire
    attacking           = false,
    
    speed               = 0,
    
    -- network stuff
    dx_input            = 0,
    dy_input            = 0,
    shot_input          = false,
    diff_x              = 0,
    diff_y              = 0,
    moved_t             = 0,
    server_death        = false
    
  }
  
  if not id then
    castle_print("/!\\ Creating an enemy with no id.")
  end
  
  if behavior == "idle" then behave = idle end
  
  if id then -- assigned by server
    if enemy_list[id] then
      deregister_object(enemy_list[id])
    end
  
    s.id = id
    enemy_nextid = max(enemy_nextid, id + 1)
    
  elseif server_only then -- assigning id now
    s.id = enemy_nextid
    enemy_nextid = enemy_nextid + 1
  end
  
  if s.id then
    enemy_list[s.id] = s
  end
  
  s.x = x or 0
  s.y = y or 0

  register_object(s)
  
  if not server_only then
    for i=1,16 do
      create_smoke(s.x, s.y, 0.75, 1+rnd(1.5), pick{1,2,3})
      -- create_explosion(s.x, s.y, 10+rnd(1.5), pick{1,2,3})
    end
  end
  
  return s
end

function update_enemy(s)
  -- debuggg = tostring(s.hp)

  s.animt = s.animt + delta_time
  if s.hit_timer > 0 then s.hit_timer = s.hit_timer - delta_time end

  -- if server_only then
  
    -- update timers
    s.timer_attack = s.timer_attack - delta_time
    
    -- find target
    s.target = player_around(s, enemy_const.hit_range)
    
    --attack if exists
    if s.timer_attack < 0 then
      if s.target then
        s.timer_attack = enemy_const.attack_time
        local p = player_list[s.target]
        if p then
            hit_player(p, nil, nil, s)
        end
        s.target = nil
      end
    end
  -- end
  
  s.target = player_around(s)
  if s.target then
    s.behave = follow
  end
  
  s.behave(s)
  
  
  local ow, oh = s.w, s.h
  s.w, s.h = 0,0
  s.in_wall = (check_mapcol(s) ~= nil)
  s.w, s.h = ow, oh
  
  if s.hit_timer > 0 then 
    s.anim_state = "hurt"
  -- elseif s.attacking then
    -- s.anim_state = "attack"
  elseif abs(s.v.x)+abs(s.v.y) > 0.1 then
    s.anim_state = "run"
    s.faceleft = s.v.x < 0
    
    if s.in_wall and s.animt%0.05 < delta_time then
      create_leaf(s.x, s.y)
    end
  else
    s.anim_state = "idle"
  end
  
end

function draw_enemy(s)
  -- circfill(s.x, s.y, enemy_const.view_range, 4)
  -- circfill(s.x, s.y, enemy_const.hit_range, 3)
--  if s.hit_timer > 0 then
--    rectfill(s.x - s.w / 2, s.y - s.h / 2 , s.x + s.w/2, s.y + s.h /2, 3)  
--  else
--    rectfill(s.x - s.w / 2, s.y - s.h / 2 , s.x + s.w/2, s.y + s.h /2, 1)  
--  end

  palt(1,true)
  palt(6,false)
  
  if s.hit_timer > 0.1 then
    all_colors_to(14)
    draw_anim(s.x, s.y-2, "helldog", s.anim_state, s.animt, 0, s.faceleft)
    all_colors_to()
  else
    
    draw_anim(s.x, s.y-2, "helldog", s.anim_state, s.animt, 0, s.faceleft)
    
  end
  
  palt(1,false)
  palt(6,true)
end

function draw_enemy_bush(s)
  if not s.in_wall then return end
  
  local co = cos(s.animt*2)
--  draw_anim(s.x, s.y-3+co, "helldog", "bush", s.animt, 0, s.faceleft)
end

function hit_enemy(s, bullet)
  if s.last_hit_bullet == bullet.id then return end
  
  s.last_hit_bullet = bullet.id
  s.hp = s.hp - get_damage_from_type(bullet.type)
  s.hit_timer = enemy_const.hit_time
    
  if s.hp < 1 then kill_enemy(s) end
end

function kill_enemy(s)

  if not server_only then
    for i=1,16 do
      create_smoke(s.x, s.y, 0.75, 1+rnd(1.5), pick{11,8,3,0})
    end
  else
    table.insert(enemy_respawner.timers, os.clock() + 35 + rnd(15))
  end
  
  sfx("get_hit", s.x, s.y) 
  
  enemy_list[s.id] = nil
  deregister_object(s)
  
end

function idle(s)
  s.v.x, s.v.y = 0,0

end

function player_around(s, view_range)
  
  local view_range = view_range or enemy_const.view_range
  -- debuggg = tostring(view_range)
  s.target = nil
  
  for i, p in pairs(player_list) do
    if p.alive and dista(s, p) < view_range then
      return p.id
    end
  end
  
  return nil
end

function players_around(s, view_range)
  
  local view_range = view_range or enemy_const.view_range

  local p = get_group_copy("player")
  local t = {}
  s.target = nil
  
  if p then
    for i, p in pairs(p) do
      if dista(s, p) < view_range then
        s.target = p.id
        t[p.id] = true
      end
    end
  end
  return t
end

function follow(s)

  local view_range = view_range or enemy_const.view_range
  local p = player_list[s.target] 
  if p then
    local dist = dista(s, p) 
    -- s.attacking = false
    if dist < view_range and dist > enemy_const.idle_range then
      s.angle = pos_to_angle(s ,p)
      update_v(s)
      update_pos(s)
    -- else 
      -- s.attacking = true
    end
  else
    s.behave = idle
  end
    
  
end

function dista(o1, o2)
  local x1 = o1.x or 0
  local y1 = o1.y or 0
  local x2 = o2.x or 0
  local y2 = o2.y or 0
  return dist(x1, y1, x2, y2)

end

function pos_to_angle(o1, o2)
  local x1 = o1.x or 0
  local y1 = o1.y or 0
  local x2 = o2.x or 0
  local y2 = o2.y or 0
  return atan2(x2 - x1, y2 - y1)
end

function update_pos(s)

  local speed = enemy_const.follow_speed
  
  s.x = s.x + s.v.x * delta_time * speed
  s.y = s.y + s.v.y * delta_time * speed

end

function update_v(s)
  local speed = enemy_const.follow_speed
  
  s.v.x = cos(s.angle) * delta_time * speed
  s.v.y = sin(s.angle) * delta_time * speed
end
