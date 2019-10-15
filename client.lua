if CASTLE_PREFETCH then
  CASTLE_PREFETCH({
--    "https://raw.githubusercontent.com/castle-games/share.lua/master/cs.lua",
--    "nnetwork.lua",
    "game.lua",
    "object.lua",
    "anim.lua",
    "sugarcoat/sugarcoat.lua",
  })
end

require("sugarcoat/sugarcoat")
local oassert = assert
sugar.utility.using_package(sugar.S, true)
assert = oassert

require("nnetwork")
start_client()

require("game")


--client = love
function client.load()
  init_sugar("Jardins du Standoff", 300, 200, 3)
  
  screen_resizeable(true, 2, on_resize)

  set_frame_waiting(30)
  
  use_palette(palettes.equpix15)

  set_background_color(0)
  
  define_controls()
  load_assets()
  
  _init()
end

function client.update()
  _update()
end

function client.draw()
  _draw()
end


function load_assets()
  load_font("assets/Miserable.ttf", 16, "small", true)
  load_font("assets/Worthy.ttf", 16, "big", true)
  
  load_png("sprites", "assets/spritesheet.png")
  load_png("title", "assets/title.png")
end

function define_controls()
  register_btn("mx", 0, input_id("mouse_position", "x"))
  register_btn("my", 0, input_id("mouse_position", "y"))
  register_btn("dmx", 0, input_id("mouse_position", "dx"))
  register_btn("dmy", 0, input_id("mouse_position", "dy"))
  register_btn("mlb", 0, input_id("mouse_button", "lb"))
  register_btn("mrb", 0, input_id("mouse_button", "rb"))
  
  register_btn("scy", 0, input_id("mouse_button", "scroll_y"))
  
  register_btn("ctrl", 0, {input_id("keyboard", "lctrl"),
                           input_id("keyboard", "rctrl")})
  
  local keyboard_keys = {"backspace", "a", "c", "v", "z", "y", "g", "h", "left", "right", "up", "down"}
  for k in all(keyboard_keys) do
    register_btn(k, 0, input_id("keyboard", k))
  end
end

function on_resize()
  local winw, winh = window_size()
  
  local scale = min(flr(winw/300), flr(winh/200))
  
  screen_resizeable(true, scale, on_resize)
end