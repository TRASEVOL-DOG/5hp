-- what can be loot : life pickups, armor, weapon and crown

-- loot has a sprite (x, y, sprite_num) and a function to interact with the player according to the loot (id ?)
loot_list = {}
local loot_nextid = 1

function create_loot(id, type, x, y, weapon_id)
  local s = {
    id           = id or 0,
    update       = update_loot,
    draw         = draw_loot,
    regs         = {"to_update", "to_draw1", "loot"},
    looted_by    = nil,
      
    x            = x or 0,
    y            = y or 0,
    w            = 8,
    h            = 8,
    loot_type    = type or 0, -- 0 for Crown, 1 for Health, 2 for weapon
    weapon_id    = weapon_id or nil, -- only if declared
    t_y          = 0
  }
  
  -- setting id
  
  if id then -- assigned by server
    if loot_list[id] then
      deregister_object(loot_list[id])
    end
  
    s.id = id
    loot_nextid = max(loot_nextid, id + 1)
    
  elseif server_only then -- assigning id now
    s.id = loot_nextid
    loot_nextid = loot_nextid + 1
  end
  
  if s.id then
    loot_list[s.id] = s
  end
  
  register_object(s)
  return s
end

function update_loot(s)

  s.t_y = s.t_y + delta_time
    
  -- if server_only then
    
    local looter = all_collide_objgroup(s,"player")
    
    if(#looter>0) then
      for i=1, #looter do
        if looter[i].alive then
          be_looted_by(s, looter[i])
        end
      end
    end
    
  -- end
end

function draw_loot(s)
  rectfill(s.x, s.y , s.x + s.w, s.y + s.h, 14)  
end

function be_looted_by(s, player)
  --sfx("pick_up", s.x, s.y)
    
  -- 0 for Crown, 1 for Health, 2 for weapon
  
  -- if s.loot_type = 0 then crown_player(player)
  -- elseif s.loot_type = 1 then heal_player(player)
  -- else
  if s.loot_type == 2 then arm_player(s, player) end
  
  if s.loot_type == 0 then crown_player(s, player) end
  
  s.looted_by = player.id  
  -- if crowned_player then
  debuggg = s.id .. "                         "
  -- if server_only then
    deregister_loot(s)
  -- end
end

function crown_player(s, player) 
  -- last_pickup_crown = love.time.getTime()
  crowned_player = player.id
end
-- function heal_player(player) player.hp = player.hp + 5 end

function arm_player(s, player) 
  local weapon = s.weapon_id
  player.weapon_id = weapon
  player.ammo = weapon_const.ammo[weapon]
end

function deregister_loot(s)

  castle_print("did it")
  if loot_list[s.id] then loot_list[s.id] = nil end
  
  deregister_object(s)
end
