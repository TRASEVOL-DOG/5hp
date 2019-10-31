require("game/objects/weapons")

loots = {}

local weapon_list, weapon_sprites = {}, {}
for k, d in pairs(weapons) do
  if k ~= "gun" then
    add(weapon_list, k)
    weapon_sprites[k] = d.get_attributes().loot_sprite
  end
end

local loot_respawns = {}
function init_loot(weapon_spawns, heal_spawns, crown)
  if not IS_SERVER then return end
  
  for _, p in pairs(weapon_spawns) do
    create_loot(nil, 1, p.x, p.y)
  end
  
  for _, p in pairs(heal_spawns) do
    create_loot(nil, 2, p.x, p.y)
  end
  
  if crown then
    create_loot(nil, 3, crown.x, crown.y)
  end
end

function loot_spawner()
  if not IS_SERVER then return end
  
  local ti = t()
  for i, l in pairs(loot_respawns) do
    if ti > l.t then
      create_loot(nil, l.type, l.x, l.y)
      del_at(loot_respawns, i)
    end
  end
end

local function respawn_loot(s)
  if not IS_SERVER then return end

  add(loot_respawns, {
    x = s.x,
    y = s.y,
    type = s.type,
    t = t() + 8 + rnd(3)
  })
end





local nextid = 1
function create_loot(id, type, x, y)
  local s = {
    x = x,
    y = y,
    w = 8,
    h = 8,
    
    type  = type or 1, -- type is: 1 for weapon, 2 for hp, 3 for crown
    animt = rnd(1),
    
    update = update_loot,
    draw   = draw_loot,
    regs   = {"to_update", "to_draw1", "loot"}
  }
  
  if s.type == 1 then -- weapon
    s.weapon = pick(weapon_list)
  end
  
  if id then
    s.id = id
  else
    s.id = nextid
    nextid = nextid + 1
  end
  
  loots[s.id] = s
  
  register_object(s)
  return s
end

local loot_effect
function update_loot(s)
  s.animt = s.animt + dt()
  
  local col = collide_objgroup(s, "player")
  if col then
    loot_effect[s.type](s, col)
    
    respawn_loot(s)
    deregister_object(s)
    
    if IS_SERVER then
      loots[s.id] = nil
    end
  end
end

function draw_loot(s)
  spr(0xE3, s.x-4, s.y-2)
  
  palt(6, false)
  palt(1, true)
  
  local flash = (s.animt%3 < 0.05)
  if flash then
    all_colors_to(14)
  end

  local a = 0.1 * cos(0.6 * s.animt)
  local y = s.y - 2 + 2 * cos(0.4 * s.animt)
  local w = 1
  local sp = 0x2F
  
  if s.type == 1 then -- weapon
    -- get weapon sprite
    sp = weapon_sprites[s.weapon]
  elseif s.type == 2 then -- health
    sp = 0xE1
    w  = 2
  elseif s.type == 3 then -- crown
    sp = 0xE0
  end
  
  aspr(sp, s.x, y, a, w, 1)
  
  if flash then
    all_colors_to()
  end
  
  palt(6, true)
  palt(1, false)
end


loot_effect = {
  [1] = function(s, p) -- looting weapon
    p.weapon = create_weapon(s.weapon)
  end,
  
  [2] = function(s, p) -- looting hp
    heal_player(p)
  end,
  
  [3] = function(s, p) -- looting crown
  
  end
}
