
network_t = 0
delay = 0
my_id = nil

connecting = false
restarting = false
connected = false

local shot_id, shot_ids

function init_network()
  if server_only then
    shot_ids = {}
    server.share[2] = {} -- players
    server.share[3] = {} -- bullets
    server.share[4] = {} -- destroyables
    server.share[5] = {} -- loot
    server.share[6] = {} -- crowned player
  else
    shot_id = 0
    client.home[4] = shot_id
  end
end

function update_network()
  network_t = network_t - delta_time
  if network_t > 0 then
    return
  end
  
  if server_only then
    server_output()
  else
    client_output()
  end
  
  network_t = 0.05
end



function client_input(diff)
--  if not (client and client.connected) then
--    return
--  end
  my_id = client.id
  
  if client.share[1] then
    local timestamp = client.share[1][client.id]
    if timestamp then
      delay = (love.timer.getTime() - timestamp) / 2
      connected = true
    elseif restarting then
      restarting = false
      connecting = true
      connected = false
    end
  end
  
  sync_players(client.share[2])
  sync_bullets(client.share[3])
  sync_destroyables(client.share[4])
  sync_loot(client.share[5])
  sync_crowned_data(client.share[6])
  
end

function client_output()
--  if not (client and client.connected) then
--    return
--  end
  
  if restarting then
    client.home[1] = nil
  elseif connecting then
    client.home[1] = love.timer.getTime()
  end
  
  local my_player = player_list[client.id]
  if my_player then
    client.home[2] = my_player.dx_input
    client.home[3] = my_player.dy_input
    
    if abs(my_player.diff_x) > 2 then
      client.home[2] = client.home[2] + mid(my_player.diff_x / 32, -2, 2)
    end
    
    if abs(my_player.diff_y) > 2 then
      client.home[3] = client.home[3] + mid(my_player.diff_y / 32, -2, 2)
    end
    
    --if my_player.shot_input then
    --  shot_id = shot_id + 1
    --  client.home[4] = shot_id
    --  debuggg = "shoot!"
    --end
    
    client.home[5] = my_player.angle
    
    client.home[6] = delay
    
    client.home[7] = my_name
    
    client.home[8] = flr(my_player.x + my_player.diff_x)
    client.home[9] = flr(my_player.y + my_player.diff_y)
    
    client.home[11]= my_player.weapon_id
    client.home[12]= my_player.hp
    client.home[13]= my_player.ammo
    
  end
end

function client_connect()
  castle_print("Connected to server!")
  
  my_id = client.id
end

function client_disconnect()
  castle_print("Disconnected from server!")
end

function client_shoot()
  shot_id = shot_id + 1
  client.home[4] = shot_id
end

function sync_players(player_data)
  if not player_data then return end
  
  for id,p in pairs(player_list) do  -- checking if any player no longer exists
    if not player_data[id] then
      kill_player(p)
      deregister_object(p)
      player_list[p.id] = nil
      if crowned_player == p.id then crowned_player = nil end
    end
  end
  
  for id,p_d in pairs(player_data) do  -- syncing players with server data
    if not player_list[id] then
      castle_print("New player: id="..id)
      -- debuggg = "New player: id="..id
      create_player(id, p_d[1], p_d[2])
    end
    local p = player_list[id]
    
    local x = p_d[1] + delay * p_d[3]
    local y = p_d[2] + delay * p_d[4]
    
    if check_mapcol(p, x, y) then
      x, y = p_d[1], p_d[2]
    end

    if id ~= my_id then
      p.v.x = p_d[3]
      p.v.y = p_d[4]
    end
    
    p.diff_x = p.diff_x + p.x - x
    p.diff_y = p.diff_y + p.y - y
    
    p.x = x
    p.y = y
    
    if p.alive and not p_d[5] then
      kill_player(p, p_d[9])
    elseif not p.alive and p_d[5] then
      resurrect(p)
    end
    
    p.server_death = not p_d[5]
    
    p.angle = p_d[6]
    p.score = p_d[7]
    p.name = p_d[8]
  end
