
require("game/systems/object")
require("game/systems/anim")
require("game/systems/menu")

require("game/systems/shader")
require("game/systems/map")
require("game/systems/gamemode")
require("game/systems/log")
require("game/systems/leaderboard")

require("game/objects/player")
require("game/objects/weapons")
require("game/objects/bullets")
require("game/objects/loot")
require("game/objects/destructible")
require("game/objects/enemy")
require("game/objects/fx")
require("game/utility")


c_drk = {[0]=1, 6, 1, 0, 1, 2, 6, 3, 0, 4, 5, 3, 9, 11, 13}
c_lit = {[0]=3, 4, 5, 11, 9, 10, 1, 13, 11, 12, 14, 13, 14, 14, 14}

my_name = ""

function _init()
  init_network()
  
  init_object_mgr(
    "player",
    "enemy",
    "bullet",
    "destructible",
    "loot",
    "particles",
    "wind",
    "water"
  )
  
  if not IS_SERVER then
    cursor = create_cursor()
    cam = create_camera(0, 0)
    
    if castle then
      load_settings()
    else
      select_shader("all")
    end
  else
    init_gamemode(1)
  end  
  
  init_anims(get_anims())
  
  init_map()
  
  init_game()
  
  if not IS_SERVER then
    if castle then
      my_name = castle.user.getMe().username
    else
      my_name = generate_name()
    end
    
    define_menus()
    menu("mainmenu")
  end
  
end

function _update()
  if my_id then
    cam.follow = players[my_id]
  end
  
  wind_maker()
  update_objects()
  
  if (gm_values.gm or 0) ~= 0 then
    update_gamemode() 
  else
    -- gm_values.init_gm = true
  end
  
  if not gm_values.GAME_OVER then 
  else
    if cursor then cursor:update() end
    for o in group("particles") do
      o:update()
    end
  end
  
  grow_walls()
  enemy_spawner()
  loot_spawner()
  player_respawner()
  
  
  if not IS_SERVER and get_menu() == "mainmenu" then
    if btn("r") then
      my_name = generate_name()
    end
  end
  
  update_menu()
  update_log()
  
  update_network()  
  
end

function _draw()
  update_shader()

  cls(10)
  camera()
  
  draw_map()
  
  palt(0,false)
  palt(6,true)
  
  apply_camera()
  
  draw_objects(0, 3)
  
  camera()
  draw_map_top()
  apply_camera()
  
  draw_objects(4)
    
  camera()
  
  draw_hp_ammo()
  draw_respawn()
  
  draw_gamemode_infos() -- leaderboard, name of game mode, whatever we think of next
  
  draw_log()
  draw_menu()
  
  if get_menu() == "mainmenu" then
    draw_title()
  end
  
  cursor:draw()
end



function init_game()

--  cam.follow = create_player(0, 64, 64)
end


