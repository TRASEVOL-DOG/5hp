if CASTLE_PREFETCH then
  CASTLE_PREFETCH({
--    "https://raw.githubusercontent.com/castle-games/share.lua/master/cs.lua",
--    "nnetwork.lua",
    "game/game.lua",
    "game/utility.lua",
    "game/systems/anim.lua",
    "game/systems/gamemode.lua",
    "game/systems/map.lua",
    "game/systems/menu.lua",
    "game/systems/nnetwork.lua",
    "game/systems/object.lua",
    "game/systems/utf.lua",
    "game/objects/bullets.lua",
    "game/objects/destructible.lua",
    "game/objects/enemy.lua",
    "game/objects/fx.lua",
    "game/objects/loot.lua",
    "game/objects/player.lua",
    "game/objects/weapons.lua",
    "sugarcoat/sugarcoat.lua",
  })
end

require("sugarcoat/sugarcoat")
local oassert = assert
sugar.utility.using_package(sugar.S, true)
assert = oassert

require("game/systems/nnetwork")
start_client()

require("game/game")


--client = love
function client.load()
  init_sugar("Jardins du Standoff", 300, 200, 3)
  
  screen_resizeable(true, 2, on_resize)

  set_frame_waiting(60)
  
  -- palette is Equpix15
  use_palette({0x523c4e, 0x2a2a3a, 0x3e5442, 0x84545c, 0x38607c, 0x5c7a56, 0x101024, 0xb27e56, 0xd44e52, 0x55a894, 0x80ac40, 0xec8a4b, 0x8bd0ba, 0xffcc68, 0xfff8c0})

  set_background_color(0)
  
  define_controls()
  load_assets()
  
  _init()
end

function client.update()
  if ROLE then client.preupdate(dt()) end
    
  _update()
  
  if ROLE then client.postupdate(dt()) end
end

function client.draw()
  _draw()
end


function load_assets()
  load_font("assets/Miserable.ttf", 16, "small", true)
  load_font("assets/Worthy.ttf", 16, "big", true)
  
  load_png("sprites", "assets/spritesheet.png", nil, true)
  load_png("title", "assets/title.png")
  
  local sfx_list={
    menu_select        = "select.ogg",
    menu_confirm       = "confirm.ogg",
    menu_slider        = "sliderset.ogg",
    tab                = "tab.ogg",
    shoot              = "shoot.ogg",
    enemy_shoot        = "enemy_shoot.ogg",
    cant_shoot         = "cant_shoot.ogg",
    steps              = "step.ogg",
    get_hit            = "get_hit.ogg",
    get_hit_player     = "get_hit_player.ogg",
    gameover           = "gameover.ogg",
    startplay          = "startplay.ogg",
    cactus_hit         = "cactus_hit.ogg",
    bullet_wall_bounce = "bullet_bounce.ogg",
    wind_a             = "wind_a.ogg",
    wind_b             = "wind_b.ogg",
    wind_c             = "wind_c.ogg",
    wind_d             = "wind_d.ogg",
    wind_e             = "wind_e.ogg",
    explosion          = "explosion.ogg",
    hurt               = "hurt.ogg"
  }
  
  for k, f in pairs(sfx_list) do
    load_sfx("assets/sfx/"..f, k, 1)
  end
end

function define_controls()
  register_btn("mouse_x", 0, input_id("mouse_position", "x"))
  register_btn("mouse_y", 0, input_id("mouse_position", "y"))
  register_btn("mouse_lb", 0, input_id("mouse_button", "lb"))
  register_btn("mouse_rb", 0, input_id("mouse_button", "rb"))
                           
  register_btn("left", 0,  {input_id("keyboard", "left"),
                            input_id("keyboard", "a"),
                            input_id("controller_button", "dpleft")})
                            
  register_btn("right", 0, {input_id("keyboard", "right"),
                            input_id("keyboard", "d"),
                            input_id("controller_button", "dpright")})
                            
  register_btn("up", 0,    {input_id("keyboard", "up"),
                            input_id("keyboard", "w"),
                            input_id("controller_button", "dpup")})
                            
  register_btn("down", 0,  {input_id("keyboard", "down"),
                            input_id("keyboard", "s"),
                            input_id("controller_button", "dpdown")})

  
  register_btn("ctrl", 0, {input_id("keyboard", "lctrl"),
                           input_id("keyboard", "rctrl")})
  
  local keyboard_keys = {"backspace", "v"}
  for k in all(keyboard_keys) do
    register_btn(k, 0, input_id("keyboard", k))
  end
end

function on_resize()
  local winw, winh = window_size()
  
  local scale = min(flr(winw/300), flr(winh/200))
  
  screen_resizeable(true, scale, on_resize)
end