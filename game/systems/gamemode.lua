-- Gamemode dictates the start, update and end state of the games

gamemode = {}
-- current_gm = 0

leaderboard = {}
leaderboard_is_large = false

function init_gamemode(gm)
  if not IS_SERVER then return end
  if gm < 1 then return end
  current_gm = gm
  leaderboard = {}
  gamemode[gm].init()  
end

function update_gamemode()
  if not IS_SERVER then return end
  
  if gamemode and gamemode[current_gm] and gamemode[current_gm].update then
    gamemode[current_gm].update()
  end
  
  -- if btnp(10) then 
    -- leaderboard_is_large = not leaderboard_is_large 
    -- sfx("tab")
  -- end
  
end

function draw_gamemode_infos()

  -- draw the leaderboard
  
  -- write the game mode name (probably in the middle of the top part of the screen
  local str = current_gm and ("Playing "..gamemode[current_gm].name) or "Waiting for server..."
  pprint(str, screen_w()/2 - str_px_width(str)/2, 5)
end

function game_over(sorted_lb)
  current_gm = 0
end


do

  gamemode = {
    {    
      -- (temporary name)
      name = "Keep the Crown",
      
      init = function()
        -- place the crown on the map
        -- set crown.x, crown.y 
        
        -- crowned_player = nil
      
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
      
      game_over = function()
        sorted_lb = {} -- rank : {player_id, score} , table is already sorted
        game_over(sorted_lb)
      end,
    },
    {    
      -- (temporary name) 
      name = "Deathmatch",
      
      init = function()
        
      
      end,
    
      update = function()
        
      
      end,
  
      game_over = function()
        sorted_lb = {} -- rank : {player_id, score} , table is already sorted
        game_over(sorted_lb)
      end,
    }
    
  }
  ------------
  

end

-- function draw_leaderboard()
  
  -- local sx, sy = screen_size()
  -- local l_t = " Leaderboard "
  -- local l_w = str_width(l_t)
  -- local width = get_leaderboard_width()
  -- local lb_w = str_width("  ") + width
  -- local y = 8
    
  -- local size = #leaderboard.list
  
  -- y = 8
  -- if not leaderboard.is_large then
    -- size = size > 5 and 5 or size
    -- y = - 13
    
    -- draw_text_oultined("\"Tab\" to expand", sx - str_width("\"Tab\" to expand"),  y + 3 + (size+1)*9, 0)
  -- else
    
    -- palt(2,true)
    -- palt(6,false)
    -- local w = max(l_w, lb_w)
    -- draw_frame(448, sx - w - 8, y - 4, sx - 1, y + 14 + (size+1) * (9 + (leaderboard_is_large and 1 or 0)), true)
    -- palt(6,true)
    -- palt(2,false)    
    
    -- draw_text_oultined(l_t, sx - w + (w-l_w)/2 - 2, y - 1, 0)
    
    -- sx = sx - 8
    
    
  -- end
   
  -- if big, will display everything
  -- if small and player <= 5th, will display 5 first
  -- if small and player >  5th, will display 3 first, "..." + the player on the 5th line
 
  -- for i = 1, size do
  
    -- local player = leaderboard.list[i]
    -- local str = player.rank .. "." .. player.name .. "(" .. player.score .. ")"
    
    -- if leaderboard.is_large then    
      -- str = player.rank .. "." .. player.name .. "(" .. player.score .. ")"
    -- elseif my_place > 5 then
      -- if i == 4 then
        -- str = "..."
      -- elseif i == 5 then        
        -- player = leaderboard.list[my_place]
        -- str = player.rank .. "." .. player.name .. "(" .. player.score .. ")"
      -- end
    -- end
    -- local c = (my_id ~= player.id)
    -- draw_text_oultined(str, sx - width , y + 3 + i*(9 + (leaderboard_is_large and 1 or 0)) , c)
  -- end
-- end