do -- ui stuff
  local hp_disp = 0
  function draw_hp_ammo()
    if not my_id or not players[my_id] then return end
    
    palt(1, true)
    palt(6, false)
    palt(0, false)
    
    local p = players[my_id]
    
    -- hp bar
    
    local flash = p.hit_timer > 0.1
    if flash then
      all_colors_to()
    end
    
    if hp_disp > p.hp then
      hp_disp = p.hp
    elseif hp_disp < p.hp then
      hp_disp = min(hp_disp + 10*dt(), p.hp)
    end
    
    local k = flr(hp_disp)/2
    
    local x, y = 2, 2
    for i = 1, max(5, ceil(hp_disp)/2) do
      local sp
      if k < i then
        sp = (k+1 > i) and 388 or 384
      else
        sp = 386
      end
      
      if i > 5 then
        sp = sp + 4
        local n = round(cos(t()*2))
        lighten(12, n)
        lighten(9, n)
        lighten(4, n)
        spr(sp, x, y, 2, 2)
        pal(12, 12)
        pal(9, 9)
        pal(4, 4)
      else
        spr(sp, x, y, 2, 2)
      end
      
      x = x + 16
    end
    
    if flash then
      all_colors_to()
    end
    
    -- ammo
    
    x, y = 2, y + 16
    
    spr(394, x, y, 2, 2)
    
    x = x + 16
    local wep = p.weapon
    if wep then
      local ammo = wep.ammo
      printp(0x0300, 0x3130, 0x3230, 0x0300)
      printp_color(14, 11, 6)
      
      if ammo then
        use_font("big")
        pprint(ammo, x+2, y)
      else
        spr(396, x, y, 2, 2)
      end
      
      x, y = 4, y + 16
      use_font("small")
      pprint(wep.full_name or wep.name, x-2, y-4)
      
      palt(1, false)
      palt(6, true)
    end
  end
  
  function draw_respawn()
    local p = players[my_id]
    if not (p and p.dead and my_respawn) then
      return
    end
    
    printp(0x0300, 0x3130, 0x3230, 0x0300)
    printp_color(14, 11, 6)
    use_font("big")
    
    local y = flr(0.25 * screen_h())
    local str = "Respawn in "..max(ceil(my_respawn), 0).."..."
    pprint(str, (screen_w() - str_px_width(str))/2, y)
  end
  
  function define_menus()
    local function toggle_glow()
      local sel = shader_params()
      if sel == "all" then
        select_shader("no_glow")
        save_setting("glow", false)
      else
        select_shader("all")
        save_setting("glow", true)
      end
      
      cam.glow = 1
    end
    
    local function set_crt(v)
      local _, crt = shader_params()
      
      if v then
        select_shader(nil, v/100 * 0.05, nil)
        save_setting("crt", v/100 * 0.05)
        return v
      end
      
      return crt/0.05 * 100
    end
    
    local function set_scanlines(v)
      local _, _, scan = shader_params()
      
      if v then
        select_shader(nil, nil, v/100 * 0.25)
        save_setting("scanlines", v/100 * 0.25)
        return v
      end
      
      return scan/0.25 * 100
    end
    
    _music_volume = music_volume
    local function music_volume(v)
      if v then
        _music_volume(v/100)
        save_setting("music", v/100)
        return v
      end
      
      return _music_volume()*100
    end
    
    _sfx_volume = sfx_volume
    local function sfx_volume(v)
      if v then
        _sfx_volume(v/100)
        save_setting("sfx", v/100)
        return v
      end
      
      return _sfx_volume()*100
    end
  
    init_menu_system({
      test = {
        { "Hello",      function() log("Hello!") end },
        { "Hi",         function() log("Hi!") end },
        { "Sfx volume", function(v) if v then v = v/100 end return (sfx_volume(v) or 0)*100 end, "slider", 100 },
        { "Text",       function(str) log(str) end, "text_field", 12, "Hello" },
        { "Close",      function() menu() end }
      },
      
      mainmenu = {
        { "Play",      function() menu() connecting = true end },
        { "Mode: <"..gamemode[1].name..">", client_next_gamemode},
        { "Name",      function(str) my_name = str end, "text_field", 12, my_name },
        { "Randomize", function() my_name = generate_name() update_menu_entry("mainmenu", 3, nil, my_name) update_menu_entry("mainmenu_ig", 2, nil, my_name) end },
        { "Settings",  function() menu("settings") end },
        params = { anc_y = 0.7 }
      },
      
      mainmenu_ig = {
        { "Play",      function() menu() connecting = true end },
        { "Name",      function(str) my_name = str end, "text_field", 12, my_name },
        { "Randomize", function() my_name = generate_name() update_menu_entry("mainmenu", 2, nil, my_name) update_menu_entry("mainmenu_ig", 2, nil, my_name) end },
        { "Settings",  function() menu("settings") end }
      },
      
      gameover = {
        { "Ready", function()  end},
        { "Mode: <"..gamemode[1].name..">", client_next_gamemode},
        { "Settings",  function() menu("settings") end }
      },
  
      settings = {
        { "Music Volume", music_volume,  "slider",  100 },
        { "Sfx Volume",   sfx_volume,    "slider",  100 },
        { "Screenshake",  shake_strength, "slider", 200 },
        { "Disable Glow", toggle_glow },
        { "Glow Strength",glow_strength,  "slider", 200 },
        { "CRT curve",    set_crt,        "slider", 200 },
        { "Scanlines",    set_scanlines,  "slider", 200 },
        { "Back",         menu }
      }
    })
  end
  
  function generate_name()
    return pick{"Nice", "Sir", "Sire", "Miss", "Madam", "Ever", "Good", "Dandy", "Green", "Lead", "Gold", "Dirt", "Dust", "Joli", "Rouge", "Belle", "Beau", "Haut", "Grand", "Riche"} .." ".. pick{"Sir", "Madam", "Dandy", "Green", "Jewel", "Trip", "Gun", "Lead", "Tree", "Guns", "Shot", "Fate", "Play", "Branch", "Grass", "Sprout", "Seeds", "Leaf", "Mark", "Groom", "Bloom", "Gems", "Crown", "Roses", "Tulip", "Acorn", "Fruit", "Plant", "Flower"}
  end
  
  function draw_title()
    local scrnw, scrnh = screen_size()
    local c0,c1,c2 = 14, 9, 6
    
    printp(0x0300, 0x3130, 0x3230, 0x0300)
    printp_color(c0, c1, c2)
    
    use_font("big")
    if scrnw > 215 then
      local str = "Trasevol_Dog and Eliott present "
      pprint(str, scrnw/2 - str_px_width(str)/2, -1)
    else
      local str = "Trasevol_Dog and Eliott "
      pprint(str, scrnw/2 - str_px_width(str)/2, -1)
      local str = "present "
      pprint(str, scrnw/2 - str_px_width(str)/2, 13)
    end
    
    spritesheet("title")
    
    local x = 0.5 * scrnw - 9 * 9
    local y = 0.25 * scrnh - 14
    
    for i = 0, 9 do
      local s = (i*2)%16 + flr(i*2/16)*32
      local v = t() * 0.25 + i * 0.1
      
      local dy = 2*(4+3*sin(t()*0.13+i*0.13))*cos(v)
      local yy = y + dy
      local a = 0.03*cos(v+0.25)
      
      pal(14, 6)
      aspr(s, x, yy-1, a, 2, 2)
      aspr(s, x-1, yy, a, 2, 2)
      aspr(s, x+1, yy, a, 2, 2)
      aspr(s, x-1, yy+1, a, 2, 2)
      aspr(s, x+1, yy+1, a, 2, 2)
      aspr(s, x, yy+2, a, 2, 2)

      pal(14,10)
      aspr(s, x, yy+1, a, 2, 2)
      pal(14,14)
      aspr(s, x, yy, a, 2, 2)
      
      x = x + 18
    end
    
    local x = 0.5 * scrnw - 7 * 9
    local y = 0.25 * scrnh + 14
    
    for i = 0,7 do
      local s = 64+ (i*2)%16 + flr(i*2/16)*32
      local v = t()*0.25+(i+0.5)*0.1
      
      local dy = 2*(4+3*sin(t()*0.13+i*0.13))*cos(v)
      local yy = y + dy
      local a = 0.03*cos(v+0.25)
      
      pal(14, 6)
      
      aspr(s, x, yy-1, a, 2, 2)
      aspr(s, x-1, yy, a, 2, 2)
      aspr(s, x+1, yy, a, 2, 2)
      aspr(s, x-1, yy+1, a, 2, 2)
      aspr(s, x+1, yy+1, a, 2, 2)
      aspr(s, x, yy+2, a, 2, 2)
      
      pal(14,10)
      aspr(s, x, yy+1, a, 2, 2)
      pal(14,14)
      aspr(s, x, yy, a, 2, 2)
      
      x = x + 18
    end
    
    pal(14, 14)
    
    spritesheet("sprites")
    
    str = "@Trasevol_Dog"
    pprint(str, scrnw - str_px_width(str) - 4, scrnh-32)
    str = "@Eliott_MacR"
    pprint(str, scrnw - str_px_width(str) - 4, scrnh-16)
  end
