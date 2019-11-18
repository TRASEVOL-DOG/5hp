if castle then
  cs = require("https://raw.githubusercontent.com/castle-games/share.lua/master/cs.lua")
else
  cs = require("sharelua/cs")
end


do -- General init and update

  delay = 0
  my_id = nil
  connected = false
  connecting = false
  
  function init_network()
    if IS_SERVER then
      server_init()
    else
      client_init()
    end
  end
  
  local network_t = 0
  function update_network()
    network_t = network_t - dt()
    if network_t > 0 then
      return
    end
    
    if IS_SERVER then
      server_output()
    else
      client_output()
    end
    
    network_t = 0.05
  end
  
end


do -- client

  function client_init()
  
  end

  function client_input(diff)
    my_id = client.id
    
    if client.share[1] then
      local timestamp = client.share[1][client.id]
      if timestamp then
        delay = (t() - timestamp) / 2
        connected = true
        
        delay = min(delay, 0.5)
      else
        return
      end
    else
      return
    end
  
  
    client_sync_players()
    client_sync_bullets()
    client_sync_destructibles()
    client_sync_loot()
    client_sync_enemies()
    
    client_sync_map(diff[7])
    client_sync_gm_values()
    
    if diff[9] and gm_values.gm ~= diff[9] then
      gm_values.gm = client.share[9]
      update_menu_entry("mainmenu", 2, "Mode: <"..gamemode[gm_values.gm].name..">")
      update_menu_entry("gameover", 2, "Mode: <"..gamemode[gm_values.gm].name..">")
      
      new_log("Now playing " .. gamemode[gm_values.gm].name .. "!")
    end
  end
  
  function client_output()
    if connecting then
      client.home[1] = t()
    else
      client.home[1] = nil
    end
    
    local my_player = players[client.id] or players[0]
    if my_player then
      if my_player.dead then
        client.home[2] = nil
        client.home[3] = nil
        client.home[4] = nil
        client.home[5] = nil
        return
      end
      
      client.home[2] = my_player.x
      client.home[3] = my_player.y
      client.home[4] = my_player.dx_input
      client.home[5] = my_player.dy_input
      client.home[6] = my_player.angle
      client.home[8] = my_player.shoot_held
      
      client.home[9] = my_name
    end
    
  end
  
  function client_connect()
    log("Connected to server!")
    
    my_id = client.id
  end
  
  function client_disconnect()
    disconnected = true
    
    log("Disconnected from server!")
  end
  
  
  function client_shoot()
    client.home[7] = (client.home[7] or 0) + 1
  end
  
  function client_next_gamemode()
    client.home[10] = (gm_values.gm or 0) % #gamemode + 1
    
    update_menu_entry("mainmenu", 2, "Mode: <"..gamemode[client.home[10]].name..">")
    update_menu_entry("gameover", 2, "Mode: <"..gamemode[client.home[10]].name..">")
  end
  
  
  function client_sync_players()
    local data = client.share[2]
    if not data then return end
    
    for id, p in pairs(players) do
      if not data[id] then
        kill_player(p)
        forget_player(p)
      end
    end
    
    for id, d in pairs(data) do
      local p = players[id]
      
      if p and p.dead and d[9] >= 10 then
        for i = 1, 16 do
          create_smoke(p.x, p.y, 1, nil, 14, i/16+rnd(0.1))
        end
        
        p.x = d[1]
        p.y = d[2]
      end
      
      if not p then
        log("New player: id #"..id)
        p = create_player(id, d[1], d[2])
      end
      
      if id ~= my_id or p.dead then
        local nx = d[1] + delay * d[3]
        local ny = d[2] + delay * d[4]
        
        p.diff_x = p.diff_x + p.x - nx
        p.diff_y = p.diff_y + p.y - ny
        
        p.x = nx
        p.y = ny
        
        p.vx = d[3]
        p.vy = d[4]
        p.dx_input = d[5]
        p.dy_input = d[6]
        
        p.angle = d[7]
        p.shoot_trigger = d[14]
        p.shoot_hold = d[15]
      end
      
      if not p.weapon or p.weapon.id ~= d[8] then
        p.weapon = create_weapon(d[8])
      end
      --p.weapon.ammo = d[10]
      
      if d[11] and not p.dead then
        kill_player(p, p.dead)
      elseif p.dead and not d[11] then
        resurrect_player(p)
      end
      
      p.hp = d[9]
      p.score = d[12]
      
      
      p.name = d[13]
      
      -- notify_gamemode_new_p(id, p.score)
      -- gm_values.leaderboard = gm_values.leaderboard or {}      
      -- gm_values.leaderboard[id] = {name = p.name or "", score = p.score or 0}
      
    end
  end

  function client_sync_bullets()
    local data = client.share[3]
    if not data then return end
    
    for id, d in pairs(data) do
      local b = bullets[id]
      
      if not b then
        local found
        for bu in group("bullet") do
          if bu.from == d[5] and not bu.id then
            bu.id = id
            bullets[id] = bu
            dead_bullets[id] = nil
            b = bu
            
            found = true
            break
          end
        end
      
        if not found then
          b = create_bullet(d[5], id, d[6], atan2(d[3], d[4]))
          if not b then goto skip_sync end
        end
      end
      
      if vx ~= d[3] or vy ~= d[4] then
        b.vx, b.vy = d[3], d[4]
        b.angle = atan2(b.vx, b.vy)
      end
      
      local nx = d[1] + delay * d[3]
      local ny = d[2] + delay * d[4]
      
      b.diff_x = b.diff_x + b.x - nx
      b.diff_y = b.diff_y + b.y - ny
      
      b.x = nx
      b.y = ny
      
      ::skip_sync::
    end
  end
  
  function client_sync_destructibles()
    local data = client.share[4]
    if not data then return end
    
    for id, d in pairs(data) do
      local s = destructibles[id]
      
      if not s then
        s = create_destructible(id, d[1], d[2])
      end
      
      if s.dead and not d[3] then
        respawn_destructible(s)
      elseif d[3] and not s.dead then
        kill_destructible(s, d[4])
      end
    end
  end
  
  function client_sync_loot()
    local data = client.share[5]
    if not data then return end
    
    for id, s in pairs(loots) do
      if not data[id] then
        deregister_object(s)
        loots[id] = nil
      end
    end
    
    for id, d in pairs(data) do
      if not loots[id] then
        s = create_loot(id, d[3], d[1], d[2])
        s.weapon = d[4]
      end
    end
  end
  
  function client_sync_enemies()
    local data = client.share[6]
    if not data then return end
    
    for id, s in pairs(enemies) do
      if not data[id] then
        kill_enemy(s)
      end
    end
    
    for id, d in pairs(data) do
      local s = enemies[id]
      
      if not s then
        s = create_enemy(id, d[1], d[2])
      end
      
      local nx = d[1] + delay * d[3]
      local ny = d[2] + delay * d[4]
      
      s.diff_x = s.diff_x + s.x - nx
      s.diff_y = s.diff_y + s.y - ny
      
      s.x = nx
      s.y = ny
      s.vx = d[3]
      s.vy = d[4]
      
      s.target = d[5]
      s.hp = d[6]
    end
  end
  
  function client_sync_map(diff)
    if not diff then return end
    
    for y, d_line in pairs(diff) do
      local m_line = map_data[y]
      
      for x, d_v in pairs(d_line) do
        local m_v = m_line[x]
        
        if d_v ~= m_v then
          update_map_wall(x, y, d_v == 2, true)
        end
      end
    end
  end
  
  function client_sync_gm_values()
    if not client.share[8] then return end
    log("here")
    gm_values = client.share[8]
  end
  
