

enemies = {}
local nextid = 1

function create_enemy(id, x, y)
  local s = {
    x = x,
    y = y,
    w = 6,
    h = 4,
    
    hp   = 2,
    dead = false,
    hit  = 0,
    
    target = 0,
    clock  = 0,
    
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
  
    local player, d = nil, sqr(64)
    for p in group("players") do
      local sqd = sqrdist(p.x - s.x, p.y - s.y)
      if sqd < d then
        player = p
        d = sqd
      end
    end
    
    if player then
      s.target = player.id
    end
  end
  
  if s.target then
    local p = players[s.target]
    
    if p then
      if collide_objobj(s, p) do
        hit_player(p, s)
        
        s.vx = s.vx * 4
        s.vy = s.vy * 4
      else
        local a = atan2(p.x - s.x, p.y - s.y)
        s.vx = cos(a) * 60
        s.vy = sin(a) * 60
      end
    end
  end
  
  -- update animation state
  if s.hit > 0 then
    s.state = "hurt"
  elseif abs(s.vx) + abs(s.vy) then
    s.state    = "run"
    s.faceleft = (s.vx < 0)
    
    if get_maptile(s.x/8, s.y/8) == 2 and s,animt % 0.5 < dt() then
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
  s.hp  = s.hp - bullet.damage
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