end

do -- cursor

  function update_cursor(s)
    s.animt = max(s.animt - dt()*30, 0)
    
    local x, y = btnv("mouse_x"), btnv("mouse_y") 
    s.x = x + cam.x
    s.y = y + cam.y
    
    if btnp("mouse_lb") then
      s.animt = 5
    end
  end
  
  function draw_cursor(s)
    local sp = 256+ceil(s.animt)*2
    local camx, camy = get_camera_pos()
    --local x, y = ceil(s.x-camx), ceil(s.y-camy)
    local x, y = s.x-camx, s.y-camy
    
    palt(6, false)
    palt(1, true)
  
    spr(sp, x-16, y-16, 2, 2)
    spr(sp, x, y-16, 2, 2, true, false)
    spr(sp, x-16, y, 2, 2, false, true)
    spr(sp, x, y, 2, 2, true, true)
    
    palt(1, false)
  end
  
  function create_cursor()
    local s = {
      x      = 0,
      y      = 0,
      animt  = 0,
      update = update_cursor,
      draw   = draw_cursor,
      regs   = {"to_update"}
    }

    register_object(s)
    
    return s
  end

end

do -- camera

  function apply_camera()
    local shk = cam.shkp/100
    camera(round(cam.x+cam.shkx*shk), round(cam.y+cam.shky*shk))
  end
  
  function get_camera_pos()
    local shk = cam.shkp/100
    return round(cam.x+cam.shkx*shk), round(cam.y+cam.shky*shk)
  end
  
  function add_shake(powr)
    if IS_SERVER then return end
  
    local powr = powr or 3
    local a = rnd(1)
    cam.shkx = powr*cos(a)
    cam.shky = powr*sin(a)
    
    cam.glow = max(powr/8, cam.glow + powr/32)
  end
  
  function shake_strength(v)
    if v and cam then
      cam.shkp = v
      add_shake(2)
      
      save_setting("shake", v)
      return cam.shkp
    end
    
    return cam.shkp
  end
  
  function update_camera(s)
    s.shkt = s.shkt - dt()
    if s.shkt < 0 then
      if abs(s.shkx)+abs(s.shky) < 0.5 then
        s.shkx, s.shky = 0,0
      else
        s.shkx = s.shkx * (-0.5-rnd(0.2))
        s.shky = s.shky * (-0.5-rnd(0.2))
      end
      
      s.shkt = 1/30
    end
    
    cam.glow = max(lerp(cam.glow, 0, 3*dt()) - 3*dt(), 0)
    
    if s.follow then
      local scrnw, scrnh = screen_size()
      s.x = lerp(s.x, s.follow.x-scrnw/2, dt()*10)
      s.y = lerp(s.y, s.follow.y-scrnh/2, dt()*10)
    end
  end
  
  function create_camera(x, y)
    local s = {
      x      = x or 0,
      y      = y or 0,
      shkx   = 0,
      shky   = 0,
      shkt   = 0,
      shkp   = 100,
      glow   = 0,
      follow = nil,
      update = update_camera,
      regs   = {"to_update"}
    }
    
    register_object(s)
    
    return s
  end

