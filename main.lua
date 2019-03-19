-- BLAST FLOCK source files
-- by TRASEVOL_DOG (https://trasevol.dog/)

if CASTLE_PREFETCH then
  CASTLE_PREFETCH({
    'client.lua',
    'server.lua',
    'game.lua',
    'player.lua',
    'bullet.lua',
    'destroyable.lua',
    'wind.lua',
    'leaderboard.lua',
    'audio.lua',
    'drawing.lua',
    'input.lua',
    'shader.lua',
    'maths.lua',
    'sprite.lua',
    'object.lua',
    'ttable.lua',
    'nnetwork.lua',
    'menu.lua',
    'fx.lua',
    'assets/Worthy.ttf',
    'assets/Miserable.ttf',
    'assets/spritesheet.png',
    'assets/title.png',
    "assets/sfx/select.ogg",
    "assets/sfx/confirm.ogg",
    "assets/sfx/sliderset.ogg",
    "assets/sfx/tab.ogg",
    "assets/sfx/shoot.ogg",
    "assets/sfx/enemy_shoot.ogg",
    "assets/sfx/cant_shoot.ogg",
    "assets/sfx/step.ogg",
    "assets/sfx/get_hit.ogg",
    "assets/sfx/get_hit_player.ogg",
    "assets/sfx/gameover.ogg",
    "assets/sfx/startplay.ogg",
    "assets/sfx/cactus_hit.ogg",
    "assets/sfx/bullet_bounce.ogg",
    "assets/sfx/wind_a.ogg",
    "assets/sfx/wind_b.ogg",
    "assets/sfx/wind_c.ogg",
    "assets/sfx/wind_d.ogg",
    "assets/sfx/wind_e.ogg",
    'palswap.shader',
    "https://raw.githubusercontent.com/castle-games/share.lua/master/cs.lua"
  })
end


require("game")
require("drawing")
require("input")
require("sprite")
require("shader")
require("maths")
require("audio")

require("nnetwork")

ROLE = nil
USE_CASTLE_CONFIG = (castle ~= nil)
require("server")
require("client")


if not castle then
  castle_log = {}
  castle_print = function(str)
    add(castle_log, str)
  end
end


if not USE_CASTLE_CONFIG then
  function love.load(args)
    if castle then
      init_graphics(256, 144, ". 1HP .")
      init_audio()
      init_shader_mgr()
      init_input_mgr()
      font("big")
      pal()
      color(23)
    end
  
    if args[1] == "server" then
      start_server()
    elseif args[1] == "client" then
      start_client()
    end
  end

  function love.draw()
    if ROLE then
--      font("big")
--      color(23)
      love.graphics.print("Running server.", 32, 32)
      
      if not castle then
        local y = 48
        local n = #castle_log
        while n > 0 do
          love.graphics.print(castle_log[n], 48, y)
          n = n-1
          y = y+16
        end
      end
    else
      love.graphics.print("Press 1 to launch local server.", 32, 32)
      love.graphics.print("Press 2 to launch local client.", 32, 64)
    end
  end
  
  function love.keyreleased(key)
    if key == '1' then
      love.keyreleased = nil
      start_server()
    elseif key == '2' then
      love.keyreleased = nil
      start_client()
    end
  end
end



--function love.load()
--  castle_print("Starting client init...")
--
--  init_graphics(256, 144, ". 1HP .")
--  init_audio()
--  init_shader_mgr()
--  init_input_mgr()
--  font("small")
--  pal()
--  
--  predraw()
--  _init()
--  afterdraw()
--  
--  love.keyboard.setKeyRepeat(true)
--  love.keyboard.setTextInput(false)
--  
--  client_init = true
--  castle_print("Client init done!")
--end
--
--
--delta_time = 0
--dt30f = 0
--function love.update(dt)
----  if dt > 1/30 then
----    love.timer.sleep(1/30-dt)
----    dt = 1/30
----  end
--
--  delta_time = dt
--  dt30f = dt*30
-- 
--  _update(dt)
--  update_input_mgr()
--end
--
--function love.draw()
--  if not client_init then
--    castle_print("no init.")
--    return
--  end
--
--  predraw()
--  _draw()
--  afterdraw()
--end
--
--
--function love.resize(w,h)
--  render_canvas=love.graphics.newCanvas(w,h)
--  render_canvas:setFilter("nearest","nearest")
--  local scx,scy=screen_scale()
--  
--  graphics.wind_w=w
--  graphics.wind_h=h
--  graphics.scrn_w=flr(w/scy)
--  graphics.scrn_h=flr(h/scx)
--end
--
--function love.textinput(text)
--  menu_textinput(text)
--end
--
--function love.keypressed(key)
--  input_keypressed(key)
--end
--
--function love.keyreleased(key)
--  input_keyreleased(key)
--end
--
--function love.mousepressed(x,y,k,istouch)
--  input_mousepressed(x,y,k,istouch)
--end
--
--function love.mousereleased(x,y,k,istouch)
--  input_mousereleased(x,y,k,istouch)
--end



function step()
  if love.timer then
    love.timer.step()
    dt = love.timer.getDelta()
    if dt < 1/30 then
      love.timer.sleep(1/30 - dt)
    end
    dt=max(dt,1/30)
  end
end

function eventpump() -- here to avoid things bugging out
end


