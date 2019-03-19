
leaderboard = {is_large = false}

function get_list_leaderboard()
  
  local list_player = get_group_copy("player")
  local sorted_list = {}
  
  local my_id = my_id or 1
  my_place = 0
  local rank = 1
  
  for i = 1, #list_player do -- defined above
  
    local maxi = 0
    local index = 1
    
    for j, v in pairs(list_player) do
      if v.score > maxi then 
        maxi = v.score
        index = j
      end
      if v.id == my_id then
        my_place = rank
      end
    end
    
    local lrank = rank or 1
    local lname = list_player[index].name or ""
    local lscore = list_player[index].score or 1
    
    add(sorted_list, {  rank = lrank, 
                        name = lname,
                        score = lscore})
    delat(list_player, index)
    rank = rank + 1
    
    
  end 
   
  return sorted_list -- array of string with players according to score
end

function get_victim()
  return player_li -- array of string with players according to score
end

function get_victimest()
  return { "playertwo" } -- array of string with players according to score
end

function get_killer()
  return { "playerthree" } -- array of string with players according to score
end

function init_leaderboard()

  leaderboard.is_large = false

end

function draw_leaderboard()
  
  local sx, sy = screen_size()
  
  local y = 8
  local x = 70
    
  local size = #leaderboard.list
  
  y = 8
  if not leaderboard.is_large then
    size = size > 5 and 5 or size
    y = - 13
    
    draw_text_oultined("\"Tab\" to expand", sx - str_width("\"Tab\" to expand"),  y + 3 + (size+1)*8, 0)
  else
    rectfill(sx - x - 2, y + 1, sx - 2 , y + 12 , 0)
    rectfill(sx - x - 1, y + 2, sx - 3 , y + 11 , 1)
    draw_text_oultined(" Leaderboard", sx - x, y - 2, 0)
    rectfill(sx - x - 2, y + 13     , sx - 2 , y + 10 + (size+1) * 8    , 0)
    rectfill(sx - x - 1, y + 13 + 1 , sx - 3 , y + 10 + (size+1) * 8 - 1, 1)
    sx = sx - 4
    
    
  end
   
  -- if big, will display everything
  -- if small and player <= 5th, will display 5 first
  -- if small and player >  5th, will display 3 first, "..." + the player on the 5th line
 
  for i = 1, size do
  
    local player = leaderboard.list[i]
    local c = not ( my_place == i )
    local str = player.rank .. "." .. player.name .. "(" .. player.score .. ")"
    
    if leaderboard.is_large then    
      str = player.rank .. "." .. player.name .. "(" .. player.score .. ")"
    else 
      if i == 4 and my_place > 5  then
        str = "..."
      end
      if i == 5 and my_place > 5  then        
        player = leaderboard.list[my_place]
        str = player.rank .. "." .. player.name .. "(" .. player.score .. ")"
        c = 2        
      end
    end
    
    draw_text_oultined(str, sx - leaderboard.width - 19 , y + 3 + i*8 , c)
  end
  
  str = "Last victim :"
  y = sy - 60
  draw_text_oultined(str, sx - str_width(str), y, 0)
   
  str = leaderboard.last_victim or "none"
  y = y + 8
  draw_text_oultined(str, sx - str_width(str), y)
  
  str = "Last killer :"
  y = y + 10
  draw_text_oultined(str, sx - str_width(str), y)
  
  str = leaderboard.last_killer or "none"
  y = y + 8
  draw_text_oultined(str, sx - str_width(str), y)
  
  str = "Most killed :"
  y = y + 10
  draw_text_oultined(str, sx - str_width(str), y)
  
  local q = leaderboard.most_killed
  
  y = y + 8
  
  if q and q.count > 0 and q.name ~="" then
      str = q.name
      str = (str .. "(" .. q.count .. ")" )
  else
    str = "none"
  end
  draw_text_oultined(str, sx - str_width(str), y)
  
end

function update_leaderboard()

  if btnp(10) then 
    leaderboard.is_large = not leaderboard.is_large 
    sfx("tab")
  end
  
  leaderboard.list = get_list_leaderboard()
  
  leaderboard.width = get_length_leaderboard()
  
  if player_list[my_id] then
  
    local name = "none"
    
    -- find in last victim 
    local d = death_history.last_victim[my_id]
    if d and player_list[d.victim] then
      name = player_list[d.victim].name 
    else
      name = "none"
    end
    leaderboard.last_victim = name
    
    -- find last killer
    d = death_history.last_killer[my_id]
    if d and player_list[d.killer] then
      name = player_list[d.killer].name  
    else
      name = "none"
    end
    leaderboard.last_killer = name

    -- find most killed
    get_most_killed() -- {name : count}
    
  end
  
end
                
function get_most_killed()

  local count = 0
  local killed_name = ""
  local found = false
  
  if death_history.kills then
    for i, v in pairs(death_history.kills) do
      if v.killer == my_id and v.count > count then
        count = v.count
        -- debuggg = "count found"
        local p = player_list[v.victim]
        if p then
          killed_name = p.name
        end
      end
    end
  end
  leaderboard.most_killed =  {name = killed_name, count = count}
end


function draw_text_oultined(str, x, y, c1, me)
  y = y + 5
  if c1 then draw_text(str, x, y, 0, 0,2,3) else draw_text(str, x, y, 0, 1,2,3) end
end

function get_length_leaderboard()
  local maxi = 0
  if (graphics) then
    for i = 1, #leaderboard.list do
      local name = leaderboard.list[i].name or ""
      local length = str_width(name)
      if length > maxi then
        maxi = length
      end  
    end
  end
  return maxi
end