-- Gamemode dictates the start, update and end state of the games

gamemode = {}
-- current_gm = 0

leaderboard = {}
leaderboard_is_large = true

function init_gamemode(gm)
  if not IS_SERVER then return end
  if gm < 1 then return end
  current_gm = gm
  leaderboard = {}
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
