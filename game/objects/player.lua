
players = {}

function create_player(id, x, y)
  local s = {
    id = id,
    
    x  = x,
    y  = y,
    vx = 0,
    vy = 0,
    w  = 6,
    h  = 7,
    
    weapon = create_weapon("shotgun"),
    hit_timer = 0,
    angle     = 0,
    
    name  = "Someone",
    hp    = 10,
    hit_timer = 2,
    dead  = false,
    animt = 0,
    state = "idle",
    faceleft = chance(50),
    skin  = pick{13, 11, 7, 3, 0},
    
    update = update_player,
    draw   = draw_player,
    regs   = {"to_update", "to_draw0", "player"},
    
    shoot_trigger = false,
    shoot_held    = false,
    dx_input = 0,
    dy_input = 0,
    diff_x   = 0,
    diff_y   = 0
  }

  if not id then
    castle_print("/!\\ Creating a player with no id.")
  end
  -- leaderboard = gm_values.leaderboard or {}
  players[s.id or 0] = s
  
  if IS_SERVER then
    notify_gamemode_new_p(s.id or 0)
  end
  
  if not x then
    local p = get_player_spawn()
    s.x, s.y = p.x, p.y
  end
  
  if not IS_SERVER then
    for i = 1, 16 do
      create_smoke(s.x, s.y, 1, nil, 14, i/16+rnd(0.1))
    end
    
    if s.id == my_id then
      sfx("startplay", s.x, s.y)
    end
  end
  
  register_object(s)
  return s
end


function update_player(s)
  s.animt = s.animt + dt()
  
  if s.hit_timer > 0 then
    s.hit_timer = s.hit_timer - dt()
  end
  
  if s.hp > 10 then
    s.hp = max(s.hp - dt(), 10)
  end
  
  if s.dead then
    update_corpse(s)
    return
  end
  

  -- do input
  
  if s.id == my_id then
    s.dx_input = btnv("right") - btnv("left")
    s.dy_input = btnv("down") - btnv("up")
    s.angle = atan2(cursor.x - s.x, cursor.y - s.y)
  end
  
 
  -- do movement
  
  player_movement(s)
  s.diff_x = lerp(s.diff_x, 0, dt())
  s.diff_y = lerp(s.diff_y, 0, dt())

  
  -- shooty shoot-shoot
  
  if s.id == my_id then
    s.shoot_trigger = btnp("mouse_lb")
    s.shoot_held    = btn("mouse_lb")
    
    if btnp("mouse_lb") then
      client_shoot()
    end
  end
  
    
  if do_shoot(s) then -- determine if weapon should shoot this frame (if player trigger, auto fire, rafale, etc..)
    shoot(s)
  end
  
  s.shoot_trigger = false
  
  -- update state
  
  if abs(s.vx) + abs(s.vy) > 0.2 then
    s.state = "run"
  else
    s.state = "idle"
  end
  
  if s.state == "run" then
    local a,b,c = anim_step("player", "run", s.animt)
    if b and a%8 == 1 then
      sfx("steps", s.x, s.y, 1+rnd(0.2))
    end
  end
  
  s.faceleft = (s.angle-0.25)%1 < 0.5
end

function draw_player(s)
  local x = s.x + s.diff_x
  local y = s.y + s.diff_y

  palt(6, false)
  palt(1, true)
  
  local flash = s.hit_timer > 0.4 or s.hit_timer % 0.2 < 0.1
  if flash then
    all_colors_to(14)
  end
  
  local spi, dy
  if s.dead then
    spi = 142
    dy = -1
  else
    spi = anim_sprite("player", s.state, s.animt)
    dy = -2
  end
  
  -- draw body outline
  spr(spi, x-8, y+dy-8, 2, 2, s.faceleft)
  
  -- draw weapon arm
  if s.weapon then
    aspr(s.weapon.arm_sprite, x, y-1.5, s.angle, 1, 1, 1/8, 5/8, 1, sgn((s.angle-0.25)%1-0.5))
  end
  -- draw body
  palt(6, true)
  spr(spi, x-8, y+dy-8, 2, 2, s.faceleft)

  
  if flash then
    all_colors_to()
  end
  

  palt(1, false)
end



