
player_list = {}

function create_player(id, x, y)
  -- my_id = 0
  local s = {
    id = id,
    
    x  = x,
    y  = y,
    vx = 0,
    vy = 0,
    w  = 6,
    h  = 7,
    
    weapon = create_weapon("gl"),
    hit_timer = 0,
    angle     = 0,
    
    name  = "",
    hp    = 10,
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
  
  player_list[s.id or 0] = s
  
  if not x then
--    local q = get_spawn()
--    s.x, s.y = q.x, q.y
    s.x, s.y = 64, 64
  end
  
  register_object(s)
  return s
end


function update_player(s)
  s.animt = s.animt + dt()
  
  if s.hit_timer > 0 then
    s.hit_timer = s.hit_timer - dt()
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
  
  update_weapon(s)

  
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
  
  s.faceleft = (s.angle-0.25)%1 < 0.5
end

function draw_player(s)
  local x = s.x + s.diff_x
  local y = s.y + s.diff_y

  palt(6, false)
  palt(1, true)
  
  local flash = s.hit_timer > 0.1
  if flash then
    all_colors_to(14)
  end
  
  local spi, dy
  if state == "dead" then
    spi = 142
    dy = -1
  else
    spi = anim_sprite("player", s.state, s.animt)
    dy = -2
  end
  
  -- draw body outline
  spr(spi, x-8, y+dy-8, 2, 2, s.faceleft)
  
  -- draw weapon arm
  aspr(s.weapon.arm_sprite, x, y-1.5, s.angle, 1, 1, 1/8, 5/8, 1, sgn((s.angle-0.25)%1-0.5))
  
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


function resurrect_player(s)
  s.dead = false
end

function kill_player(s, killer_id)
  s.dead = killer_id or true
  
  s.animt = 0.49
  
  if s.id == my_id then
    add_shake(5)
    sfx("get_hit_player", s.x, s.y)
  else
    sfx("get_hit", s.x, s.y)
  end
end

function forget_player(s)
  deregister_object(s)
  player_list[s.id or -1] = nil
end