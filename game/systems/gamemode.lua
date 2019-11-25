-- Gamemode dictates the start, update and end state of the games

gamemode = {}

gm_values = {}

leaderboard_is_large = true

function init_gamemode(gm)
  log("Initializing game mode: " .. gamemode[gm].name)
  
  -- init_map()
  gm_values = {}
  displayed_g_o = false
  
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
    else
      t_game_over = t_game_over + dt()
      if t_game_over > 3 then
        init_gamemode(gm_values.gm)
      end
    end
  else -- Client
    if btnp("tab") then 
      leaderboard_is_large = not leaderboard_is_large 
      sfx("tab")
    end   
    if gm_values.GAME_OVER then
      if not displayed_g_o then
        displayed_g_o = true
        new_log("The game is over !")
      end
    end
  end
end

function draw_gamemode_infos()

  draw_leaderboard()
 
  use_font("small")
  local str = gm_values.gm and ("Playing "..gamemode[gm_values.gm].name) or ""
  pprint(str, screen_w()/2 - str_px_width(str)/2, 5)
  
  if gamemode == 1 then draw_crown_indicator() end
  
end

function game_over()
  gm_values.GAME_OVER = true
  t_game_over = 0
end

function is_game_over()
  if not gm_values.gm then return end
  return gamemode[gm_values.gm].is_game_over()  
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
      -- (temporary name)
      name = "Keep the Crown",
      
      description = "The Crown's description, and it's holy.",
      
      base_score = 5,
      
      init = function()
        gm_values.leaderboard = {}        
        gm_values.leaderboard_order = "ascending"
        for i, p in pairs(players) do notify_gamemode_new_p(i, 0) end    
      end,
    
      update = function()
        for i, l in pairs(gm_values.leaderboard) do  
          if gm_values.crowned_player == i then
            local p_since_picked = flr((t() - (l.time_picked_crown))*10)/10
            l.score = (l.last_score or gamemode[gm_values.gm].base_score) - p_since_picked
          end
        end
        
        is_game_over()
        
      end,
      
      new_p = function(id_player)
        gm_values.leaderboard[id_player or 0] = { score = gamemode[gm_values.gm].base_score , 
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
      
      is_game_over = function()
        for i, l in pairs(gm_values.leaderboard) do
          if l.score <= 0 then 
            l.score = 0 
            game_over()
          end
        end
      end,
    },
    {    
      -- (temporary name) 
      name = "Deathmatch",
      
      description = "Deathmatch is a match to the death.",
      
      init = function()
        gm_values.leaderboard = {}        
        for i, p in pairs(players) do notify_gamemode_new_p(i, 0) end
      end,
    
      update = function()
        for i, l in pairs(gm_values.leaderboard) do  
          l.score = 5 - flr((t() - l.time_joined)*10)/10
        end
      end,
      
      new_p = function(id_player, score)
        gm_values.leaderboard[id_player or 0] = {score = score or gamemode[gm].base_score, time_joined = t()}      
      end,
      
      deleted_p = function(id_player)
        gm_values.leaderboard[id_player or 0] = nil     
      end,
      
      is_game_over = function()
        for i, l in pairs(gm_values.leaderboard) do
          if l.score <= 0 then 
            l.score = 0 
            game_over()
          end
        end
      end,
  
    }
  }
  ------------
  
end

do -- gamemode ui
  function draw_crown_indicator()
    if my_id then
      if player_list[my_id] then
        local angle = 0
        local scrnw,scrnh = screen_size()
        local crowned_player = gm_values.crowned_player
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

  function indicate_crown(angle)
  
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

end