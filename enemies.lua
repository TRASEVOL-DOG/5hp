--enemies

-- enemies are player that have auto behavior and no input check

-- go to player

              
function create_enemy(id,x,y)
  
  local s = {
    id                  = id,
    name                = "helldog",
    update              = update_enemy,
    draw                = draw_enemy,
  
    behave              = idle,
    animt               = 0,
    anim_state          = "idle",
    regs                = {"to_update", "to_draw0", "player"},
    alive               = true,
    dead_sfx_player     = false,
    bounce              = false,
    
    w                   = 6,
    h                   = 4,
    
    timer_fire          = 0, -- cooldown (seconds) left for bullet fire
    
    v                   = { x = 0, y = 0 },-- movement vector 
    angle               = 0,
    speed               = 0,
    
    --network stuff
    dx_input            = 0,
    dy_input            = 0,
    shot_input          = false,
    diff_x              = 0,
    diff_y              = 0,
    moved_t             = 0,
    server_death        = false
    --
  }
  
  if not id then
    castle_print("/!\\ Creating an enemy with no id.")
  end
  
  enemy_list[s.id or 0] = s
  
  
  if x and y then
    s.x = x
    s.y = y
  end
  
  register_object(s)
  
  if not server_only then
    for i=1,16 do
      create_smoke(s.x, s.y, 0.75, 1+rnd(1.5), pick{1,2,3})
    end
  end
  
  return s
end

function update(s)
  -- behave
  behave(s)
  
  -- cooldown firing gun
  s.timer_fire = s.timer_fire - delta_times
  
end

function update_movement(s)

  if server_only then

    -- MOVEMENT

    local delta_time = delta_time
    if s.delay then
      delta_time = delta_time + 0.5 * delay
    end

    update_vec(s, delta_time)

  else
      -- we need the speed to figure out state on draw_player
    s.speed = dist(s.v.x, s.v.y)

  end

  if not server_only then
    s.diff_x = lerp(s.diff_x, 0, 20*delta_time)
    s.diff_y = lerp(s.diff_y, 0, 20*delta_time)
  end

  -- translate vector to position according to delta (30 fps)
  apply_v_to_pos(s)

end

function idle(s)
end

function moving(s)  
  
  for i, p in pairs(objs["player"]) do 
    if distance(s, p) < enemy_const.visible_range then
    else
      angle = atan2( rnd(5) - 5, rnd(5) - 5)
    end
  end
  
  local add = .05
  local pangle = atan2(s.x - s.target.x, s.y - s.target.y)
  
  if s.angle - pangle > .5
    add = add * -1
  end
  
  s.angle = s.angle + add * delta_time
  
  update_movement(s)
end

function check_fire_at_player(s, player)
  if distance(s, p) < enemy_const.visible_range then
    for x = 0, (abs(player.x - s.x) / 32) do
      for y = 0, (abs(player.y - s.y) / 32) do
        if check_wall(x,y) then abort end
      end
    end
  end
end

function update_vec(s, delta_time)
    
  local acc = player_const.acceleration * delta_time * 10 -- intentionnaly left there
  local dec = player_const.deceleration * delta_time * 10 -- ^
  
  if server_only then
    acc = acc * 1.25
    dec = dec * 1.25
  else
    acc = acc * 0.75
    dec = dec * 0.75
  end
  
  -- decelerate speed every frame
  if s.v.x > dec*1.3 then
    s.v.x = s.v.x - dec
  elseif s.v.x < - dec * 1.3 then
    s.v.x = s.v.x + dec
  else
    s.v.x = 0
  end
  
  if s.v.y > dec * 1.3 then
    s.v.y = s.v.y - dec
  elseif s.v.y < - dec * 1.3 then
    s.v.y = s.v.y + dec
  else
    s.v.y = 0
  end
    
  -- accelerate on input
  if s.moving then
    s.v.x = s.v.x + acc * cos(s.angle)
    s.v.y = s.v.y + acc * sin(s.angle)
    
    cap_speed(s)
  else
    s.v.x = 0
    s.v.y = 0
  end

end

function cap_speed(s)
  s.speed = dist(s.v.x, s.v.y)
  local max_speed = player_const.max_speed -- intentionnaly left there
  
  if s.speed > max_speed then
    s.v.x = s.v.x / s.speed * max_speed
    s.v.y = s.v.y / s.speed * max_speed
    s.speed = max_speed
  end
end

function apply_v_to_pos(s)
  -- client syncing stuff
  local apply_diff = (s.id == my_id and abs(s.dx_input) + abs(s.dy_input) > 0)
  if apply_diff then
    s.x, s.y = s.x + s.diff_x, s.y + s.diff_y
  end
  
  -- actual move update
  local nx = s.x + s.v.x * delta_time * 10
  local col = check_mapcol(s,nx)
  if col then
    local tx = flr((nx + col.dir_x * s.w * 0.5) / 8)
    s.x = tx * 8 + 4 - col.dir_x * (8 + s.w + 0.5) * 0.5
    
    col = check_mapcol(s,nx,nil,true) or col
    --s.v.y = s.v.y - 1* col.dir_y * s.acceleration * delta_time * 10
    s.y = s.y - 1* col.dir_y * delta_time * 20
  else
    s.x = nx
  end
  
  local ny = s.y + s.v.y * delta_time * 10
  local col = check_mapcol(s,nil,ny)
  if col then
    local ty = flr((ny + col.dir_y * s.h * 0.5) / 8)
    s.y = ty * 8 + 4 - col.dir_y * (8 + s.h + 0.5) * 0.5
    
    col = check_mapcol(s,nil,ny,true) or col
    --s.v.x = s.v.x - 1* col.dir_x * s.acceleration * delta_time * 10
    s.x = s.x - 1* col.dir_x * delta_time * 20
  else
    s.y = ny
  end
  
  -- more client syncing bullshit
  if apply_diff then
    s.x, s.y = s.x - s.diff_x, s.y - s.diff_y
  end
end

function distance( obj1, obj2 )
  local x1 = obj1.x or 0
  local y1 = obj1.y or 0
  local x2 = obj2.x or 0
  local y2 = obj2.y or 0

  return dist(x1 - x2, y1 - y2)
  
end
