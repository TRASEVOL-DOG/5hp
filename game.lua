-- 1hp source files
-- by TRASEVOL_DOG (https://trasevol.dog/)

require("drawing")
require("maths")
require("table")
require("object")
require("sprite")
require("audio")

--require("nnetwork")

require("menu")

require("fx")

require("map")
require("player")
require("enemy")
require("destroyable")
require("loot")
require("bullet")
require("wind")
require("leaderboard")

score = 0
show_connection_status = false
crowned_player = nil

function _init()
  eventpump()
  
  init_network()
  
  init_menu_system()
  
  init_object_mgr(
    "player",
    "enemy",
    "bullet",
    "destroyable",
    "loot",
    "wind"
  )

  t = 0
  
  if not server_only then
    cursor = create_cursor()
    cam = create_camera(256,256)
  end
  
  init_map()
  
  init_game()
  
  if not server_only then
    main_menu()
  end
  if server_only then
    init_loot_spawns()
    init_enemy_spawns()
  end
end

wind_timer = 0
function _update(dt)

  wind_timer = wind_timer - delta_time
  if wind_timer < 0 then
    sfx(pick({"wind_a","wind_b","wind_c","wind_d","wind_e"}), nil, nil, 0.7+rnd(0.4), 5+rnd(10))
    wind_timer = 1.5+rnd(1)
  end

--  if btnp(6) then
--    refresh_spritesheets()
--  end
  
  if btnp(5) then
    debug_mode = not debug_mode
  end

  t = t + dt
  
  if not server_only and chance(10) then
    if chance(0.2) then windgoright = not windgoright end
    create_wind()
  end

  update_objects()
  grow_walls()
  
  update_leaderboard()
  
  if btnp(12) then show_connection_status = not show_connection_status end
  
  local curmenu = querry_menu()
  if btnp(7) or btnp(8) then
    if not curmenu then
      pause_menu()
    elseif curmenu == "pause" or curmenu == "settings" then
      menu_back()
      in_pause = false
    end
  end
  
  if btnp(11) and curmenu == "mainmenu" and not menulock then
    my_name = generate_name()
    menus["mainmenu"][2].txt = my_name
  end
  
  update_menu()
  
  update_network()
  
  if server_only then
    check_loot_respawn()
    check_enemy_respawn()
  end
  
end

function _draw()
  cls(10)
  camera()
  draw_map()
  
  palt(0,false)
  palt(6,true)
  
  apply_camera()

  draw_objects(0,3)
  
  camera()
  draw_map_top()
  apply_camera()
  
  for s in group("enemy") do
    draw_enemy_bush(s)
  end
  
  draw_objects(4)
  
  draw_player_names()
  
  draw_crown_indicator()
  
  camera()
  
  draw_hp_ammo()
  
  local menu = querry_menu()
  
  if not menu or menu == "gameover" then
    draw_leaderboard()
  end
  
  if menu == "mainmenu" or not client.connected then
    draw_title()
    draw_connection()
  elseif menu == "gameover" then
    draw_gameover()
  elseif in_pause then
    draw_pause_background()
  end
  
  if show_connection_status then
    draw_connection(true)
  end
  
  draw_menu()
  
  draw_debug()
  
  cursor:draw()
end

function _on_resize()

end



function update_cursor(s)
  s.animt = s.animt + delta_time
  s.sprite_t = max(s.sprite_t - dt30f, 0)
  
  local x, y = mouse_pos() 
  s.x = x + cam.x
  s.y = y + cam.y
  
  if mouse_btnp(0) then
    s.sprite_t = 4
  end
end

function draw_cursor(s)
  local sp = 256+ceil(s.sprite_t)*2
  local camx, camy = get_camera_pos()

  spr(sp, s.x-camx, s.y-camy, 2, 2)
end

function create_cursor()
  local s = {
    animt    = 0,
    sprite_t = 0,
    update   = update_cursor,
    draw     = draw_cursor,
    regs     = {"to_update"}
  }
  
  s.x, s.y = mouse_pos()
  
  register_object(s)
  
  return s
end




function apply_camera()
  local shk = cam.shkp/100
  camera(round(cam.x+cam.shkx*shk), round(cam.y+cam.shky*shk))
end

function get_camera_pos()
  local shk = cam.shkp/100
  return round(cam.x+cam.shkx*shk), round(cam.y+cam.shky*shk)
end

function add_shake(powr)
  if server_only then return end

  local powr = powr or 3
  local a = rnd(1)
  cam.shkx = powr*cos(a)
  cam.shky = powr*sin(a)
end

function update_camera(s)
  s.shkt = s.shkt - delta_time
  if s.shkt < 0 then
    if abs(s.shkx)+abs(s.shky) < 0.5 then
      s.shkx, s.shky = 0,0
    else
      s.shkx = s.shkx * (-0.5-rnd(0.2))
      s.shky = s.shky * (-0.5-rnd(0.2))
    end
    
    s.shkt = 1/30
  end
  
  if s.follow then
    local scrnw, scrnh = screen_size()
    s.x = lerp(s.x, s.follow.x-scrnw/2, delta_time*10)
    s.y = lerp(s.y, s.follow.y-scrnh/2, delta_time*10)
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
    follow = nil,
    update = update_camera,
    regs   = {"to_update"}
  }
  
  register_object(s)
  
  return s
