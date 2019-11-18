-- Gamemode dictates the start, update and end state of the games

gamemode = {}

gm_values = {}

leaderboard_is_large = true

function init_gamemode(gm)
  log("Initializing game mode: " .. gamemode[gm].name)
  
  if IS_SERVER then
    if gm < 1 then return end
    gm_values.gm = gm
    gamemode[gm].init()
  end
end

function client_init_gm()
  gm_values = {}
end

function update_gamemode()

  if IS_SERVER then
    if not gm_values.GAME_OVER then
      if gamemode and gamemode[gm_values.gm] and gamemode[gm_values.gm].update then
        gamemode[gm_values.gm].update()
      end
      gm_values.GAME_OVER = is_game_over()
      t_game_over = 0
    else
      -- decide how game over ends
      
      t_game_over = t_game_over + dt()
      if t_game_over > 3 then
        init_gamemode(gm_values.gm)
        gm_values.GAME_OVER = false
        displayed_g_o = false
      end
      
    end
  else -- Client
    if btnp("tab") then 
      leaderboard_is_large = not leaderboard_is_large 
      sfx("tab")
    end   
    if gm_values.GAME_OVER then
      if not displayed_g_o then
        -- do things
        -- END_OF_GAME = false
        displayed_g_o = true
        new_log("The game is over !")
      end
    else
      -- END_OF_GAME = true
    end
  end
end

function draw_gamemode_infos()

  -- draw the leaderboard
  draw_leaderboard()
  
  -- write the game mode name
  use_font("small")
  local str = gm_values.gm and ("Playing "..gamemode[gm_values.gm].name) or ""
  pprint(str, screen_w()/2 - str_px_width(str)/2, 5)
  
  if gamemode == 1 then draw_crown_indicator() end
  
end

function game_over(sorted_lb)
  gm_values = {}
end

function is_game_over()
  if SERVER_ONLY and not id_player and not gm_values.gm then return end
  return gamemode[gm_values.gm].is_game_over()  
end

function notify_gamemode_new_p(id_player, score)
  if SERVER_ONLY and not id_player and not gm_values.gm then return end
  gamemode[gm_values.gm].new_p(id_player, score)  
end

function notify_gamemode_deleted_p(id_player)
  if SERVER_ONLY and not id_player and not gm_values.gm then return end
  gamemode[gm_values.gm].deleted_p(id_player)  
end

do

  gamemode = {
    {    
      -- (temporary name)
      name = "Keep the Crown",
      
      description = "The Crown's description, and it's holy.",
      
      init = function()
        -- place the crown on the map
        -- set crown.x, crown.y         
        -- crowned_player = nil    
        gm_values.leaderboard = {}        
        for i, p in pairs(players) do notify_gamemode_new_p(i, 0) end
        
      end,
    
      update = function()
        
        for i, l in pairs(gm_values.leaderboard()) do
          l.score = l.score - dt()
        end
        -- local found = false
        -- for _, p in pairs(players) do 
          -- if not found and dist(player, crown) < 16 then 
            -- crown = nil
            -- crowned_player = player.id
            -- found = true
            -- new_log(player.name .. " began his rule.")
          -- end
        -- end
        
        -- if crowned_player then -- update score based on time possessing the crown
          -- local l = leaderboard[crowned_player]
          -- l = l + dt()
        -- end
        
      end,
      
      new_p = function(id_player, score)
        gm_values.leaderboard[id_player or 0] = {score = score or 15}      
      end,
      
      deleted_p = function(id_player)
        gm_values.leaderboard[id_player or 0] = nil     
      end,
      
      is_game_over = function()
        for i, l in pairs(gm_values.leaderboard) do
          if l.score <= 0 then l.score = 0 return true end
        end
      end,
      
      game_over = function()
        sorted_lb = {} -- rank : {player_id, score} , table is already sorted
        game_over(sorted_lb)
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
        gm_values.leaderboard[id_player or 0] = {score = score or 100, time_joined = t()}      
      end,
      
      deleted_p = function(id_player)
        gm_values.leaderboard[id_player or 0] = nil     
      end,
      
      is_game_over = function()
        for i, l in pairs(gm_values.leaderboard) do
          if l.score <= 0 then l.score = 0 new_log("here") return true end
        end
      end,
      
  
      game_over = function()
        sorted_lb = {} -- rank : {player_id, score} , table is already sorted
        game_over(sorted_lb)
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

end