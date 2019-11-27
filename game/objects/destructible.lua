
destructibles = {}
local nextid  = 1

flower_color = {12, 8, 13, 8, 13, 12}
flower_skin  = {420, 422, 424, 426, 428, 430}

function create_destructible(id, x, y)
  local s = {
    x        = x,
    y        = y,
    w        = 6,
    h        = 6,
    dead     = false,
    respawn  = 0,
    white    = 0,
    style    = irnd(6)+1,
    faceleft = chance(50),
    
    update = update_destructible,
    draw   = draw_destructible,
    regs   = {"to_update", "to_draw0", "destructible"}
  }
  
  if id then
    if destructibles[id] then
      deregister_object(desctuctibles[id])
    end
    
    s.id = id
    nextid = max(nextid, id) + 1
  else
    s.id = nextid
    nextid = nextid + 1
  end
  
  destructibles[s.id] = s
  
  register_object(s)
  return s
end

function update_destructible(s)
  if IS_SERVER and s.dead then
    s.respawn = s.respawn - dt()
    if s.respawn <= 0 then
      respawn_destructible(s)
    end
  end
  
  if s.white > 0 then
    s.white = s.white - dt()
  end
end

function draw_destructible(s)
  palt(1, true)
  palt(6, false)
  
  if s.white > 0 then
    all_colors_to(14)
    spr(flower_skin[s.style], s.x-8, s.y-10, 2, 2, s.faceleft)
    all_colors_to()
  elseif s.dead then
    spr(s.dead_skin, s.x-8, s.y-10, 2, 2, s.faceleft)
  else
    spr(flower_skin[s.style], s.x-8, s.y-10, 2, 2, s.faceleft)
  end
  
  palt(1, false)
  palt(6, true)
end

function respawn_destructible(s)
  if not s.dead then return end
  
  s.dead   = false
  s.killer = nil
  s.style  = irnd(6)+1
  s.white  = 0.1
end

function kill_destructible(s, bullet_id)
  if s.dead then return end
  
  sfx("cactus_hit", s.x, s.y, 0.9+rnd(0.2))
  s.white = 0.05
  s.dead_skin = 416 + irnd(2)*2
  
  s.dead = true
  s.respawn = 10 + rnd(5)
  s.killer = bullet_id
  
  local c = flower_color[s.style]
  local k = 5+irnd(3)
  for i = 1, k do
    create_leaf(s.x, s.y, c, c_drk[c])
  end
  
  if bullet_id then
    local b = bullets[bullet_id]
    if b then
      kill_bullet(b)
    end
  end
end


function init_destructibles(spawns)
  for _, o in pairs(destructibles) do
    deregister_object(o)
  end
  destructibles = {}
  
  if IS_SERVER then
    server.share[4] = {}
  end

  for _, p in pairs(spawns) do
    if chance(90) then
      create_destructible(nil, p.x+irnd(3)-1, p.y+irnd(3)-2)
    end
  end
end
