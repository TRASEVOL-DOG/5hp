SUGAR_SERVER_MODE = true

require("sugarcoat/sugarcoat")
sugar.utility.using_package(sugar.S, true)

require("nnetwork")
start_server(16)

require("game")

function server.load()
  IS_SERVER = true

  sfx = function() end
  
  init_sugar("Jardins du Standoff", 128, 128, 3)
  set_frame_waiting(50)
  
  _init()
end

function server.update()
  _update()
end