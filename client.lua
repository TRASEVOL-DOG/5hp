if castle then
  cs = require("https://raw.githubusercontent.com/castle-games/share.lua/master/cs.lua")
else
  cs = require("cs")
end
client = cs.client

if USE_CASTLE_CONFIG then
  client.useCastleConfig()
else
  function start_client()
    client.enabled = true
    client.start('127.0.0.1:22122') -- IP address ('127.0.0.1' is same computer) and port of server
    
    love.update, love.draw = client.update, client.draw
    love.resize, love.textinput, love.keypressed, love.keyreleased, love.mousepressed, love.mousereleased = client.resize, client.textinput, client.keypressed, client.keyreleased, client.mousepressed, client.mousereleased
    
    client.load()
    ROLE = client
  end
end

client.changed = client_input
client.connect = client_connect
client.disconnect = client_disconnect


function client.connect() -- Called on connect from server
    castle_print("Client connected!")
end


-- Client gets all Love events

local client_init = false
function client.load()
  if client_init then
    castle_print("Attempt to 2nd client init?")
    return
  end
  castle_print("Starting client init...")

  init_graphics(300, 200, ". 1HP .")--2,2)
  init_audio()
  init_shader_mgr()
  init_input_mgr()
  font("small")
  pal()

  predraw()
  _init()
  afterdraw()
  
  love.keyboard.setKeyRepeat(true)
  love.keyboard.setTextInput(false)
  
  client_init = true
  castle_print("Client init done!")
end
local client_load_sav = client.load

delta_time = 0
dt30f = 0
function client.update(dt)
--  dt = dt or love.timer.getDelta()
--  if not castle then
--    love.timer.sleep(1/30-dt)
--    dt = 1/30
--  end

  if not client_init then
    castle_print("Client.update being called before client.load...")
--    castle_print("Calling client.load from update.")
    --client.load = client_load_sav
    --network.async(function() client.load() end)
--    client.load()
    return
  end
  
  if ROLE then client.preupdate() end

  delta_time = dt
  dt30f = dt*30
 
  _update(dt)
  update_input_mgr()
  
  if ROLE then client.postupdate() end
  
  love.graphics.setCanvas()
end

function client.draw()
  if not client_init then
    castle_print("no init.")
    return
  end

  predraw()
  _draw()
  afterdraw()
  
  love.graphics.setCanvas()
end


function client.resize(ww,hh)
  local scale = min(flr(ww/graphics.scrn_setw), flr(hh/graphics.scrn_seth))
  local scx, scy = scale, scale
  
  local w, h = ceil(ww/scx), ceil(hh/scy)
  render_canvas = love.graphics.newCanvas(w, h)
  render_canvas:setFilter("nearest","nearest")
  
  graphics.scrn_scalex = scx
  graphics.scrn_scaley = scy
  
  graphics.wind_w = ww
  graphics.wind_h = hh
  graphics.scrn_w = w
  graphics.scrn_h = h
  
  if _on_resize then
    _on_resize()
  end
end

function client.textinput(text)
  menu_textinput(text)
end

function client.keypressed(key)
  input_keypressed(key)
end

function client.keyreleased(key)
  input_keyreleased(key)
end

function client.mousepressed(x,y,k,istouch)
  input_mousepressed(x,y,k,istouch)
end

function client.mousereleased(x,y,k,istouch)
  input_mousereleased(x,y,k,istouch)
end