end



function main_menu()
  local scrnw, scrnh = screen_size()
  menu("mainmenu")
end

function draw_title()
  local scrnw, scrnh = screen_size()
  local c0,c1,c2 = 14,9,6
  
  font("big")
  draw_text("Trasevol_Dog and Eliott present", scrnw/2, 8, 1, c0,c1,c2)
  
  spritesheet("title")
  
  local x = 0.5 * scrnw - 9 * 9
  local y = 0.25 * scrnh - 14
  
  for i=0,9 do
    local s = (i*2)%16 + flr(i*2/16)*32
    local v = t*0.25+i*0.1
    
    local dy = 2*(4+3*sin(t*0.13+i*0.13))*cos(v)
    local yy = y + dy
    local a = 0.03*cos(v+0.25)
    
    draw_spr_outline(s, x, yy, 2, 2, 6, a)
    draw_spr_outline(s, x, yy+1, 2, 2, 6, a)
    pal(14,10)
    spr(s, x, yy+1, 2, 2, a)
    pal(14,14)
    spr(s, x, yy, 2, 2, a)
    
    x = x + 18
  end
  
  local x = 0.5 * scrnw - 7 * 9
  local y = 0.25 * scrnh + 14
  
  for i=0,7 do
    local s = 64+ (i*2)%16 + flr(i*2/16)*32
    local v = t*0.25+(i+0.5)*0.1
    
    local dy = 2*(4+3*sin(t*0.13+i*0.13))*cos(v)
    local yy = y + dy
    local a = 0.03*cos(v+0.25)
    
    draw_spr_outline(s, x, yy, 2, 2, 6, a)
    draw_spr_outline(s, x, yy+1, 2, 2, 6, a)
    pal(14,8)
    spr(s, x, yy+1, 2, 2, a)
    pal(14,14)
    spr(s, x, yy, 2, 2, a)
    
    x = x + 18
  end
  
  pal(14,14)
  
  spritesheet("sprites")
  
  draw_text("@Trasevol_Dog", scrnw-2, scrnh-26, 2, c0,c1,c2)
  draw_text("@Eliott_MacR" , scrnw-2, scrnh-10, 2, c0,c1,c2)
end

function pause_menu() -- not an actual pause - access to settings & restart & main menu
  local scrnw, scrnh = screen_size()
  menu("pause")
  in_pause = true
end

function draw_pause_background()
  local scrnw,scrnh=screen_size()
  color(6)
  for i=0,scrnh+scrnw,2 do
    line(i,0,i-scrnh,scrnh)
  end
end

