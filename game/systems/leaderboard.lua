

function draw_leaderboard(x, y, align_x, align_y, font, force_large, title)
  if not gm_values.leaderboard then return end

  use_font(font or "small")

  local leaderboard = {}
  for i, l in pairs(gm_values.leaderboard) do
    local p = players[i]
    if p then
      leaderboard[i] = { score = l.score, name = p.name or "" }
    end
  end
  
  local tab = get_ordered_tab(gm_values.leaderboard_order or "descending", leaderboard, "score") or {}

  local title = (title or "Leaderboard").." "
  local spacing = (font and font == "big" and 12) or 9
  local my_rank = get_rank(tab, my_id) or 0
  local large = leaderboard_is_large or force_large
  
  local w = max(str_px_width(title), str_px_width(get_longest_line(leaderboard))) + 8
  local h = #tab * spacing + 24
  
  x = x - align_x * w
  y = y - align_y * h
  
  printp(0x0300, 0x3130, 0x3230, 0x0300)
  printp_color(12, 4, 6)
  
  if large then
    palt(2, true) palt(6, false) palt(0, false)
    frame(448, x-2, y-2, x+w+2, y+h+4, true)
    palt(2, false) palt(6, true)
    
    pprint(title, x + (w-str_px_width(title))/2, y+spacing-9)
    y = y + flr(1.4 * spacing)
  end
  
  for i, l in pairs(tab) do
    l.str = i..". "..l.name.." ("..l.score..")"
  end
  
  if not large and my_rank > 5 then
    tab[4].str = "..."
    tab[5] = tab[my_rank]
    tab[6] = nil
  end
  
  for i, l in ipairs(tab) do
    pprint(l.str, x+4, y, (i == my_rank and t()%1 < 0.5) and 14 or 12)
    y = y + spacing
  end
  
  if not large then
    local str = '"Tab" to expand'
    pprint(str, x+w-str_px_width(str), y)
  end
end

function get_longest_line(leaderboard)
  local n = ""
  local mw = 0
  local j = 0
  local s = 0
  -- local leaderboard = gm_values.leaderboard or {}
  -- local leaderboard = {}
  -- for i, l in pairs(gm_values.leaderboard) do
    -- if players[i] then leaderboard[i] = l end 
  -- end
  
  for i, p in pairs(leaderboard) do
    local w = str_px_width(j..(players[i].name or "")..(p.score or 0))
    if mw < w then
      mw = w 
      n = players[i].name
      j = i
      s = p.score
    end
  end
  return j..". "..n.." ("..s..") "
end

function get_ordered_tab(mode, tab, key)
  local copy_t = copy_table(tab)
  local sorted_list = {}
  if mode == "descending" then
    while count(copy_t) > 0 do
      local mx, i = get_max(copy_t, key)
      sorted_list[#sorted_list + 1] = tab[i]
      copy_t[i] = nil
    end  
  elseif mode == "ascending" then
    while count(copy_t) > 0 do
      local mx, i = get_min(copy_t, key)
      sorted_list[#sorted_list + 1] = tab[i]
      copy_t[i] = nil
    end
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
    mx = mx or l[key]    
    index = index or i   
    if l[key] then 
      if l[key] > mx then 
        mx = l[key] 
        index = i 
      end    
    end    
  end
  return mx, index
end

function get_min(tab, key)
  if tab == {} or not key then return end
  local mn
  local index
  for i, l in pairs(tab) do
    mn = mn or l[key]    
    index = index or i   
    if l[key] then 
      if l[key] < mn then 
        mn = l[key] 
        index = i 
      end    
    end    
  end
  return mn, index
end

function get_rank(lb, id)
  if not players or not players[id] or not lb then return end
  for i = 1, #lb do
    if lb[i].name == players[id].name then return i end
  end
end
