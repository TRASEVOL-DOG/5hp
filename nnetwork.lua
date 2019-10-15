if castle then
  cs = require("https://raw.githubusercontent.com/castle-games/share.lua/master/cs.lua")
else
  cs = require("cs")
end


do -- General init and update

  network_t = 0
  delay = 0
  my_id = nil
  connected = false
  
  function init_network()
    if IS_SERVER then
  
    else
  
    end
  end
  
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
  
  
    
    
    
  end
  
  function client_output()
    client.home[1] = t()
    
  
    
  end
  
  function client_connect()
    log("Connected to server!")
    
    my_id = client.id
  end
  
  function client_disconnect()
    disconnected = true
    
    log("Disconnected from server!")
  end
  
end


do -- server

  function server_input(id, diff)
    local ho = server.homes[id]
  
    
    
  end
  
  function server_output()
    for id,ho in pairs(server.homes) do
      server.share[1][id] = ho[1]
    
  
    end
  end
  
  function server_new_client(id)
    log("New client: #"..id)
  
  end
  
  function server_lost_client(id)
    log("Client #"..id.." disconnected.")
    
  end

end


do -- look-up table

-- client.home = {
--   [1] = timestamp
-- }


-- server.share = {
--   [1] = {
--     [user_id] = timestamp,
--     ...
--   }
-- }

end


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