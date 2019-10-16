
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
  
  local acc = 600 * dt()
  if btn("left")  then s.vx = s.vx - acc end
  if btn("right") then s.vx = s.vx + acc end
  if btn("up")    then s.vy = s.vy - acc end
  if btn("down")  then s.vy = s.vy + acc end
  
  s.x = s.x + s.vx * dt()
  s.y = s.y + s.vy * dt()
  
  s.vx = s.vx * 0.6
  s.vy = s.vy * 0.6
  
  
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
  
  draw_anim(s.x, s.y, "player", s.state, s.animt, s.faceleft)
  
  palt(6, true)
  palt(1, false)
end

