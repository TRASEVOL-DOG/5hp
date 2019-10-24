-- Gamemode dictates the start, update and end state of the games

gamemode = {}
current_gm = 0

function init_gamemode(gm)
  if gm < 1 then return end
  current_gm = gm
  gamemode[gm].init()
end

function update_gamemode()
  if gamemode and gamemode[current_gm] and gamemode[current_gm].update then
    gamemode[current_gm].update()
  end
end

function game_over(leaderboard)
  current_gm = 0
end


do

  gamemode = {
  -- (temporary name) Keep the Crown
    {    
      name = "ktc",
      
      init = function()
        
      
      end,
    
      update = function()
        
      
      end,
      
      game_over = function()
        leaderboard = {} -- player : score , table is already sorted
        game_over()
      end,
    },
  -- (temporary name) Deathmatch
    {    
      name = "dm",
      
      init = function()
        
      
      end,
    
      update = function()
        
      
      end,
  
      game_over = function()
        leaderboard = {} -- player : score , table is already sorted
        game_over()
      end,
    }
    
  }
  ------------
  

end