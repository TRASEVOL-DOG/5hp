if castle then
  cs = require("https://raw.githubusercontent.com/castle-games/share.lua/master/cs.lua")
else
  cs = require("cs")
end
server = cs.server

server.maxClients = 16

if USE_CASTLE_CONFIG then
  server.useCastleConfig()
else
  function start_server()
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




-- Server only gets `.load`, `.update`, `.quit` Love events (also `.lowmemory` and `.threaderror`
-- which are less commonly used)

local server_init
function server.load()
  if server_init then
    castle_print("Attempt to 2nd server init?")
    return
  end
  castle_print("Starting server init...")

  server_only = true
  
  if true or USE_CASTLE_CONFIG then
--    local syss = {"audio", "graphics", "video", "window"}
--    --local syss = {}
--    local syssav = {}
--    for sys in all(syss) do
--      syssav[sys], love[sys] = love[sys], nil
--    end
    
    _init()
    
--    for sys in all(syss) do
--      love[sys] = syssav[sys]
--    end
  else
    if not castle then
      init_graphics(400,300)
      init_audio()
      init_shader_mgr()
      init_input_mgr()
      font("big")
      pal()
    end
    
    predraw()
    _init()
    afterdraw()
    
    love.keyboard.setKeyRepeat(true)
    love.keyboard.setTextInput(false)
  end
  
  
--  server_only = false
  
  server_init = true
  castle_print("Server init done!")
end
local server_load_sav = server.load

delta_time = 0
dt30f = 0
function server.update(dt)
  dt = dt or love.timer.getDelta()
--  if not castle then
--    love.timer.sleep(1/30-dt)
--    dt = 1/30
--  end

  if ROLE then server.preupdate() end

  if not server_init then
    castle_print("Calling server.load from update.")
    server.load = server_load_sav
    server.load()
    return
  end
  
--  castle_print("server update")

--  server_only = true
  delta_time = dt
  dt30f = dt*30
  
--  local syss = {"audio", "graphics", "video", "window"}
--  --local syss = {}
--  local syssav = {}
--  for sys in all(syss) do
--    syssav[sys], love[sys] = love[sys], nil
--  end

  
  --update_game()
  _update(dt)
  
  
--  for sys in all(syss) do
--    love[sys] = syssav[sys]
--  end
  
--  server_only = false
  
  if ROLE then server.postupdate() end
end