end

function sync_bullets(bullet_data)
  if not bullet_data then return end
  
--  for id,b in pairs(bullet_list) do  -- checking if any bullet no longer exists
--    if not bullet_data[id] then
--      deregister_bullet(b)
--    end
--  end
  
  for id,b_d in pairs(bullet_data) do  -- syncing players with server data
    if not bullet_list[id] then
      create_bullet(b_d[5], id)
    end
    local b = bullet_list[id]
    
    if b then
      b.v.x = b_d[3]
      b.v.y = b_d[4]
      
      local x = b_d[1] + delay*b.v.x
      local y = b_d[2] + delay*b.v.y
      b.diff_x = b.diff_x + b.x - x
      b.diff_y = b.diff_y + b.y - y
      b.x = x
      b.y = y
    end
  end
end

function sync_destroyables(destroyable_data)
  if not destroyable_data then return nil end

  for id,d_d in pairs(destroyable_data) do  -- syncing players with server data
    if not destroyable_list[id] then
      create_destroyable(id, d_d[1], d_d[2])
    end
    local d = destroyable_list[id]
    
    if d.alive and not d_d[3] then
      kill_destroyable(d, d_d[4])
    elseif not d.alive and d_d[3] then
      respawn_destroyable(d)
    end
  end
end

function sync_loot(loot_data)
    -- loot_data[id] = {
      -- l.id,
      -- l.loot_type,
      -- l.x, l.y,
      -- l.looted_by,
      -- l.weapon_id
    -- }
  if not loot_data then return nil end  
  
  for id,p in pairs(loot_list) do  -- checking if any loot no longer exists
    if not loot_data[id] then
      deregister_object(p)
      loot_list[p.id] = nil
    end
  end

  for id,l_d in pairs(loot_data) do  -- syncing loot with server data
    if not loot_list[id] then
      local p = create_loot(id, l_d[2], l_d[3], l_d[4], l_d[6])
      p.looted_by = l_d[5]
    end
    
    local l = loot_list[id]
    
    if l.looted_by then
      if l.loot_type == 0 then crowned_player = l.looted_by end
      deregister_loot(l)
    end
  end
end

function sync_crowned_data(data)
  crowned_player = data
end

function server_input()
--  if not server then
--    return
--  end
  
  for id,ho in pairs(server.homes) do
    if ho[1] then
      local player = player_list[id]
      
      if not player then
        player = create_player(id)
        player.is_new_t = (ho[6] or 0) * 5
      end
      
      player.dx_input = ho[2] or 0
      player.dy_input = ho[3] or 0
      
      if ho[4] then
        --if ho[4] > shot_ids[id] then
        --  castle_print("Player #"..id.." shot! "..ho[4])
        --end
        
        player.shot_input = (ho[4] > shot_ids[id])
      end
      
      shot_ids[id] = ho[4] or 0
      player.angle = ho[5] or 0
      
      player.delay = ho[6] or 0
      
      player.name = ho[7]
      
      if player.is_new_t > 0 then
        player.is_new_t = player.is_new_t - delta_time
      else
        if ho[8] and ho[9] then
          if abs(ho[8]-player.x) > 8 or abs(ho[9]-player.y) > 8 then
            local x, y = ho[8] + player.delay * player.v.x, ho[9] + player.delay * player.v.y
            --local x, y = ho[8], ho[9]
            if not check_mapcol(player,x,y) then
              castle_print("Taking client values for player #"..id.."'s position.")
              player.x, player.y = x, y
            end
          end
        end
      end
      
      player.weapon_id = ho[11] or 1
      player.hp = ho[12] or 1
      player.ammo = ho[13] or 1
      
    else
      forget_player(id)
    end
  end
end

