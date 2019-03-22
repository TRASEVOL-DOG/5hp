-- --enemies

-- --enemies are player that have auto behavior and no input check

-- --go to player

enemy_list = {} -- { id : enemy }
local enemy_nextid = 1
              
enemy_const = {
  visible_range = 40,
  follow_range = 80,
  follow_speed = 20,
  hit_time = .05
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
    hp                  = hp or 1,
    behavior            = behavior or "idle",
    
    animt               = 0,
    hit_timer           = 0,
    anim_state          = "idle",
    dead_sfx_player     = false,
    bounce              = false,
    
    w                   = 6,
    h                   = 4,
    
    timer_fire          = 0, -- cooldown (seconds) left for bullet fire
    
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
    end
  end
  
  return s
end

function update_enemy(s)
  -- behave
  s.behave(s)
  
  -- cooldown firing gun
  s.timer_fire = s.timer_fire - delta_time
  if s.hit_timer > 0 then s.hit_timer = s.hit_timer - delta_time end
  
end

function draw_enemy(s)
  if s.hit_timer > 0 then
    rectfill(s.x, s.y , s.x + 8, s.y + 8, 3)  
  else
    rectfill(s.x, s.y , s.x + 8, s.y + 8, 1)  
  end
end

function hit_enemy(s)
  s.hp = s.hp - 1
  s.hit_timer = enemy_const.hit_time
  if s.hp < 1 then kill_enemy(s) end

end

function idle(s)
  if target_found(s) then
    s.behave = moving
  end

end

function target_found(s)
  
  local p_g = get_group_copy("player")
  
  for i, player in pairs(p_g) do
    if player.alive and dista(s, player) < enemy_const.visible_range then
      s.target = player.id
      return true      
    end
  end
  
  return false
  
end

function moving(s)
  local target = player_list[s.target]
  
  if target and dista(s, target) < enemy_const.follow_range then
    debuggg = "found"
    s.angle = find_angle(s, target)
    s.v = angle_to_v(s.angle)
    update_movement_enemy(s)
  else
    debuggg = "goidle"
    go_idle(s)
  end
  
end

function find_angle(s, t)
  return atan2(t.x - s.x, t.y - s.y)
end

function angle_to_v(s)
  return {x = cos(s), y = sin(s)}
end

function go_idle(s)
  s.angle = 0
  s.target = nil
  s.v = {x = 0, y = 0}
  
  s.behave = idle
  
end

function update_movement_enemy(s)

  local speed = enemy_const.follow_speed
    
  -- actual move update
  local nx = s.x + s.v.x * delta_time * speed
  local col = check_mapcol(s,nx)
  if col then
    -- local tx = flr((nx + col.dir_x * s.w * 0.5) / 8)
    -- s.x = tx * 8 + 4 - col.dir_x * (8 + s.w + 0.5) * 0.5
    -- col = check_mapcol(s,nx,nil,true) or col
    -- s.v.y = s.v.y - 1* col.dir_y * delta_time * speed
    -- s.y = s.y - 1* col.dir_y * delta_time * speed * 2
    
    forget_target(s)
  else
    s.x = nx
  end

  local ny = s.y + s.v.y * delta_time * speed
  local col = check_mapcol(s,nil,ny)
  if col then
    -- local ty = flr((ny + col.dir_y * s.h * 0.5) / 8)
    -- s.y = ty * 8 + 4 - col.dir_y * (8 + s.h + 0.5) * 0.5
    
    -- col = check_mapcol(s,nil,ny,true) or col
    -- s.v.x = s.v.x - 1* col.dir_x * delta_time * speed * 2
    -- s.x = s.x - 1* col.dir_x * delta_time * speed * 2
    
    forget_target(s)
  else
    s.y = ny
  end

  
  
  -- s.x = s.x + s.v.x * delta_time * speed
  -- s.y = s.y + s.v.y * delta_time * speed
  collide_with_dest(s, enemy_const.follow_speed)
end

function forget_target(s)
  s.target = nil
  go_idle(s)
end

function collide_with_dest(s, acc)
  local destroyable = collide_objgroup(s,"destroyable")
  if destroyable and destroyable.alive then  -- Remy was here: made this use delta time (and acceleration)
    s.v.x = s.v.x + sgn(s.x - destroyable.x) * acc * 0.5 * delta_time
    s.v.y = s.v.y + sgn(s.y - destroyable.y) * acc * 0.5 * delta_time
  end
end  

function kill_enemy(s)

  if not server_only then
    for i=1,16 do
      create_smoke(s.x, s.y, 0.75, 1+rnd(1.5), pick{1,2,3})
    end
  end
  sfx("get_hit", s.x, s.y) 
  
  enemy_list[s.id] = nil
  deregister_object(s)
  
end

-- function moving(s)  
  
  -- for i, p in pairs(objs["player"]) do 
    -- if distance(s, p) < enemy_const.visible_range then
    -- else
      -- angle = atan2( rnd(5) - 5, rnd(5) - 5)
    -- end
  -- end
  
  -- local add = .05
  -- local pangle = atan2(s.x - s.target.x, s.y - s.target.y)
  
  -- if s.angle - pangle > .5 then
    -- add = add * -1
  -- end
  
  -- s.angle = s.angle + add * delta_time
  
  -- update_movement(s)
-- end

-- function check_fire_at_player(s, player)
  -- if distance(s, p) < enemy_const.visible_range then
    -- for x = 0, (abs(player.x - s.x) / 32) do
      -- for y = 0, (abs(player.y - s.y) / 32) do
        ---- if check_wall(x,y) then abort end
        -- return true
      -- end
    -- end
  -- end
-- end

-- function update_vec(s, delta_time)
    
  -- local acc = player_const.acceleration * delta_time * 10 -- intentionnaly left there
  -- local dec = player_const.deceleration * delta_time * 10 -- ^
  
  -- if server_only then
    -- acc = acc * 1.25
    -- dec = dec * 1.25
  -- else
    -- acc = acc * 0.75
    -- dec = dec * 0.75
  -- end
  
  -- decelerate speed every frame
  -- if s.v.x > dec*1.3 then
    -- s.v.x = s.v.x - dec
  -- elseif s.v.x < - dec * 1.3 then
    -- s.v.x = s.v.x + dec
  -- else
    -- s.v.x = 0
  -- end
  
  -- if s.v.y > dec * 1.3 then
    -- s.v.y = s.v.y - dec
  -- elseif s.v.y < - dec * 1.3 then
    -- s.v.y = s.v.y + dec
  -- else
    -- s.v.y = 0
  -- end
    
  -- accelerate on input
  -- if s.moving then
    -- s.v.x = s.v.x + acc * cos(s.angle)
    -- s.v.y = s.v.y + acc * sin(s.angle)
    
    -- cap_speed(s)
  -- else
    -- s.v.x = 0
    -- s.v.y = 0
  -- end

-- end

-- function cap_speed(s)
  -- s.speed = dist(s.v.x, s.v.y)
  -- local max_speed = player_const.max_speed -- intentionnaly left there
  
  -- if s.speed > max_speed then
    -- s.v.x = s.v.x / s.speed * max_speed
    -- s.v.y = s.v.y / s.speed * max_speed
    -- s.speed = max_speed
  -- end
-- end

-- function apply_v_to_pos(s)
  -- client syncing stuff
  -- local apply_diff = (s.id == my_id and abs(s.dx_input) + abs(s.dy_input) > 0)
  -- if apply_diff then
    -- s.x, s.y = s.x + s.diff_x, s.y + s.diff_y
  -- end
  
  -- actual move update
  -- local nx = s.x + s.v.x * delta_time * 10
  -- local col = check_mapcol(s,nx)
  -- if col then
    -- local tx = flr((nx + col.dir_x * s.w * 0.5) / 8)
    -- s.x = tx * 8 + 4 - col.dir_x * (8 + s.w + 0.5) * 0.5
    
    -- col = check_mapcol(s,nx,nil,true) or col
    -- s.v.y = s.v.y - 1* col.dir_y * s.acceleration * delta_time * 10
    -- s.y = s.y - 1* col.dir_y * delta_time * 20
  -- else
    -- s.x = nx
  -- end
  
  -- local ny = s.y + s.v.y * delta_time * 10
  -- local col = check_mapcol(s,nil,ny)
  -- if col then
    -- local ty = flr((ny + col.dir_y * s.h * 0.5) / 8)
    -- s.y = ty * 8 + 4 - col.dir_y * (8 + s.h + 0.5) * 0.5
    
    -- col = check_mapcol(s,nil,ny,true) or col
    -- s.v.x = s.v.x - 1* col.dir_x * s.acceleration * delta_time * 10
    -- s.x = s.x - 1* col.dir_x * delta_time * 20
  -- else
    -- s.y = ny
  -- end
  
  -- more client syncing bullshit
  -- if apply_diff then
    -- s.x, s.y = s.x - s.diff_x, s.y - s.diff_y
  -- end
-- end
-- function update_movement(s)

  -- if server_only then

    -- MOVEMENT

    -- local delta_time = delta_time
    -- if s.delay then
      -- delta_time = delta_time + 0.5 * delay
    -- end

    -- update_vec(s, delta_time)

  -- else
      -- we need the speed to figure out state on draw_player
    -- s.speed = dist(s.v.x, s.v.y)

  -- end

  -- if not server_only then
    -- s.diff_x = lerp(s.diff_x, 0, 20*delta_time)
    -- s.diff_y = lerp(s.diff_y, 0, 20*delta_time)
  -- end

  -- translate vector to position according to delta (30 fps)
  -- apply_v_to_pos(s)

-- end


function dista( obj1, obj2 )
  local x1 = obj1.x or 0
  local y1 = obj1.y or 0
  local x2 = obj2.x or 0
  local y2 = obj2.y or 0

  return dist(x1 - x2, y1 - y2)
  
end