function player_movement(s)
  -- deceleration
  local dec = 450 * dt()
  local speed = dist(s.vx, s.vy)
  if speed > 0 then
    local nspeed = max(speed - dec, 0)
    s.vx = s.vx / speed * nspeed
    s.vy = s.vy / speed * nspeed
  end
  
  -- acceleration
  local acc = 800 * dt()
  s.vx = s.vx + s.dx_input * acc
  s.vy = s.vy + s.dy_input * acc
  
  -- speed capping
  local speed, max_speed = dist(s.vx, s.vy), 70
  if speed > max_speed then
    s.vx = s.vx / speed * max_speed
    s.vy = s.vy / speed * max_speed
  end
  
  -- position prevision
  local nx = s.x + s.vx * dt()
  local ny = s.y + s.vy * dt()
  
  -- collision check
  local col = check_mapcol(s, nx, s.y)
  if col then
    local cx = nx + col.dir_x * s.w/2
    local tx = cx - cx % 8 + 4
    nx = tx - col.dir_x * (4.25 + s.w/2)
    
    s.vy = s.vy - 600 * col.dir_y * dt()
  end
  
  local col = check_mapcol(s, s.x, ny)
  if col then
    local cy = ny + col.dir_y * s.h/2
    local ty = cy - cy % 8 + 4
    ny = ty - col.dir_y * (4.25 + s.h/2)
    
    s.vx = s.vx - 600 * col.dir_x * dt()
  end
  
  -- apply new positions
  s.x = nx
  s.y = ny
end

function update_corpse(s)
  s.diff_x = lerp(s.diff_x, 0, 2*dt())
  s.diff_y = lerp(s.diff_y, 0, 2*dt())

  s.vx = lerp(s.vx, 0, dt())
  s.vy = lerp(s.vy, 0, dt())
  
  local nx = s.x + s.vx * dt()
  local ny = s.y + s.vy * dt()
  
  -- collision check
  local col = check_mapcol(s, nx, s.y)
  if col then
    local cx = nx + col.dir_x * s.w/2
    local tx = cx - cx % 8 + 4
    nx = tx - col.dir_x * (4.25 + s.w/2)
    
    s.vx = -s.vx
  end
  
  local col = check_mapcol(s, s.x, ny)
  if col then
    local cy = ny + col.dir_y * s.h/2
    local ty = cy - cy % 8 + 4
    ny = ty - col.dir_y * (4.25 + s.h/2)
    
    s.vy = -s.vy
  end
  
  -- apply new positions
  s.x = nx
  s.y = ny
end

function hit_player(s, b)
  if s.hit_timer > 0 or s.dead then
    return
  end
  
  -- knockback
  local a = atan2(b.x - s.x, b.y - s.y)
  s.vx = - 70 * cos(a)
  s.vy = - 70 * sin(a)
  
  s.hp = s.hp - b.damage
  s.hit_timer = 0.5
  
  if s.id == "my_id" then
    sfx("get_hit_player", s.x, s.y)
  else
    sfx("get_hit", s.x, s.y)
  end
  
  if s.hp <= 0 then
    kill_player(s, b.from)
  end
end

function heal_player(s)
  s.hp = min(s.hp + 5, 20)
  sfx("heal", s.x, s.y, 1)
end


local player_respawns = {}
function player_respawner()
  if IS_SERVER then
    for id, p in pairs(players) do
      if p.dead then
        player_respawns[id] = (player_respawns[id] or 5) - dt()
        if player_respawns[id] < 0 then
          -- respawn player
          respawn_player(p)
          player_respawns[id] = nil
        end
      end
    end
  else
    local p = players[my_id]
    if p and p.dead then
      my_respawn = (my_respawn or 5) - dt()
    else
      my_respawn = nil
    end
  end
end

function respawn_player(s)
  s.dead = false
  s.hp = 10
  s.hit_timer = 2

  local p = get_player_spawn()
  s.x, s.y = p.x, p.y
  
  s.weapon = create_weapon("gun")
  s.state = "idle"
end

function resurrect_player(s)
  s.dead = false
end

function kill_player(s, killer_id)
  s.dead = killer_id or true
  
  -- killer_id can be nil: if killer is AI
  
  s.vx = s.vx * 5
  s.vy = s.vy * 5
  
  s.animt = 0.49
  
  local k = killer_id and players[killer_id]
  if k and killer_id == my_id and s.id == my_id then
    new_log("You killed yourself!", 8)
  elseif k and killer_id == my_id then
    new_log("You killed "..s.name.."!", 10)
  elseif k and s.id == my_id then
    new_log("You got killed by "..k.name..".", 8)
  elseif k then
    new_log(s.name.." got killed by "..k.name..".", 8)
  elseif s.id == my_id then
    new_log("You died.", 8)
  else
    new_log(s.name.." died.", 11)
  end
  
  if s.id == my_id then
    add_shake(5)
    sfx("get_hit_player", s.x, s.y)
  else
    sfx("get_hit", s.x, s.y)
  end
end

function forget_player(s)
  if not IS_SERVER then
    for i = 1, 16 do
      create_smoke(s.x, s.y, 1, nil, 14, i/16+rnd(0.1))
    end
  end
  
  deregister_object(s)
  
  if SERVER_ONLY then
    notify_gamemode_deleted_p(s.id or 0)
  end
  
  players[s.id or -1] = nil
end
