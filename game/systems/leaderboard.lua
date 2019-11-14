
function draw_leaderboard()
  
  if not gm_values.leaderboard then return end
    
  for i, l in pairs(gm_values.leaderboard) do
    if not players[i] then gm_values.leaderboard[i] = nil end 
  end
  
  local sx, sy = screen_size()
  local leaderboard = gm_values.leaderboard
  local size = count(leaderboard)
  
  local l_t = " Leaderboard  "
  local l_w = str_px_width(l_t)
  
  local width = str_px_width(get_longest_line())
  local w = max(str_px_width(l_t), str_px_width("  ") + width) + 6  
  
  
  local y = 8
  
  if not leaderboard_is_large then
    if size > 5 then    
      size = 5  
      pprint("\"Tab\" to expand ", sx - str_px_width("\"Tab\" to expand "),  y + (size)*9)    
    end
  else  
    local h = size*9
    
    palt(2,true)
    palt(6,false)    
    frame(448,  sx - w, y - 4, sx - 1, y + h + 24, true)
    palt(6,true)  
    palt(2,false)
    
    pprint(l_t, sx - w/2 - l_w/2 , y - 2)
    
  end
  -- if small and player >  5th, will display 3 first, "..." + the player on the 5th line
  if count(leaderboard) > 0 then
    for i, l in pairs(leaderboard) do
      l.name = players[i].name
    end
    
    local tab = get_ordered_tab("descending", leaderboard, "score") or {}
    local my_rank = get_rank(tab, my_id)
    
    if leaderboard_is_large or size < 6 then
    -- if big, will display everything  
      for i = 1, size do
        local l = tab[i]    
        local str = " "..i.."."..(l.name or "").." ("..l.score..") "
        t_pprint(str, sx - (leaderboard_is_large and w or width)/2 - width/2 , y + (i-1)*8.8 + 9 * (leaderboard_is_large and 1 or -1) ,(i==my_rank) )
      end
    else    
      for i = 1, 3 do
        local l = tab[i]    
        local str = i.."."..(l.name or "").." ("..l.score..") "
        t_pprint(str, sx - (leaderboard_is_large and w or width)/2 - str_px_width(str)/2 , y + (i-1)*8.8 - 9 ,(i==my_rank) )
      end    
    
      -- if small and player <= 5th, will display 5 first
      if my_rank < 6 then     
        for i = 4, 5 do
          local l = tab[i]        
          local str = i.."."..(l.name or "").." ("..l.score..") "
          t_pprint(str, sx - (leaderboard_is_large and w or width)/2 - str_px_width(str)/2 , y + (i-1)*8.8 - 9 ,(i==my_rank) )
        end
      else
        -- 4th
        t_pprint("...", sx - (leaderboard_is_large and w or width)/2 - str_px_width(str)/2 , y + (4-1)*8.8 - 9 ,(i==my_rank) )
        
        -- 5th
        local l = tab[5]        
        local str = "5".."."..(l.name or "").." ("..l.score..") "
        t_pprint(str  , sx - (leaderboard_is_large and w or width)/2 - str_px_width(str)/2 , y + (5-1)*8.8 - 9 ,(i==my_rank) )    
      end
    end
  end
end

function t_pprint(str, x, y, bool) -- will print player's rank in another color if bool is true
  if bool then 
    printp_color(12 + flr(t()*2)%2, 11, 6)
  end  
  pprint(str, x, y)  
  printp_color(14, 11, 6)
end

function get_longest_line()
  local n = ""
  local mw = 0
  local j = 0
  local s = 0
  local leaderboard = gm_values.leaderboard or {}
  
  for i, p in pairs(leaderboard) do
    local w = str_px_width(j..(players[i].name or "")..(p.score or 0))
    if mw < w then
      mw = w 
      n = players[i].name
      j = i
      s = p.score
    end
  end
  return j..". "..n.." ( "..s.." ) "
end

function get_ordered_tab(mode, tab, key)
  local copy_t = copy_table(tab)
  local sorted_list = {}
  
  if mode == "descending" then    
    while count(copy_t) > 0 do
      local mx, i = get_max(copy_t, key)
      add(sorted_list, tab[i])
      copy_t[i] = nil
    end  
  elseif mode == "ascending" then
  end
  
  return sorted_list
end

function count(tab)
  if not tab then return 0 end
  local nb = 0
  for i, j in pairs(tab) do nb = nb + 1 end
  return nb  
end
  
function get_max(tab, key)
  if tab == {} or not key then return end
  local mx
  local index
  for i, l in pairs(tab) do
    mx = mx or l.key    
    index = index or i   
    if l and l.key then 
      if l.key > mx then 
        mx = l.key 
        index = i 
      end    
    end    
  end
  return mx, index
end

function get_rank(lb, id)
  if not players or not players[id] or not lb then return end
  for i = 1, #lb do
    if lb[i].name == players[id].name then return i end
  end
end