end

do -- settings
  function save_setting(name, v)
    if not castle then return end
    
    network.async(castle.storage.set, nil, name, v)
  end

  function load_settings()
    if not castle then return end

    local glow = castle.storage.get("glow")
    glow = glow or (glow == nil)
    
    local crt = castle.storage.get("crt") or 0.05
    local scanlines = castle.storage.get("scanlines") or 0.25
    select_shader(glow and "all" or "no_glow", crt, scanlines)
    
    glow_strength(castle.storage.get("glow_str") or 100)
    shake_strength(castle.storage.get("shake") or 100)
    
    sfx_volume(castle.storage.get("sfx") or 1)
    music_volume(castle.storage.get("music") or 1)
  end
end

function get_anims()
  return {
    player = {
      idle = {
        dt = 0.1,
        sprites = {128, 130, 132, 134, 136, 138},
        w = 2,
        h = 2
      },
      run = {
        dt = 0.04,
        sprites = {160,162,164,166,168,170,172,174,192,194,196,198,200,202,204,206},
        w = 2,
        h = 2
      },
      hurt = {
        dt = 0.035,
        sprites = {140,140,140,140,140,140,140},
        w = 2,
        h = 2
      }
    },
    
    helldog = {
      idle = {
        dt = 0.04,
        sprites = {292, 294, 296, 294, 292, 290, 288, 290, 292, 294, 296, 294, 292, 290, 288, 290, 292, 294, 296, 294, 292, 290, 288, 290, 292, 294, 296, 294, 292, 290, 288, 290, 292, 294, 296, 294, 292, 290, 288, 290, 292, 294, 296, 294, 292, 290, 288, 290, 292, 294, 296, 294, 292, 290, 288, 290, 292, 294, 296, 294, 292, 290, 288, 290, 292, 294, 296, 294, 292, 290, 288, 290, 292, 294, 296, 294, 292, 290, 288, 290, 292, 294, 296, 294, 292, 290, 288, 290, 
                   292, 294, 296, 294, 292, 290, 288, 290, 292, 294, 296, 294, 292, 290, 288, 290, 292, 294, 296, 294, 292, 290, 288, 290, 292, 294, 296, 294, 292, 290, 288, 290, 292, 294, 296, 294, 292, 290, 288, 290, 292, 294, 296, 294, 292, 290, 288, 290, 292, 294, 296, 294, 292, 290, 288, 290, 292, 294, 296, 294, 292, 290, 288, 290, 292, 294, 296, 294, 292, 290, 288, 290, 292, 294, 296, 294, 292, 290, 288, 290, 292, 294, 296, 294, 292, 290, 288, 290, 
                   292, 294, 296, 294, 292, 290, 288, 290, 292, 294, 296, 294, 292, 290, 288, 290, 292, 294, 296, 294, 292, 290, 288, 290, 292, 294, 296, 294, 292, 290, 288, 290, 292, 294, 296, 294, 292, 290, 288, 290, 292, 294, 296, 294, 292, 290, 288, 290, 292, 294, 296, 294, 292, 290, 288, 290, 292, 294, 296, 294, 292, 290, 288, 290, 292, 294, 296, 294, 292, 290, 288, 290, 292, 294, 296, 294, 292, 290, 288, 290, 292, 294, 296, 294, 292, 290, 288, 290, 
                   298, 298, 300, 300, 300, 300, 300, 300, 300, 300, 300, 300, 300, 300, 300, 300, 302, 302, 302},
        w = 2,
        h = 2
      },
      run = {
        dt = 0.06,
        sprites = {324, 326, 328, 330, 332, 334, 320, 322},
        w = 2,
        h = 2
      },
      hurt = {
        dt = 0.035,
        sprites = {352, 352, 352, 352, 352, 352, 352},
        w = 2,
        h = 2
      },
      attack = {
        dt = 1.3/28,
        sprites = {328, 228, 228, 228, 228, 228, 228,228, 228, 228, 228, 228, 228, 228},
        w = 2,
        h = 2
      },
      bush = {
        dt = 0.15,
        sprites = {354, 356, 358},
        w = 2,
        h = 2
      }
    },
    
    wind = {
      a = {
        dt = 0.06,
        sprites = {64,65,66,67,68,69,70,71,72,73,74,75,76,78}
      },
      b = {
        dt = 0.06,
        sprites = {80,81,82,83,84,85,86,87,88,89}
      },
      c = {
        dt = 0.06,
        sprites = {96,97,98,99,100,101,102,103,104,105}
      }
    },
    
    shine = {
      a = {
        dt = 0.03,
        sprites = {90,91,92,93,94}
      },
      b = {
        dt = 0.03,
        sprites = {106,107,108,109,110}
      }
    }
  }
end