hp_disp = 0
function draw_hp_ammo()
  local my_player = player_list[my_id]
  
  if my_player then
    palt(1, true)
    palt(6, false)
    palt(0, false)
  
    local flash = my_player.hit_timer > 0.1
    if flash then
      all_colors_to(14)
    end
    
    if hp_disp > my_player.hp then
      hp_disp = my_player.hp
    elseif hp_disp < my_player.hp then
      hp_disp = min(hp_disp + delta_time*10, my_player.hp)
    end
    
    local k = flr(hp_disp)/2
    
    local y = 2
    local x = 2
    for i = 1,max(10/2, ceil(hp_disp)/2) do
      local sp
      if k<i then
        if k+1 > i then
          sp = 388
        else
          sp = 384
        end
      else
        sp = 386
      end
      
      if i > 5 then
        sp = sp+4
        local n = round(cos(t*2))
        pal(12,lighter(12,n))
        pal(9 ,lighter(9 ,n))
        pal(4 ,lighter(4 ,n))
        spr(sp, x+8, y+8, 2, 2)
        pal(12,12)
        pal(9 ,9 )
        pal(4 ,4 )
      else
        spr(sp, x+8, y+8, 2, 2)
      end
      
      x = x + 16
    end

    if flash then
      all_colors_to()
    end
    
    y = y + 16
    x = 2
    
    spr(394, x+8, y+8, 2, 2)
    
    x = x + 16
    local wep = my_player.weapon_id
    local ammo = my_player.ammo
    if ammo == 0 then
      spr(396, x+8, y+8, 2, 2)
    else
      font("big")
      draw_text(""..ammo, x+4, y+8, 0, 14, 11, 6)
    end
    
    x = 4
    y = y + 16
    font("small")
    draw_text(weapon_const.names[wep], x, y+2, 0, 14, 11, 6)
    
    palt(1, false)
    palt(6, true)
  end
end

function draw_crown_indicator()
  if my_id then
    if player_list[my_id] then
      local angle = 0
      local scrnw,scrnh=screen_size()
      if crowned_player ~= nil and crowned_player ~= my_id and player_list[crowned_player] then
        angle = atan2(player_list[my_id].x - player_list[crowned_player].x,
        player_list[my_id].y - player_list[crowned_player].y)
        indicate_crown(angle)
      else 
        local c = crown_looted()
        if c then
          angle = atan2(player_list[my_id].x - c.x, player_list[my_id].y - c.y)
          indicate_crown(angle)
        end
      end
    end
  end

end

function crown_looted()
  for i, loot in pairs(loot_list) do
    if loot.loot_type == 0 then return loot end
  end
  return false
end

function indicate_crown(angle)
--  local camx, camy = get_camera_pos()
--  color(13)
--  line(player_list[my_id].x - camx + 10 * cos(angle+.5), player_list[my_id].y - camy + 10 * sin(angle+.5), player_list[my_id].x - camx + 20 * cos(angle+.5), player_list[my_id].y - camy + 20 * sin(angle+.5))

  local player = player_list[my_id]
  if not player then return end

  angle = angle + 0.5
  
  local l = 12 + cos(t)
  local x = player.x + player.diff_x + l*cos(angle)
  local y = player.y + player.diff_y + l*sin(angle)

  palt(6,false)
  palt(1,true)
  
  spr(232, x, y, 1, 1, angle)
--  spr(233, x, y-4+cos(t))
  
  palt(6,true)
  palt(1,false)
end

function game_over()
  menu_back()
  menu_back()
  
  add_shake(8)
    
  sfx("gameover")
  local scrnw, scrnh = screen_size()
  menu("gameover")
  in_pause = false
end

function draw_gameover()
  local scrnw, scrnh = screen_size()
  
  local c0,c1,c2 = 14,8,6
  
  font("big")
  
  local str = "* G A M E   O V E R *"
  local w = str_width(str)
  
  local x = scrnw/2-w/2
  local y = 0.25 * scrnh
  
  for i = 1,#str do
    local st = str:sub(i,i)
    if st ~= ' ' then
      local yy = y + (4+2*sin(t*0.41+i*0.13))*cos(t*0.25+i*0.1)
      draw_text(st, x, yy, 0, c0,c1,c2)
    end
    x = x + str_width(st)
  end
  
  local x = 0.5 * scrnw
  local y = 0.4 * scrnh
  
  local msg =""
  local player = player_list[my_id]
  local last_kill = death_history.last_killer[my_id]
  
  local c0,c1,c2 = 14,8,6
  
  if last_kill and    last_kill.count ~= 1 then
    if last_kill.count == 21 then msg = "st" 
    elseif last_kill.count == 2 or last_kill.count == 22 then msg = "nd" 
    elseif last_kill.count == 3 or last_kill.count == 23 then msg = "rd"
    else msg = last_kill.count + "th" 
    end
    msg = " for the "..last_kill.count.. msg .. " time"
  end
  if player then
    draw_text("You got shot by ".. player.last_killer_name .. msg ..".", x, y-10, 1, c0,c1,c2)
  
    draw_text("Score: "..player.score, x, y+10, 1, c0,c1,c2)
  end