end


do -- server
  
  local shot_ids

  function server_init()
    shot_ids = {}
    
    server.share[1] = {}
    server.share[2] = {}
    server.share[3] = {}
    server.share[4] = {}
    server.share[5] = {}
    server.share[6] = {}
    server.share[8] = {}
  end

  function server_input(id, diff)
    local ho = server.homes[id]
    
    if diff[10] then
      if diff[10] ~= gm_values.gm then
        init_gamemode(diff[10])
      end
    end
    
    if not ho[1] then return end
  
    local player = players[id]
    if not player then
      player = create_player(id)
    end
    
    player.x = ho[2] or player.x
    player.y = ho[3] or player.y
    player.dx_input = ho[4] or 0
    player.dy_input = ho[5] or 0
    player.angle = ho[6] or 0
    
    player.shoot_held = ho[8]
    
    if ho[7] and ho[7] > shot_ids[id] then
      player.shoot_trigger = true
      shot_ids[id] = ho[7]
    end
    
    player.name = ho[9] or ""
  end
  
  function server_output()
    for id,ho in pairs(server.homes) do
      server.share[1][id] = ho[1]
    end
    
    server_out_players()
    server_out_bullets()
    server_out_destructibles()
    server_out_loot()
    server_out_enemies()
    
    server.share[7] = map_data
    
    server_out_gm_values()
    
    server.share[9] = gm_values.gm or 0
  end
  
  function server_new_client(id)
    log("New client: #"..id)
    
    shot_ids[id] = 0
  end
  
  function server_lost_client(id)
    log("Client #"..id.." disconnected.")
    
    local p = players[id]
    if p then
      forget_player(p)
    end
  end
  
  
  
  function server_out_players()
    local data_list = server.share[2]
    
    for id, _ in pairs(data_list) do
      if not players[id] then
        data_list[id] = nil
      end
    end
    
    for id, p in pairs(players) do
      data_list[id] = {
        p.x, p.y,
        p.vx,
        p.vy,
        p.dx_input,
        p.dy_input,
        p.angle,
        p.weapon.id,
        p.hp,
        p.weapon.ammo,
        p.dead,
        p.score,
        p.name,
        p.shoot_trigger,
        p.shoot_hold
      }
    end
  end

  function server_out_bullets()
    local data_list = server.share[3]
    
    for id, _ in pairs(data_list) do
      if not bullets[id] then
        data_list[id] = nil
      end
    end
    
    for id, s in pairs(bullets) do
      data_list[id] = {
        s.x, s.y,
        s.vx, s.vy,
        s.from,
        s._type
      }
    end
  end
  
  function server_out_destructibles()
    local data = server.share[4]
    
    for id, s in pairs(destructibles) do
      data[id] = {
        s.x, s.y,
        s.dead,
        s.killer
      }
    end
  end
  
  function server_out_loot()
    local data = server.share[5]
    
    for id, d in pairs(data) do
      if not loots[id] then
        data[id] = nil
      end
    end
    
    for id, s in pairs(loots) do
      data[id] = {
        s.x, s.y,
        s.type,
        s.weapon
      }
    end
  end
  
  function server_out_enemies()
    local data = server.share[6]
    
    for id, d in pairs(data) do
      if not enemies[id] then
        data[id] = nil
      end
    end
    
    for id, s in pairs(enemies) do
      data[id] = {
        s.x,  s.y,
        s.vx, s.vy,
        s.target,
        s.hp
      }
    end
  end
  
  function server_out_gm_values()
    if not gm_values then return end    
    server.share[8] = gm_values    
  end