function server_output()
--  if not server then
--    return
--  end
  
  server.share[1] = {} -- timestamps
  for id,ho in pairs(server.homes) do
    server.share[1][id] = ho[1]
  end
  
  
  local player_data = server.share[2]
  for id,_ in pairs(player_data) do
    if not player_list[id] then
      player_data[id] = nil
    end
  end
  
  for id,p in pairs(player_list) do
    player_data[id] = {
      p.x, p.y,
      p.v.x, p.v.y,
      p.alive,
      p.angle,
      p.score,
      p.name,
      p.last_killer_id
    }
  end
  
  local bullet_data = server.share[3]
  for id,_ in pairs(bullet_data) do
    if not bullet_list[id] then
      bullet_data[id] = nil
    end
  end
  
  for id,b in pairs(bullet_list) do
    bullet_data[id] = {
      b.x, b.y,
      b.v.x, b.v.y,
      b.from
    }
  end
  
  local destroyable_data = server.share[4]
  for id,d in pairs(destroyable_list) do
    destroyable_data[id] = {
      d.x, d.y,
      d.alive,
      d.killer
    }
  end
  
  local loot_data = server.share[5]
  
  for id,_ in pairs(loot_data) do
    if not loot_list[id] then
      loot_data[id] = nil
    end
  end
  
  for id,l in pairs(loot_list) do
    loot_data[id] = {
      l.id,
      l.loot_type,
      l.x, l.y,
      l.looted_by,
      l.weapon_id
    }
  end
  
  server.share[6] = crowned_player
  
  
end

function server_new_client(id)
  castle_print("New client: #"..id)
  shot_ids[id] = 0
end

function server_lost_client(id)
  castle_print("Client #"..id.." disconnected.")
  
  forget_player(id)
end

function forget_player(id)
  local player = player_list[id]
  if player then
    kill_player(player)
    deregister_object(player)
    player_list[id] = nil
    server.share[2][id] = nil
    if crowned_player == player.id then crowned_player = nil create_loot(0, 0, player.x, player.y) end
  end
end

-- look-up table


-- client.home = {
--   [1] = timestamp,
--   
--   [2] = player_dx_input,
--   [3] = player_dy_input,
--   [4] = player_shoot_id,
--   [5] = player_angle,
--   
--   [6] = client_delay,
--   [7] = player_name,
--   
--   [8] = local_player_position_x,
--   [9] = local_player_position_y
-- }


-- server.share = {
--   [1] = client_timestamps,
--
--   [2] = { -- player data
--     [player_id] = {
--       [1]  = x,
--       [2]  = y,
--       [3]  = v.x,
--       [4]  = v.y,
--       [5]  = alive,
--       [6]  = angle,
--       [7]  = score,
--       [8]  = name,
--       [9]  = last_killer_id,
--       [10] = crowned,
--       [11] = weapon_type,
--       [12] = hp,
--       [13] = ammo,
--     },
--     ...
--   },
--   [3] = { -- bullet_data
--     [bullet_id] = {
--       [1] = x,
--       [2] = y,
--       [3] = v.x,
--       [4] = v.y,
--       [5] = from_player_id,
--       [6] = type
--     },
--     ...
--   },
--   [4] = { -- destroyable_data
--     [loot_id] = {
--       [1] = x,
--       [2] = y,
--       [3] = alive,
--       [4] = type,
--       [5] = weapon_type
--     },
--     ...
--   },
--   [5] = { -- loot_data
--     [loot_data] = {
--       [1] = x,
--       [2] = y,
--       [3] = type,
--       [4] = looted_by,
--       [5] = killer_id
--     },
--   [6] = { -- crown_data
--       crowned_player,
--     ...
--   }
-- }


-- server.share : server write
-- server.homes : server read -> { [client_id] = client_home, ... }
-- 
-- client.share : client read
-- client.home  : client write
-- 
-- client.connected
-- client.id

