-- Gamemode dictates the start, update and end state of the games

gamemode = {}

gm_values = {}

leaderboard_is_large = not ON_MOBILE

TIME_DISPLAY_DESC = 2 -- time description will stay on screen after beginning of game
gm_indicator = 0 -- variable counting time desc was on screen

function init_gamemode(gm)
  log("Initializing game mode: " .. gamemode[gm].name)
  gm_values = {}
  
  -- cleanup
    
    -- Keep the Crown
    for i, o in pairs(loots) do
      if o.type == 3 then 
        deregister_object(o) 
        loots[i] = nil 
      end
    end
  
  if IS_SERVER then
    if gm < 1 then return end
    gm_values.gm = gm
    gamemode[gm].init()
  end
end

function update_gamemode()

  if IS_SERVER then
    if not gm_values.GAME_OVER then
      -- log("here")
      if gamemode and gamemode[gm_values.gm] and gamemode[gm_values.gm].update then
        gamemode[gm_values.gm].update()
      end
    end
  else -- Client
    if btnp("tab") then 
      leaderboard_is_large = not leaderboard_is_large 
      sfx("tab")
    end   
  end
end

function draw_gamemode_infos()
  if not gamemode[gm_values.gm] then return end
          
  if start_timer and start_timer <= 0 then
    if gm_indicator < 4 and players[my_id] then
      gm_indicator = gm_indicator + dt()
      print_desc_gm(gamemode[gm_values.gm].description)
    end                     
  end
  
  if not gamemode[gm_values.gm].draw_hud then return end
  gamemode[gm_values.gm].draw_hud()
end

function print_name_gm(name)
  use_font("small")
  local str = gm_values.gm and ("Playing " .. name) or ""
  pprint(str, screen_w()/2 - str_px_width(str)/2, 5)
end

function print_desc_gm(desc)
  use_font("big")
  local str = gm_values.gm and (desc) or ""
  pprint(str, screen_w()/2 - str_px_width(str)/2, screen_h()/4)
end

function game_over()
  gm_values.GAME_OVER = true
  gm_indicator = 0
  start_timer = 60
end

function notify_gamemode_new_p(id_player, score)
  if not id_player or not gm_values.gm then return end
  gamemode[gm_values.gm].new_p(id_player, score)  
end

function notify_gamemode_deleted_p(id_player)
  if not id_player or not gm_values.gm then return end
  gamemode[gm_values.gm].deleted_p(id_player)  
end

do
  
  gamemode = {
    {    
      name = "Keep the Crown",
      
      description = "Keep your head and the crown on it for 50 seconds.",
      
      base_score = 50,
      
      init = function()
        gm_values.leaderboard = {}        
        gm_values.leaderboard_order = "ascending"
        
        for i, o in pairs(loots) do
          if o.type == 3 then 
            deregister_object(o)
            loots[i] = nil
          end
        end
        
        for i, p in pairs(players) do notify_gamemode_new_p(i, 0) end    
        
        spawn_crown()
        
      end,
    
      update = function()
        for i, l in pairs(gm_values.leaderboard) do  
          if gm_values.crowned_player == i then
            local p_since_picked = flr((t() - (l.time_picked_crown))*10)/10
            l.score = (l.last_score or gamemode[gm_values.gm].base_score) - p_since_picked
          end
        end
        
        for i, l in pairs(gm_values.leaderboard) do
          if l.score <= 0 then 
            l.score = 0 
            game_over()
          elseif l.score < 8 then 
            l.score = 8
          end
        end
        
      end,
      
      draw_hud = function ()
      
        if not gm_values.GAME_OVER then
          draw_leaderboard(screen_w()-4, 4, 1, 0)          
          print_name_gm(gamemode[gm_values.gm].name)
          draw_crown_indicator()
        end
      
      end,
      
      new_p = function(id_player, score)
        gm_values.leaderboard[id_player or 0] = { score = score or gamemode[gm_values.gm].base_score , 
                                                  time_picked_crown = nil, 
                                                  last_score = gamemode[gm_values.gm].base_score}
      end,
      
      deleted_p = function(id_player)
        gm_values.leaderboard[id_player or 0] = nil
        
        if gm_values.crowned_player == id_player then
          if IS_SERVER then
            create_loot(nil, 3, players[id_player].x, players[id_player].y)
          end
          gm_values.crowned_player = nil    
        end
        
      end,
      
    },
    -- {    
      -- name = "Big Bad Wolf",
      
      -- description = "Nobody likes that wolf.",
      
      -- special_leaderboard = true,      
      
      -- base_score_wolf = 100,
      
      -- init = function()
      
      -- end,
    
      -- update = function()
      
      -- end,
      
      -- draw_hud = function ()
      
      -- end,
      
      -- new_p = function(id_player)
      
      -- end,
      
      -- deleted_p = function(id_player)
      
      -- end,
      
    -- },
    {    
      name = "Deathmatch",
      
      description = "Kill 10 people. Others won't make it easy.",
      
      max_kills = 10,
      
      init = function()
        gm_values.leaderboard = {}  
        for i, p in pairs(players) do notify_gamemode_new_p(i, 0) end
      end,
    
      update = function()
        for i, l in pairs(gm_values.leaderboard) do
          if l.score >= gamemode[gm_values.gm].max_kills then 
            l.score = gamemode[gm_values.gm].max_kills 
            game_over()
          end
        end
      end,
      
      draw_hud = function ()
      
        if not gm_values.GAME_OVER then
          draw_leaderboard(screen_w()-4, 4, 1, 0)
          print_name_gm(gamemode[gm_values.gm].name)
        end
      
      end,
      
      new_p = function(id_player, score)
        gm_values.leaderboard[id_player or 0] = {score = score or 0}
      end,
      
      deleted_p = function(id_player)
        gm_values.leaderboard[id_player or 0] = nil     
      end,
  
    }
  }
  ------------
  
end

do -- gamemode ui
  function draw_crown_indicator()
    if my_id then
      if players[my_id] then
        local angle = 0
        local crowned_player = gm_values.crowned_player
        apply_camera()
        if crowned_player then 
          if crowned_player ~= my_id and players[crowned_player] then -- not the player
            angle = atan2(players[my_id].x - players[crowned_player].x,
            players[my_id].y - players[crowned_player].y)
            indicate_crown(angle)     
          else
            palt(6,false)
            palt(1,true)
            aspr(233, players[my_id].x - 0.5 - cos(t()), players[my_id].y - 14 + sin(t()), angle, 1, 1)
            palt(6,true)
            palt(1,false)
          end
        elseif crown then -- crown on map
          angle = atan2(players[my_id].x - crown.x, players[my_id].y - crown.y)
          indicate_crown(angle)  
        end
        camera()      
      end
    end
  end

  function indicate_crown(angle)
  
    local player = players[my_id]
    if not player then return end

    angle = angle + 0.5
    local l = 15 + cos(t())    
    local x = players[my_id].x + players[my_id].diff_x + l*cos(angle) - 1
    local y = players[my_id].y + players[my_id].diff_y + l*sin(angle) - 2

    palt(6,false)
    palt(1,true)    
    aspr(232, x, y, angle, 1, 1)
    palt(6,true)
    palt(1,false)
  end
  
end