end


--[[ -- look-up table

  client.home = {
    [1] = timestamp,
    [2] = player_x,
    [3] = player_y,
    [4] = player_dx_input,
    [5] = player_dy_input,
    [6] = player_angle,
    [7] = player_shoot_id,
    [8] = player_shoot_held,
    [9] = player_name,
  }
  
  
  server.share = {
    [1] = {
      [user_id] = timestamp,
      ...
    },
    [2] = { -- player data
      [id] = {
        [1] = x,
        [2] = y,
        [3] = vx,
        [4] = vy,
        [5] = dx_input,
        [6] = dy_input,
        [7] = angle,
        [8] = weapon_type,
        [9] = hp,
        [10] = ammo,
        [11] = dead,
        [12] = score,
        [13] = name,
        [14] = shoot_trigger,
        [15] = shoot_hold
      },
      ...
    },
    [3] = { -- bullet data
      [id] = {
        [1] = x,
        [2] = y,
        [3] = vx,
        [4] = vy,
        [5] = from_player_id,
        [6] = type
      },
      ...
    },
    [4] = { -- destructible data
      [id] = {
        [1] = x,
        [2] = y,
        [3] = dead,
        [4] = killer_bullet
      },
      ...
    },
    [5] = { -- loot data
      [id] = {
        x,
        y,
        type,
        weapon
      },
      ...
    },
    [6] = { -- enemy data
      [id] = {
        [1] = x,
        [2] = y,
        [3] = vx,
        [4] = vy,
        [5] = target,
        [6] = hp
      },
      ...
    },
    [7] = map_data,
    [8] = gm_values
    [9] = current_gamemode
  }
  
--]]


do -- start-up stuff

  function start_client()
    client = cs.client
    
    if castle then
      client.useCastleConfig()
    else
      start_client = function()
        client.enabled = true
        client.start('127.0.0.1:22122') -- IP address ('127.0.0.1' is same computer) and port of server
        
        love.update, love.draw = client.update, client.draw
        client.load()
        
        ROLE = client
      end
    end
    
    client.changed = client_input
    client.connect = client_connect
    client.disconnect = client_disconnect
  end
  
  function start_server(max_clients)
    server = cs.server
    server.maxClients = max_clients
    
    if castle then
      server.useCastleConfig()
    else
      start_server = function()
        server.enabled = true
        server.start('22122') -- Port of server
        
        love.update = server.update
        server.load()
        
        ROLE = server
      end
    end
    
    server.changed = server_input
    server.connect = server_new_client
    server.disconnect = server_lost_client
  end

end