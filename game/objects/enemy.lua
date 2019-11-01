

enemies = {}
local nextid = 1

function create_enemy(id, x, y)
  local s = {
    x  = x,
    y  = y,
    w  = 6,
    h  = 4,
    vx = 0,
    vy = 0,
    
    hp   = 2,
    hit  = 0,
    
    target = 0,
    clock  = 0,
    damage = 2,
    
    animt    = rnd(10),
    state    = "idle",
    faceleft = chance(50),
    
    update = update_enemy,
    draw   = draw_enemy,
    regs   = {"to_update", "to_draw0", "enemy"},
    
    diff_x = 0,
    diff_y = 0
  }
  
  if id then
    if enemies[id] then
      deregister_object(enemies[id])
    end
  
    s.id = id
    nextid = max(nextid, id) + 1
  else
    s.id = nextid
    nextid = nextid + 1
  end
  
  enemies[s.id] = s
  
  log("New enemy! "..x..";"..y)
  
  register_object(s)
  return s
end

function update_enemy(s)
  s.animt = s.animt + dt()

  if s.hit > 0 then
    s.hit = s.hit - dt()
  end
  
  s.clock = s.clock - dt()
  
  if s.clock < 0 then
    s.clock = 1 + rnd(1)
  
    local player, d = nil, sqr(96)
    for p in group("player") do
      local sqd = sqrdist(p.x - s.x, p.y - s.y)
      if sqd < d and not p.dead then
        player = p
        d = sqd
      end
    end
    
    if player then
      s.target = player.id
    end
  end
  
  -- slow down
  s.vx = lerp(s.vx, 0, 8 * dt())
  s.vy = lerp(s.vy, 0, 8 * dt())
  
  -- cap speed
  local v = sqrdist(s.vx, s.vy)
  if v > sqr(60) then
    v = sqrt(v)
    s.vx = s.vx / v * 40
    s.vy = s.vy / v * 40
  end
  
  -- follow player
  if s.target then
    local p = players[s.target]
    
    if p then
      if collide_objobj(s, p) then
        hit_player(p, s)
        
        s.vx = s.vx * 1.5
        s.vy = s.vy * 1.5
      else
        local a = atan2(p.x - s.x, p.y - s.y)
        s.vx = s.vx + cos(a) * 5
        s.vy = s.vy + sin(a) * 5
      end
    end
  end
  
  -- enemies push each other
  local other = collide_objgroup(s, "enemy")
  if other then
    local a = atan2(other.x - s.x, other.y - s.y)
    local co, si = cos(a), sin(a)
    local acc = 50
    s.vx = s.vx - co * acc * dt()
    s.vy = s.vy - si * acc * dt()
    other.vx = other.vx + co * acc * dt()
    other.vy = other.vy + si * acc * dt()
  end
  
  -- apply movement
  s.x = s.x + s.vx * dt()
  s.y = s.y + s.vy * dt()
  
  s.diff_x = lerp(s.diff_x, 0, dt())
  s.diff_y = lerp(s.diff_y, 0, dt())
  
  -- update animation state
  if s.hit > 0 then
    s.state = "hurt"
  elseif abs(s.vx) + abs(s.vy) > 0.5 then
    s.state    = "run"
    s.faceleft = (s.vx < 0)
    
    if get_maptile(s.x/8, s.y/8) == 2 and s.animt % 0.5 < dt() then
      create_leaf(s.x, s.y)
    end
  else
    s.state = "idle"
  end
end

function draw_enemy(s)
  palt(1, true)
  palt(6, false)
  
  if s.hit > 0 then
    all_colors_to(14)
    draw_anim(s.x, s.y-2, "helldog", s.state, s.animt, s.faceleft)
    all_colors_to()
  else
    draw_anim(s.x, s.y-2, "helldog", s.state, s.animt, s.faceleft)
  end
  
  palt(6, true)
  palt(1, false)
end


function hit_enemy(s, bullet)
  local b = bullets[bullet]
  
  if b then
    s.hp = s.hp - b.damage  
  else
    s.hp = s.hp - 1
  end
  s.hit = 0.2
  
  if s.hp <= 0 then
    kill_enemy(s)
  end
end

function kill_enemy(s)
  if not IS_SERVER then
    for i = 1, 16 do
      create_smoke(s.x, s.y, 0.75, 1+rnd(1.5), pick{11, 8, 3, 0})
    end
  end
  
  sfx("get_hit", s.x, s.y)
  
  enemies[s.id] = nil
  deregister_object(s)
end


local spawn_t = 0
function enemy_spawner()
  if not IS_SERVER then return end

  spawn_t = spawn_t - dt()
  
  if spawn_t < 0 then
    spawn_t = 1 + rnd(2)
  
    if group_size("enemy") >= 8 then
      return
    end
  
    local x, y
    local mw, mh = get_mapsize()
    while not (x and y and get_maptile(x, y) == 2) do
      x = irnd(mw)
      y = irnd(mh)
    end
    
    create_enemy(nil, x*8+4, y*8-2)
  end
end