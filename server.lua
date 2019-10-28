SUGAR_SERVER_MODE = true and not LOAD_MAP_FROM_PNG

require("sugarcoat/sugarcoat")
sugar.utility.using_package(sugar.S, true)

require("game/systems/nnetwork")
start_server(8)

require("game/game")

function server.load()
  IS_SERVER = true

  sfx = function() end
  music = function() end
  
  init_sugar("Jardins du Standoff", 128, 128, 3)
--  set_frame_waiting(50)
  
  _init()
end

function server.update()
  if ROLE then server.preupdate(dt()) end

  _update()
  
  if ROLE then server.postupdate(dt()) end
end