end



function draw_connection(tool_tip)
  font("small")
  
  local scrnw,scrnh = screen_size()
  local x,y = 2, 0.5*scrnh
  
  local c0,c1,c2 = 14,9,6
  
  if client.connected then
    draw_text("Connected!", x, y-4, 0, c0,c1,c2)
    draw_text("Ping: "..client.getPing(), x, y+4, 0, c0,c1,c2)
    if tool_tip then
      draw_text("[Press 'N' to hide]", x, y+14, 0, c0,c1,c2)
    end
  else
    draw_text("Not Connected.", x, y-4, 0, c0,c1,c2)
    if castle and castle.isLoggedIn then
      draw_text("Please wait...", x, y+4, 0, c0,c1,c2)
    else
      draw_text("Please sign into", x, y+6, 0, c0,c1,c2)
      draw_text("Castle to connect", x, y+14, 0, c0,c1,c2)
    end
  end
end

debuggg = ""
function draw_debug()
  if #debuggg == 0 then return end
  
  local scrnw, scrnh = screen_size()
  
  local c0,c1,c2 = 14,9,6
  
  font("small")
  draw_text("debug: "..debuggg, scrnw, scrnh-16, 2, c0,c1,c2)
end

function init_game()

  if server_only then
    for _,p in pairs(flower_spawn_points) do
      if chance(85) then
        create_destroyable(nil, p.x+irnd(3)-2, p.y+irnd(3)-2)
      end
    end
    
    if crown_spawn then
      create_loot(0, 0, crown_spawn.x, crown_spawn.y)
    end
    
    create_loot(2, 2, 512+8, 295+8, 4)
  end
  
end

function define_menus()
  local menus={
    mainmenu={
      {"Play", function() menu_back() connecting = true end},
      {"Player Name", function(str) my_name = str end, "text_field", 11, my_name},
      {"Settings", function() menu("settings") end},
--      {"Join the Castle Discord!", function() love.system.openURL("https://discordapp.com/invite/4C7yEEC") end}
    },
    cancel={
      {"Go Back", function() connecting=false main_menu() end}
    },
    settings={
      {"Fullscreen", fullscreen},
      {"Screenshake", function(v) if cam then cam.shkp = v add_shake(4) return cam.shkp end return 100 end,"slider",200},
      {"Master Volume", master_volume,"slider",100},
      {"Music Volume", music_volume,"slider",100},
      {"Sfx Volume", sfx_volume,"slider",100},
      {"Back", menu_back}
    },
    pause={
      {"Resume", function() menu_back() in_pause = false end},
      {"Restart", function() menu_back() in_pause = false restarting = true end},
      {"Settings", function() menu("settings") end},
      {"Back to Main Menu", function() menu_back() main_menu() in_pause = false end},
    },
    gameover={
      {"Restart", function() menu_back() restarting = true end},
      {"Back to Main Menu", main_menu}
    }
  }
  
  set_menu_linespace("mainmenu", 13)
  set_menu_linespace("settings", 10)
  
  menu_position("mainmenu",0.5,0.7)
  menu_position("gameover",0.5,0.75)
  
  if not (castle or network) then
    add(menus.mainmenu, {"Quit", function() love.event.push("quit") end})
  end
  
  return menus
end

--loot_respawner
lr = { current_index = 1, timers = {} , pos = {}, type = {} }

function init_loot_spawns()
  for i, sp in pairs(weapon_spawn_points) do
    create_loot(nil, 2, sp.x, sp.y, 6 ) --2 + irnd(3))
  end
  for i, sp in pairs(hp_spawn_points) do
    create_loot(nil, 1, sp.x, sp.y)
  end
