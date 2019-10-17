if castle then
  cs = require("https://raw.githubusercontent.com/castle-games/share.lua/master/cs.lua")
else
  cs = require("cs")
end


do -- General init and update

  delay = 0
  my_id = nil
  connected = false
  
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
    
--    client_sync_bullets()
  end
  
  function client_output()
    client.home[1] = t()
    
    local my_player = player_list[client.id] or player_list[0]
    if my_player then
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
  
  
  function client_sync_players()
    local data = client.share[2]
    if not data then return end
    
    for id, p in pairs(player_list) do
      if not data[id] then
        kill_player(p)
        forget_player(p)
      end
    end
    
    for id, d in pairs(data) do
      local p = player_list[id]
      
      if not p then
        log("New player: id #"..id)
        p = create_player(id, d[1], d[2])
      end
      
      if id ~= my_id then
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
      
      if not p.weapon or p.weapon.name ~= d[8] then
        p.weapon = create_weapon(d[8])
      end
      p.weapon.ammo = d[10]
      
      if d[11] and not p.dead then
        kill_player(p, p.dead)
      elseif p.dead and not d[11] then
        resurrect_player(p)
      end
      
      p.hp = d[9]
      p.score = d[12]
      p.name = d[13]
    end
  end

  function client_sync_bullets()
    local data = client.share[3]
    if not data then return end
    
    for id, d in pairs(data) do
      local b = bullets[id]
      
      if not b then
        --b = create_bullet(d[5], id, ????)
      end
      
      
    end
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
  end

  function server_input(id, diff)
    local ho = server.homes[id]
    
    if not ho[1] then return end
  
    local player = player_list[id]
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
--    server_out_bullets()
  end
  
  function server_new_client(id)
    log("New client: #"..id)
    
    shot_ids[id] = 0
  end
  
  function server_lost_client(id)
    log("Client #"..id.." disconnected.")
  end
  
  
  
  function server_out_players()
    local data_list = server.share[2]
    
    for id, _ in pairs(data_list) do
      if not player_list[id] then
        data_list[id] = nil
      end
    end
    
    for id, p in pairs(player_list) do
      data_list[id] = {
        p.x, p.y,
        p.vx,
        p.vy,
        p.dx_input,
        p.dy_input,
        p.angle,
        p.weapon.name,
        p.hp,
        p.ammo,
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
        s.type
      }
    end
    
    
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
      }
    },
    ...
  }
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
  [4] = { -- destroyable data
    [id] = {
      [1] = x,
      [2] = y,
      [3] = alive,?
      [4] = killer ?
    },
    ...
  },
  [5] = { -- loot data
    [id] = {
      x,
      y,
      type,
      ???
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
      [6] = hp,
      [7] = dead,?
    },
    ...
  },
  [7] = map_data,
  [8] = crowned_player_id

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