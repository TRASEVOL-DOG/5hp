-- Gamemode dictates the start, update and end state of the games

gamemode = {}
-- current_gm = 0

gm_values = {}

leaderboard_is_large = true

function init_gamemode(gm)
  if not IS_SERVER then return end
  if gm < 1 then return end
  current_gm = gm
  
  log("Initializing game mode: "..gamemode[gm].name)
  -- log(gm_values.leaderboard and count(gm_values.leaderboard) or "nil")
  gamemode[gm].init()
end

function update_gamemode()
  if not IS_SERVER then 
    if btnp("tab") then 
      leaderboard_is_large = not leaderboard_is_large 
      sfx("tab")
    end   
    return 
  end
  
  -- log(gm_values.leaderboard and count(gm_values.leaderboard) or "nil")
  
  if gamemode and gamemode[current_gm] and gamemode[current_gm].update then
    gamemode[current_gm].update()
  end
  
end

function draw_gamemode_infos()

  -- draw the leaderboard
  draw_leaderboard()
  
  -- write the game mode name (probably in the middle of the top part of the screen
  local str = current_gm and ("Playing "..gamemode[current_gm].name) or "Waiting for server..."
  pprint(str, screen_w()/2 - str_px_width(str)/2, 5)
  
  if gamemode == 1 then draw_crown_indicator() end
  
end

function game_over(sorted_lb)
  current_gm = 0
  gm_values = {}
end

function notify_gamemode_new_p(id_player, score)
  if SERVER_ONLY and not id_player then return end
  gamemode[current_gm].new_p(id_player, score)  
end

function notify_gamemode_deleted_p(id_player)
  if SERVER_ONLY and not id_player then return end
  gamemode[current_gm].deleted_p(id_player)  
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
      
        -- local found = false
        -- for _, p in pairs(players) do 
          -- if found and dist(player, crown) < 16 then 
            -- crown = nil
            -- crowned_player = player.id
            -- found = true
            -- display_new_ruler(player.name)
          -- end
        -- end
        
        -- if crowned_player then -- update score based on time possessing the crown
          -- local l = leaderboard[crowned_player]
          -- l = l + dt()
        -- end
        
      end,
      
      new_p = function(id_player, score)
        gm_values.leaderboard[id_player or 0] = {score = score or 0}      
      end,
      
      deleted_p = function(id_player)
        gm_values.leaderboard[id_player or 0] = nil     
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
        
      end,
      
      new_p = function(id_player, score)
        gm_values.leaderboard[id_player or 0] = {score = score or 0}      
      end,
      
      deleted_p = function(id_player)
        gm_values.leaderboard[id_player or 0] = nil     
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