end

function check_loot_respawn()
  
  if lr.timers[lr.current_index] and lr.pos[lr.current_index] and lr.type[lr.current_index] then
    local t = os.clock()
    local diff = t - lr.timers[lr.current_index]
    if diff > 0 then
      
      create_loot(nil, lr.type[lr.current_index], lr.pos[lr.current_index].x, lr.pos[lr.current_index].y, 2 + irnd(3)) 
      
      local id = lr.current_index
      lr.timers[id] = nil
      lr.pos[id]    = nil
      lr.type[id]   = nil 
      lr.current_index = lr.current_index + 1
    end
  end
end

-----------------------------------

--enemy_respawner

enemy_respawner = { current_index = 1, timers = {}}

function init_enemy_spawns()

  for i = 1, 15 do
  
    local x
    local y
    repeat
      x = irnd(MAP_W)
      y = irnd(MAP_H)
    until(  get_maptile(x,  y  ) == 2 and 
            get_maptile(x-1,y  ) == 2 and 
            get_maptile(x,  y-1) == 2 and 
            get_maptile(x-1,y-1) == 2     )
            
    create_enemy(enemy_nextid, x * 8, y * 8 - 4)
  
  end
  
end

function check_enemy_respawn()
  
  if lr.timers[lr.current_index] then
    local t = os.clock()
    local diff = t - lr.timers[lr.current_index]
    if diff > 0 then
      local x
      local y
      repeat
      x = irnd(MAP_W)
      y = irnd(MAP_H)
      until(  get_maptile(x,  y  ) == 2 and 
              get_maptile(x-1,y  ) == 2 and 
              get_maptile(x,  y-1) == 2 and 
              get_maptile(x-1,y-1) == 2     )
      create_enemy(enemy_nextid, x, y)
      
      local id = lr.current_index
      lr.timers[lr.current_index] = nil
      lr.current_index = lr.current_index + 1
    end
  end
end

--function generate_name() return pick{"Roll","Miss","Skul","Cool","Nice","Cute","Good","Ever","Rain","Dead","Bone","Lazy","Fast","Slow","Shot","Coin","Rage","Flat","Love","Meat","Sexy","Warm","Moon","Fate","Heat","High","Hell","Lead","Gold","Bull","Wolf","Game","Gunn","Play","Cuts","Stab","Kink","King","Funk","Bite","Beat","Evil","Ride","Rude","Star","Sand","Badd","Snek","Hate","Work","Load","Coal","Hard","Soap","Sire","Fire","Fear","Road","Pain","Junk"}.." "..pick{"Boii","Boys","Miss","Cops","Skul","Thug","Cats","Puss","Dogs","Pups","Bird","Cows","Rats","Suns","Bone","Burn","Shot","Gunz","Coin","Rage","Love","Meat","Hero","Hawk","Moon","Fate","Heat","Hell","Lead","Gold","Food","Hand","Limb","Bull","Wolf","Game","Gunn","Cuts","Stab","Kink","King","Toad","Punk","Pack","Digg","Beer","Wind","Bear","Wall","Trip","Fool","Soul","Evil","Star","Sand","Snek","Hats","Work","Load","Coal","Hugz","Joke","Papa","Mama","Mood","Fire","Fear","Cook","Rope","Mark","Pain","Junk"} end

function generate_name() return pick{"Nice", "Sir", "Sire", "Miss", "Madam", "Ever", "Good", "Dandy", "Green", "Lead", "Gold", "Dirt", "Dust", "Joli", "Rouge", "Belle", "Beau", "Haut", "Grand", "Riche"} .." ".. pick{"Sir", "Madam", "Dandy", "Green", "Jewel", "Trip", "Gun", "Lead", "Tree", "Guns", "Shot", "Fate", "Play", "Bush", "Grass", "Sprout", "Seeds", "Leaf", "Mark", "Groom", "Bloom", "Gems", "Crown", "Roses", "Tulip", "Acorn", "Fruit", "Plant"} end

my_name = generate_name()


function chance(a) return rnd(100)<a end
