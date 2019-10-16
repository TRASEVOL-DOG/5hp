
player_list = {}

function create_player(id, x, y)
  local s = {
    id = id,
    
    x  = x,
    y  = y,
    vx = 0,
    vy = 0,
    w  = 6,
    h  = 7,
    
    -- weapon = create_weapon("ar"),
    weapon = create_weapon("gun"),
    
    name  = "",
    hp    = 10,
    animt = 0,
    state = "idle",
    faceleft = chance(50),
    skin  = pick{13, 11, 7, 3, 0},
    
    update = update_player,
    draw   = draw_player,
    regs   = {"to_update", "to_draw0", "player"}
  }

  if not id then
    castle_print("/!\\ Creating a player with no id.")
  end
  
  player_list[s.id or 0] = s
  
  if not x then
    local q = get_spawn()
    s.x, s.y = q.x, q.y
  end
  
  register_object(s)
  return s
end


function update_player(s)
  s.animt = s.animt + dt()

  -- do movement
  -- TMP - gotta make better later
  
  s.dx_input = btnv("right") - btnv("left")
  s.dy_input = btnv("down") - btnv("up")
  
  player_movement(s)

  
  
  -- shooty shoot-shoot
  update_weapon(s)
  
  if btnp("mouse_lb") or s.weapon.to_shoot then
    s.weapon.to_shoot = false
    shoot(s)
  end
  
  
  -- update state
  
  if abs(s.vx) + abs(s.vy) > 0.2 then
    s.state = "run"
  else
    s.state = "idle"
  end
  
  if abs(s.vx) > 0 then
    s.faceleft = (s.vx < 0)
  end
end

function draw_player(s)
  palt(6, false)
  palt(1, true)
  
  draw_anim(s.x, s.y-2, "player", s.state, s.animt, s.faceleft)
  
  palt(6, true)
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
