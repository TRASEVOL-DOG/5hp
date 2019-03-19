-- what can be loot : life pickups, armor, weapon and crown

-- loot has a sprite (x, y, sprite_num) and a function to interact with the player according to the loot (id ?)

--[[ 

function create_loot(id, type, x, y, weapon_id)
  local s = {
      id           = id,
      x           = x,
      y           = y,
      w           = w,
      h           = h,
      loot_type   = type, -- 0 for Crown, 1 for Health, 2 for weapon
      weapon_id   = weapon_id or nil, -- only if declared
      t_y         = 0
  }
  
  return s
end

function update_loot(s)
  s.t_y = s.t_y + delta_time
  
  local looter = collide_objgroup(s,"player")
  if looter then be_looted_by(s, looter) end
  
end

function draw_loot(s)
  local y_offs = cos(s.t_y)
  rectfill(s.x, s.y + y_offs, s.x + s.w, s.y + y_offs + s.h, 1)
end

function be_looted_by(s, player)
  --sfx("pick_up", s.x, s.y)
    
  -- 0 for Crown, 1 for Health, 2 for weapon
  
  if s.loot_type = 0 then crown_player(player)
  elseif s.loot_type = 1 then heal_player(player)
  elseif s.loot_type = 2 then cock_player(player, s.weapon_id) end
  
  deregister_loot(s)
end

function crown_player(player) end
function heal_player(player) player.hp = player.hp + 5 end
function cock_player(player, s.weapon_id) end

function deregister_loot(loot)
  deregister_object(s)
  
  -- if s.id then
    -- bullet_list[s.id] = nil
    -- dead_bullets[s.id] = true
  -- end

end

--]] 