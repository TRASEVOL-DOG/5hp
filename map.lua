

map_data = nil

local map_w, map_h
local map_index

local map_ground_surf
local map_wall_surf

local wall_hp = {}
local wall_flash = {}

local walls = {[2] = true}
local wall_hpmax = 3



function init_map()
  map_index = 1
  map_data = copy_table(maps[map_index], true)
  map_w = #map_data[0]
  map_h = #map_data
  
  gen_mapsurf()
  
  for y = 0, map_h-1 do
    wall_hp[y] = {}
    for x = 0, map_w-1 do
      local m = map_data[y][x]
      
      if m == 2 then
        wall_hp[y][x] = wall_hpmax
      end
    end
  end
end

function draw_map()
  local w,h = screen_size()
  local x,y = get_camera_pos()
  local sx,sy = 0,0

  palt(0,false)
  spr_sheet(map_ground_surf, -x, -y)
  palt(0,true)
  
  pal(7,14)
  for _,s in pairs(wall_flash) do
    local xx,yy = s.x*8, s.y*8
    spr(0, xx-x, yy-y)
  end
  pal(7,7)
end

function draw_map_top()
  local w,h = screen_size()
  local x,y = get_camera_pos()
  local sx,sy = 0,0
  
  y = y + 8

  palt(0,false)
  spr_sheet(map_wall_surf, -x, -y)
  palt(0,true)
  
  pal(7,14)
  for i,s in pairs(wall_flash) do
    local xx,yy = s.x*8, s.y*8
    spr(0, xx-x, yy-y)
    
    s.t = s.t - dt()
    if s.t <= 0 then
      del_at(wall_flash, i)
    end
  end
  pal(7,7)
end



function check_mapcol(s, x, y, w, h)
  local sx = x or s.x
  local sy = y or s.y
 
  local dirs = {{-1,-1},{1,-1},{-1,1},{1,1}}
  nirs=dirs
  
  local dd = 0.5
  local w  = w or s.w
  local h  = h or s.h
  
  local res, b = {0,0}
 
  for k,d in pairs(dirs) do
    local x = sx+w*dd*d[1]
    local y = sy+h*dd*d[2]
    
    local tx = flr(x/8)
    local ty = flr(y/8)
    
    if tx < 0 or tx >= map_w or ty < 0 or ty >= map_h or walls[map_data[ty][tx]] then
      res[1] = res[1] + d[1]
      res[2] = res[2] + d[2]
      b = true
    end
  end
  
  if res[1] ~= 0 then res[1] = sgn(res[1]) end
  if res[2] ~= 0 then res[2] = sgn(res[2]) end
  
  return b and {dir_x = res[1], dir_y = res[2]}
end

function get_maptile(x,y)
  if not map_data[y] then return nil end
  return map_data[y][x]
end



-- x and y have to be tile coordinates ( flr(world_x/8) )
function hurt_wall(x,y,dmg)
  if x <= 0 or y <= 0 or x >= map_w-1 or y >= map_h-1 then return end
  
  local hp = wall_hp[y][x]
  if not hp then
    return
  end
  
  if not IS_SERVER then
    add(wall_flash, {
      x = x,
      y = y,
      t = 0.03
    })
    
    for i=1,2 do
      create_leaf(x*8+4, y*8+4)
    end
    
    return
  end
  
  hp = hp-dmg
  
  if hp <= 0 then
    hp = 0
    update_map_wall(x, y, false)
  end
  
  wall_hp[y][x] = hp
end


local growth_t = 0
function grow_walls()
  if not IS_SERVER then return end

  growth_t = growth_t - dt()
  if growth_t > 0 then return end
  
  for i = 1, 16 do
    local x, y = irnd(map_w), irnd(map_h)
    local hp = wall_hp[y][x]
  
    if hp and hp < wall_hpmax then
      hp = min(hp + 0.5 + rnd(1), wall_hpmax)
      
      if hp == wall_hpmax and map_data[y][x] == 0 then
        update_map_wall(x, y, true)
      end
      
      wall_hp[y][x] = hp
    end
  end
  
  growth_t = 0.03
end


function update_map_wall(x, y, exists, fx)
  if fx then
    add(wall_flash, {
      x = x,
      y = y,
      t=0.03
    })
    
    local xx, yy = x*8+4, y*8+4
    
    for i=1,4 do
      create_leaf(xx, yy)
    end
    
    if not exists then
      log("destroy walll")
      create_explosion(xx, yy-4, 7, 5).recursive = chance(10)
      sfx("cactus_hit", xx, yy-4, 0.9+rnd(0.2), 0.66)
    end
  end
  
  map_data[y][x] = exists and 2 or 0
  
  update_walltile(x, y, true)
end

function update_walltile(x, y, recursive)
  if IS_SERVER then return end

  if recursive then
    update_walltile(x-1, y)
    update_walltile(x+1, y)
    update_walltile(x, y-1)
    update_walltile(x, y+1)
  end
  
  local d_line = map_data[y]
  local v = d_line[x]
  
  local xx = x * 8
  local yy = y * 8
  
  palt(6, true)
  palt(1, false)
  
  if v == 0 then
    if maps[map_index][y][x] == 0 then
      return
    end
    
    target(map_ground_surf)
    spr(60 + irnd(4), xx, yy)
    
    target(map_wall_surf)
    pal(7, 6)
    spr(0, xx, yy)
    pal(7, 7)
  elseif v == 2 then
    local n
    local left = (d_line[x-1] == 0)
    local right = (d_line[x+1] == 0)
    
    if left and right then
      n = 53
    elseif left then
      n = 51
    elseif right then
      n = 52
    else
      n = 48 + irnd(3)
    end
    
    target(map_ground_surf)
    spr(n, xx, yy)
  
    target(map_wall_surf)
  
    local k = 0
    if x <= 0       or d_line[x-1] == 2    then k = k+1 end
    if x >= map_w-1 or d_line[x+1] == 2    then k = k+2 end
    if y <= 0       or map_data[y-1][x]==2 then k = k+4 end
    if y >= map_h-1 or map_data[y+1][x]==2 then k = k+8 end

    local s = 56 + irnd(4)
    
    if k == 15 then
      local i = min(x, y, map_w-1-x, map_h-1-y)
      if i < 2 then
        s = 30 + i
      end
    end
    
    spr(s, xx, yy)
    
    local poss = {{0},{1},{2},{0},{1},{2},{0,1},{1,2},{2,0}}
    local p = pick(poss)
    pal(11, 5)
    pal(12, 5)
    pal(13, 5)
    for c in all(p) do
      pal(11+c,14)
    end
    
    spr(32+k, xx, yy)
    
    pal(11, 11)
    pal(12, 12)
    pal(13, 13)
  end
  
  target()
end





function gen_mapsurf()
  if IS_SERVER then return end
  
  map_ground_surf = map_ground_surf or new_surface(map_w*8, map_h*8)
  map_wall_surf = map_wall_surf or new_surface(map_w*8, map_h*8)
  
  target(map_ground_surf)
  cls(10)
  
  local flippable = {1,2,3,4,5,6,7,8,9,10,11,12,13,14,15}
  local is_flippable = {}
  for _,n in pairs(flippable) do is_flippable[n] = true end
  
  palt(0, false)
  
  for y = 0,map_h-2 do
    local d_line = map_data[y]
    for x = 0,map_w-1 do
      local v = d_line[x]
      local n = 0

      if v == 1 or v == 3 then
        n = 243
      elseif v == 9 or v == 10 then
        n = 228 + irnd(3)
      else
        if chance(0.5) then
          n = 15
        elseif chance(1) then
          n = 7+irnd(8)
        elseif chance(20) then
          n = irnd(7)
        end
      end
      
      spr(n, x*8, y*8, 1, 1, is_flippable[n] and chance(50))
    end
  end

  
  palt(6,true)
  for y = map_h-2,0,-1 do
    local d_line = map_data[y]
    for x = 0,map_w-1 do
      local v = d_line[x]

      if v == 2 or v == 9 or v == 10 then
        local left,right,up,down
        
        local left  = (x>0       and d_line[x-1] ~= 2    and d_line[x-1] ~= 9    and d_line[x-1] ~= 10)
        local right = (x<map_w-1 and d_line[x+1] ~= 2    and d_line[x+1] ~= 9    and d_line[x+1] ~= 10)
        local up    = (y>0       and map_data[y-1][x]~=2 and map_data[y-1][x]~=9 and map_data[y-1][x]~=10)
        local down  = (y<map_h-1 and map_data[y+1][x]~=2 and map_data[y+1][x]~=9 and map_data[y+1][x]~=10)
        
        local downleft  = (y<map_h-1 and x>0       and map_data[y+1][x-1]~=2 and map_data[y+1][x-1]~=9 and map_data[y+1][x-1]~=10)
        local downright = (y<map_h-1 and x<map_w-1 and map_data[y+1][x+1]~=2 and map_data[y+1][x+1]~=9 and map_data[y+1][x+1]~=10)
        
        local xx = x*8
        local yy = y*8
        
        if left then
          if up then
            spr(16, xx-8, yy-8)
          end
          
          if down then
            spr(18, xx-8, yy+8)
          end
          
          spr(20+irnd(2), xx-8, yy)
        end
        
        if right then
          if up then
            spr(17, xx+8, yy-8)
          end
          
          if down then
            spr(19, xx+8, yy+8)
          end
          
          spr(22+irnd(2), xx+8, yy)
        end
        
        if up then
          spr(26, xx, yy-8)
        end
        
        if down then
          if v == 2 then
            if downleft and downright then
              spr(27+irnd(3), xx, yy+8)
            elseif downleft then
              spr(24, xx, yy+8)
            elseif downright then
              spr(25, xx, yy+8)
            else
              spr(79, xx, yy+8)
            end
          else
            if downleft and downright then
              spr(246+irnd(2), xx, yy+8)
            elseif downleft then
              spr(244, xx, yy+8)
            elseif downright then
              spr(245, xx, yy+8)
            else
              spr(231, xx, yy+8)
            end
          end
        end
      end
    end
  end
  
  for y = 0,map_h-2 do
    local d_line = map_data[y]
    for x = 0,map_w-1 do
      local v = d_line[x]

      if v == 2 then
        local n
        local left = (d_line[x-1] ~= 2)
        local right = (d_line[x+1] ~= 2)
        
        if left and right then
          n = 53
        elseif left then
          n = 51
        elseif right then
          n = 52
        else
          n = 48+irnd(3)
        end
        
        spr(n, x*8, y*8, 1, 1, is_flippable[n] and chance(50))
      end
    end
  end
  
  
  for y = 0,map_h-2 do
    local d_line = map_data[y]
    for x = 0,map_w-1 do
      local v = d_line[x]
      local n

      if v == 1 then
        n = 241
      elseif v == 3 then
        n = 240
      end
      
      if n then
        spr(n, x*8, y*8)
      end
    end
  end
  
  
  target(map_wall_surf)
  cls(6)
  
  for y = 0, map_h-1 do
    local line = {}
    local d_line = map_data[y]
    for x = 0,map_w-1 do
      local v = d_line[x]

      if v == 2 then
        local k = 0
        if x<=0       or d_line[x-1] == 2    then k = k+1 end
        if x>=map_w-1 or d_line[x+1] == 2    then k = k+2 end
        if y<=0       or map_data[y-1][x]==2 then k = k+4 end
        if y>=map_h-1 or map_data[y+1][x]==2 then k = k+8 end

        local s = 56+irnd(4)
        
        if k == 15 then
          local i = min(x,y,map_w-1-x,map_h-1-y)
          if i < 2 then
            s = 30+i
          end
        end
        
        local xx = x*8
        local yy = y*8
        
        spr(s, xx, yy)
        
        local poss = {{0},{1},{2},{0},{1},{2},{0,1},{1,2},{2,0}}
        local p = pick(poss)
        pal(11,5)
        pal(12,5)
        pal(13,5)
        for c in all(p) do
          pal(11+c,14)
        end
        
        spr(32+k, xx, yy)
      end
      
    end
  end
  
  pal(11,11)
  pal(12,12)
  pal(13,13)

  if crown_spawn then
    target(map_ground_surf)
    spr(242, crown_spawn.x-4, crown_spawn.y-4)
  end
  
  target()
  palt(0,true)
end





maps = {
  {[0]={[0]=2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2},
    {[0]=2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2},
    {[0]=2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2},
    {[0]=2,2,2,2,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,9,0,2,2,9,0,2,2,9,0,2,2,9,0,2,2,0,0,2,2,0,9,2,2,0,9,2,2,0,9,2,2,0,9,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,2,2,2,2},
    {[0]=2,2,2,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,3,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,2,0,0,0,0,0,0,0,0,0,0,0,0,2,2,2},
    {[0]=2,2,2,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,0,0,0,0,0,2,2,2},
    {[0]=2,2,2,0,0,0,2,2,0,0,0,0,0,0,0,2,0,0,0,0,0,0,0,2,2,0,0,0,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,0,0,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,0,0,0,0,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,0,0,0,0,2,2,2},
    {[0]=2,2,2,0,0,0,2,2,0,0,0,0,9,0,2,2,2,0,9,0,0,0,0,2,2,0,0,0,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,0,0,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,9,0,9,10,2,2,2,0,0,0,0,2,2,2,0,0,0,0,2,2,2,10,9,0,9,2,2,2},
    {[0]=2,2,2,0,0,0,0,0,0,2,0,0,0,0,2,2,2,0,0,0,0,2,0,0,0,0,0,0,2,2,2,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,2,2,0,0,0,0,0,0,0,0,0,0,0,0,2,2,0,0,0,9,0,9,0,9,0,0,0,0,0,0,0,0,0,0,0,0,9,0,0,9,0,0,0,0,0,0,0,0,0,0,2,2,2,9,0,0,9,2,2,0,0,0,0,0,0,2,0,0,0,0,0,0,2,2,9,0,0,9,2,2,2},
    {[0]=2,2,2,0,0,0,0,0,0,0,0,2,2,0,2,2,2,0,2,2,0,0,0,0,0,0,0,0,2,2,0,8,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,2,2,0,8,0,0,0,0,0,0,0,0,8,0,2,2,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,2,2,10,9,0,9,2,2,0,0,0,0,0,0,0,0,0,0,0,0,0,2,2,9,0,9,10,2,2,2},
    {[0]=2,2,2,0,0,0,0,0,0,2,0,0,0,0,2,2,2,0,0,0,0,2,0,0,0,0,0,0,2,2,0,0,0,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,0,0,2,2,2,2,2,2,2,2,0,0,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,0,0,2,2,2,2,2,2,2,2,2,0,0,0,2,2,0,0,0,0,2,0,0,0,0,2,0,0,0,0,0,2,0,0,0,0,2,0,0,0,0,2,2,2},
    {[0]=2,2,2,0,0,0,2,2,0,0,0,1,0,2,2,2,2,2,0,1,0,0,0,2,2,0,0,0,2,2,9,0,9,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,0,0,2,2,2,2,2,2,2,2,0,0,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,0,0,2,2,2,2,2,2,2,2,2,9,0,9,2,2,0,0,0,0,0,0,0,1,0,2,0,0,0,0,0,2,0,1,0,0,0,0,0,0,0,2,2,2},
    {[0]=2,2,2,0,0,0,2,2,0,0,0,0,0,2,2,2,2,2,0,0,0,0,0,2,2,0,0,0,2,2,0,0,0,2,2,2,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,8,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,2,2,2,0,0,0,2,2,0,0,0,0,0,0,0,0,0,2,0,0,0,0,0,2,0,0,0,0,0,0,0,0,0,2,2,2},
    {[0]=2,2,2,0,0,0,0,0,0,2,0,0,0,0,2,2,2,0,0,0,0,2,0,0,0,0,0,0,2,2,0,0,0,2,2,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,2,2,0,0,0,2,2,0,0,0,0,2,0,0,0,0,2,0,0,0,0,0,2,0,0,0,0,2,0,0,0,0,2,2,2},
    {[0]=2,2,2,0,0,0,0,0,0,0,0,2,2,0,2,2,2,0,2,2,0,0,0,0,0,0,0,0,2,2,0,0,0,2,2,0,0,0,2,2,2,2,2,2,2,0,0,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,0,0,0,2,2,0,0,0,2,2,10,9,0,9,2,2,0,0,0,0,0,0,0,0,0,0,0,0,0,2,2,9,0,9,10,2,2,2},
    {[0]=2,2,2,0,0,0,0,0,0,2,0,0,0,0,2,2,2,0,0,0,0,2,0,0,0,0,0,0,2,2,0,0,0,2,2,9,0,9,2,2,2,2,2,2,2,0,0,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,9,0,9,2,2,0,0,0,2,2,9,0,0,9,2,2,0,0,0,0,0,0,2,0,0,0,0,0,0,2,2,9,0,0,9,2,2,2},
    {[0]=2,2,2,0,0,0,2,2,0,0,0,0,9,0,2,2,2,0,9,0,0,0,0,2,2,0,0,0,2,2,0,0,0,2,2,0,0,0,2,2,2,0,0,0,0,0,0,0,8,0,2,2,0,0,0,0,0,0,0,0,0,0,0,9,0,0,9,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,2,2,2,0,0,0,2,2,0,0,0,2,2,9,0,9,10,2,2,2,0,0,0,0,2,2,2,0,0,0,0,2,2,2,10,9,0,9,2,2,2},
    {[0]=2,2,2,0,0,0,2,2,0,0,0,0,0,0,0,2,0,0,0,0,0,0,0,2,2,0,0,0,2,2,0,0,0,2,2,0,0,0,2,2,0,3,0,0,0,0,0,0,0,0,2,2,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,3,0,2,2,0,0,0,2,2,0,0,0,2,2,0,0,0,0,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,0,0,0,0,2,2,2},
    {[0]=2,2,2,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,2,2,0,0,0,2,2,0,0,0,2,2,0,0,0,2,2,2,2,2,2,2,2,2,2,2,0,2,2,2,2,2,2,2,2,2,0,0,2,2,2,2,2,2,2,2,2,2,2,0,0,2,2,2,2,2,2,0,0,0,2,2,0,0,0,2,2,0,0,0,2,2,0,0,0,0,0,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,0,0,0,0,0,2,2,2},
    {[0]=2,2,2,0,0,0,0,0,9,0,9,0,9,0,0,0,0,0,0,9,0,9,0,9,0,0,0,0,2,2,0,0,0,2,2,0,0,0,2,2,0,0,0,2,2,2,2,2,2,2,2,2,2,0,0,2,2,2,2,2,2,2,2,2,0,0,2,2,2,2,2,2,2,2,2,2,2,0,0,2,2,2,2,2,2,0,0,0,2,2,0,0,0,2,2,0,0,0,2,2,0,0,0,0,0,0,0,0,0,0,0,0,2,0,0,0,0,0,0,0,0,0,0,0,0,2,2,2},
    {[0]=2,2,2,0,0,0,0,0,10,0,0,0,0,0,0,0,0,0,0,0,0,0,0,10,0,0,0,0,2,2,0,0,0,2,2,0,0,0,2,2,0,0,0,0,0,0,0,0,0,0,0,0,0,9,2,2,0,8,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,8,0,2,2,0,0,0,0,0,2,2,2,0,0,0,2,2,0,0,0,2,2,0,0,0,2,2,0,0,0,0,9,10,9,10,9,10,9,0,0,0,9,10,9,10,9,10,0,0,0,0,0,2,2,2},
    {[0]=2,2,2,0,0,0,0,0,9,0,0,0,0,0,0,1,0,0,0,0,0,0,0,9,0,0,0,0,2,2,0,0,0,2,2,0,0,0,2,2,0,0,0,0,0,0,0,0,0,0,0,0,0,0,2,2,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,2,2,0,0,0,0,0,0,2,2,0,0,0,2,2,0,0,0,2,2,0,0,0,2,2,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,2,2,2},
    {[0]=2,2,2,0,0,0,0,0,10,0,0,0,0,0,0,0,0,0,0,0,0,0,0,10,0,0,0,0,2,2,0,0,0,2,2,0,0,0,2,2,0,0,0,2,2,0,0,0,2,2,0,0,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,0,0,0,2,2,0,9,0,0,0,0,0,0,2,2,0,8,0,2,2,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,2,2,2},
    {[0]=2,2,2,0,0,0,0,0,9,0,9,0,0,0,0,0,0,0,0,0,0,9,0,9,0,0,0,0,2,2,0,0,0,2,2,0,0,0,2,2,0,8,0,2,2,0,0,0,2,2,0,0,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,0,0,0,2,2,0,0,0,0,0,0,0,0,2,2,0,0,0,2,2,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,2,2,2},
    {[0]=2,2,2,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,2,2,0,0,0,2,2,0,0,0,2,2,0,0,0,2,2,0,0,0,2,2,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,2,2,2,0,0,0,2,2,2,2,2,2,2,0,0,0,2,2,0,0,0,2,2,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,2,2,2},
    {[0]=2,2,2,0,0,0,0,0,10,9,10,9,10,9,0,0,0,9,10,9,10,9,10,9,0,0,0,0,2,2,0,0,0,2,2,0,0,0,2,2,0,0,0,2,2,0,0,0,2,2,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,2,2,0,0,0,2,2,2,2,2,2,2,0,0,0,2,2,2,2,2,2,2,0,0,0,0,9,10,9,10,9,10,9,0,0,0,9,10,9,10,9,10,0,0,0,0,0,2,2,2},
    {[0]=2,2,2,0,3,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,2,2,0,0,0,2,2,0,0,0,2,2,2,2,2,2,2,0,0,0,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,0,0,2,2,2,2,0,0,0,2,2,0,0,0,2,2,0,0,0,2,2,0,0,0,2,2,2,2,2,2,2,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,3,0,2,2,2},
    {[0]=2,2,2,0,0,0,0,2,2,2,2,2,2,2,2,0,2,2,2,2,2,2,2,2,2,0,0,0,2,2,9,0,9,2,2,0,0,0,2,2,2,2,2,2,2,0,0,0,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,0,0,2,2,2,2,0,0,0,2,2,0,0,0,2,2,0,8,0,2,2,0,0,0,0,0,0,0,0,2,2,0,0,0,2,2,2,2,2,2,2,2,2,0,2,2,2,2,2,2,2,2,0,0,0,0,2,2,2},
    {[0]=2,2,2,0,0,0,0,2,0,0,0,0,0,0,0,0,0,0,0,0,2,0,0,0,2,0,0,0,2,2,0,0,0,0,0,0,0,0,2,2,0,0,0,2,2,0,0,0,2,2,2,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,2,2,2,0,0,0,2,2,0,0,0,2,2,0,0,0,2,2,0,0,0,0,0,0,0,0,2,2,0,0,0,2,0,0,0,0,0,0,0,0,0,2,0,0,0,0,0,0,2,0,0,0,0,2,2,2},
    {[0]=2,2,2,0,0,0,0,2,0,2,2,2,2,2,2,2,2,2,2,0,2,0,2,0,2,0,0,0,2,2,0,0,0,0,0,0,0,0,2,2,0,8,0,2,2,0,0,0,2,2,0,8,0,0,0,0,0,0,0,0,0,0,9,0,0,9,0,0,0,0,0,0,0,2,2,0,8,0,2,2,0,0,0,2,2,0,0,0,2,2,0,0,0,2,2,0,0,0,2,2,0,0,0,2,0,2,2,2,2,2,0,2,2,2,0,2,2,2,2,0,2,0,0,0,0,2,2,2},
    {[0]=2,2,2,10,9,0,0,2,2,2,0,0,0,0,0,2,0,0,0,0,0,0,2,0,2,0,0,0,2,2,2,2,2,2,2,0,0,0,2,2,0,0,0,2,2,0,0,0,2,2,0,0,0,2,2,9,0,9,2,2,2,2,2,0,0,2,2,2,2,2,9,0,9,2,2,0,0,0,2,2,0,0,0,2,2,0,0,0,2,2,0,0,0,2,2,0,0,0,2,2,0,0,0,2,0,0,0,0,0,2,0,0,0,0,0,2,0,0,2,0,2,0,0,9,10,2,2,2},
    {[0]=2,2,2,0,0,0,0,2,0,0,0,2,2,2,0,2,0,2,2,2,2,2,2,0,2,0,0,0,2,2,2,2,2,2,2,0,0,0,2,2,0,0,0,0,0,0,0,0,2,2,0,0,0,2,2,0,0,0,2,2,2,2,2,0,0,2,2,2,2,2,0,0,0,2,2,0,0,0,2,2,0,0,0,2,2,0,0,0,0,0,0,0,0,2,2,0,0,0,2,2,0,0,0,2,2,2,2,2,0,2,2,2,2,2,2,2,2,0,2,0,2,0,0,0,0,2,2,2},
    {[0]=2,2,2,0,0,9,10,2,0,2,0,2,0,0,0,0,0,0,0,0,2,0,2,0,2,0,0,0,2,2,0,0,0,2,2,0,0,0,2,2,0,9,0,0,0,0,0,0,0,0,0,0,0,2,2,0,0,0,2,2,2,10,9,0,0,9,10,2,2,2,0,0,0,2,2,0,0,0,2,2,0,0,0,2,2,0,0,0,0,0,0,0,0,2,2,0,0,0,2,2,0,0,0,2,0,0,0,2,0,2,0,0,0,0,0,0,0,0,2,0,2,10,9,0,0,2,2,2},
    {[0]=2,2,2,0,0,0,0,2,0,2,0,2,0,2,2,2,2,2,2,0,2,0,2,0,2,0,0,0,2,2,0,8,0,2,2,0,0,0,2,2,0,0,0,2,2,0,0,0,2,2,0,0,0,2,2,0,0,0,2,2,10,0,0,0,0,0,0,10,2,2,0,0,0,2,2,0,0,0,2,2,0,0,0,2,2,0,0,0,2,2,0,8,0,2,2,9,0,9,2,2,0,0,0,2,0,2,0,2,0,2,2,2,2,2,2,0,2,0,2,0,2,0,0,0,0,2,2,2},
    {[0]=2,2,2,10,9,0,0,2,0,2,2,2,0,2,1,0,0,1,2,2,2,0,0,0,2,0,0,0,2,2,0,0,0,2,2,0,0,0,2,2,0,0,0,2,2,0,0,0,2,2,0,0,0,2,2,0,0,0,2,2,9,0,1,0,0,1,0,9,2,2,0,0,0,2,2,0,0,0,2,2,0,0,0,2,2,0,0,0,2,2,0,0,0,2,2,0,0,0,2,2,0,0,0,2,2,2,0,2,2,2,1,0,0,1,2,0,2,0,2,0,2,0,0,9,10,2,2,2},
    {[0]=2,2,2,0,0,0,9,2,0,2,0,2,0,2,0,0,0,0,0,0,2,2,2,0,2,0,0,0,2,2,0,0,0,0,0,0,1,0,2,2,0,0,0,2,2,0,0,0,2,2,0,0,0,2,2,0,3,0,0,0,0,0,0,0,0,0,0,0,0,0,0,3,0,2,2,0,0,0,2,2,0,0,0,2,2,0,1,0,2,2,0,0,0,2,2,0,0,0,2,2,0,0,0,2,0,0,0,2,0,0,0,0,0,0,2,0,2,0,0,0,2,9,0,0,0,2,2,2},
    {[0]=2,2,2,0,0,0,9,2,0,0,0,2,2,2,0,0,0,0,2,0,2,0,2,0,2,0,0,0,2,2,0,0,0,0,0,0,0,0,2,2,0,0,0,2,2,0,8,0,2,2,0,0,0,2,2,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,2,2,0,0,0,0,0,0,0,0,2,2,0,0,0,2,2,2,2,2,2,2,0,0,0,2,2,0,0,0,2,0,2,2,2,0,2,0,0,0,0,2,0,2,2,2,0,2,9,0,0,0,2,2,2},
    {[0]=2,2,2,10,9,0,0,2,2,2,0,2,0,2,1,0,0,1,2,0,0,0,2,0,2,0,0,0,2,2,0,0,0,2,2,0,0,0,2,2,0,0,0,2,2,9,0,9,2,2,0,0,0,2,2,0,0,0,2,2,9,0,1,0,0,1,0,9,2,2,0,0,0,2,2,0,9,0,0,0,0,9,0,2,2,0,0,0,2,2,2,2,2,2,2,0,0,0,2,2,0,0,0,2,0,2,0,0,0,2,1,0,0,1,2,0,0,0,2,0,2,0,0,9,10,2,2,2},
    {[0]=2,2,2,0,0,0,0,2,0,0,0,2,0,2,2,2,2,2,2,2,2,0,2,0,2,0,0,0,2,2,0,0,0,2,2,0,0,0,2,2,0,0,0,2,2,0,0,0,2,2,0,0,0,2,2,0,0,0,2,2,10,0,0,0,0,0,0,10,2,2,0,0,0,2,2,0,0,0,2,2,0,0,0,2,2,0,0,0,2,2,0,0,0,2,2,0,0,0,2,2,0,0,0,2,0,2,0,2,2,2,2,2,2,2,2,0,2,0,2,0,2,0,0,0,0,2,2,2},
    {[0]=2,2,2,0,0,9,10,2,0,2,0,2,0,0,0,0,0,0,0,0,2,0,2,0,2,0,0,0,2,2,0,0,0,2,2,9,0,9,2,2,0,0,0,2,2,2,2,2,2,2,0,0,0,2,2,0,0,0,2,2,2,10,9,0,0,9,10,2,2,2,0,0,0,2,2,2,2,2,2,2,2,2,2,2,2,0,0,0,2,2,0,8,0,2,2,0,0,0,2,2,0,0,0,2,0,0,0,2,0,0,0,0,0,2,0,0,2,0,2,0,2,10,9,0,0,2,2,2},
    {[0]=2,2,2,0,0,0,0,2,0,2,0,2,2,0,2,2,2,2,2,0,2,0,2,0,2,0,0,0,0,0,0,0,0,2,2,0,0,0,2,2,0,0,0,2,2,2,2,2,2,2,0,0,0,2,2,0,0,0,2,2,2,2,2,0,0,2,2,2,2,2,0,0,0,2,2,2,2,2,2,2,2,2,2,2,2,0,0,0,2,2,0,0,0,0,0,0,0,0,2,2,0,0,0,2,0,2,0,2,0,2,2,2,0,2,2,2,2,0,2,0,2,0,0,0,0,2,2,2},
    {[0]=2,2,2,10,9,0,0,2,0,2,0,0,0,0,0,0,0,0,2,0,0,0,2,0,2,0,0,0,2,2,0,0,0,2,2,0,0,0,2,2,0,0,0,2,2,0,0,0,2,2,0,0,0,2,2,9,0,9,2,2,2,2,2,0,0,2,2,2,2,2,9,0,9,2,2,0,9,0,0,0,0,9,0,2,2,0,0,0,2,2,0,0,0,0,0,0,0,0,2,2,0,0,0,2,2,2,0,0,0,0,0,2,0,0,0,0,0,0,2,0,2,0,0,9,10,2,2,2},
    {[0]=2,2,2,0,0,0,0,2,0,2,2,2,2,2,2,2,2,2,2,2,2,2,2,0,2,0,0,0,2,2,0,0,0,2,2,0,0,0,2,2,0,0,0,2,2,9,8,9,2,2,0,0,0,2,2,0,0,0,0,0,0,0,9,0,0,9,0,0,0,0,0,0,0,2,2,0,0,0,0,0,0,0,0,2,2,0,0,0,2,2,0,0,0,2,2,0,0,0,2,2,0,0,0,2,0,2,2,2,2,2,0,2,2,2,2,2,2,2,2,0,2,0,0,0,0,2,2,2},
    {[0]=2,2,2,0,0,0,0,2,0,0,0,0,0,2,0,0,0,0,0,0,0,0,0,0,2,0,0,0,2,2,0,0,0,2,2,0,0,0,2,2,0,0,0,2,2,0,0,0,2,2,0,0,0,2,2,2,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,2,2,2,0,0,0,2,2,0,0,0,2,2,0,0,0,2,2,0,0,0,2,2,0,0,0,2,2,0,0,0,2,0,0,0,0,0,0,0,2,0,0,0,0,0,0,0,0,2,0,0,0,0,2,2,2},
    {[0]=2,2,2,0,0,0,0,2,2,2,2,2,2,2,2,0,2,2,2,2,2,2,2,2,2,0,0,0,2,2,0,0,0,2,2,0,8,0,2,2,0,0,0,2,2,0,0,0,2,2,0,0,0,2,2,2,2,2,2,0,0,2,2,2,2,2,2,2,2,2,2,2,2,2,2,0,0,0,2,2,0,0,0,2,2,0,0,0,2,2,0,0,0,2,2,0,8,0,2,2,0,0,0,2,2,2,2,2,2,2,2,2,0,2,2,2,2,2,2,2,2,0,0,0,0,2,2,2},
    {[0]=2,2,2,0,3,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,2,2,0,0,0,2,2,0,0,0,2,2,0,0,0,2,2,0,0,0,2,2,0,0,0,2,2,2,2,2,2,0,0,2,2,2,2,2,2,2,2,2,2,2,2,2,2,0,0,0,2,2,0,0,0,2,2,0,0,0,0,0,0,0,0,2,2,0,0,0,2,2,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,3,0,2,2,2},
    {[0]=2,2,2,0,0,0,0,9,10,9,10,9,10,9,0,0,0,9,10,9,10,9,10,9,0,0,0,0,2,2,0,0,0,2,2,0,0,0,2,2,0,0,0,2,2,0,0,0,2,2,0,8,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,2,2,0,0,0,0,0,0,0,8,0,2,2,0,0,0,2,2,0,0,0,0,0,0,0,0,2,2,0,0,0,2,2,0,0,0,0,0,0,9,10,9,10,9,0,0,0,9,10,9,10,9,0,0,0,0,0,0,2,2,2},
    {[0]=2,2,2,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,2,2,0,0,0,2,2,2,2,2,2,2,0,0,0,2,2,0,0,0,2,2,2,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,2,2,0,0,0,0,0,0,0,0,2,2,2,0,0,0,2,2,0,0,0,2,2,0,0,0,2,2,2,2,2,2,2,0,0,0,0,9,0,0,0,0,0,0,0,9,0,0,0,0,0,0,0,9,0,0,0,0,2,2,2},
    {[0]=2,2,2,0,0,0,0,9,0,0,10,0,0,9,0,0,0,9,0,0,10,0,0,9,0,0,0,0,2,2,0,0,0,2,2,2,2,2,2,2,0,0,0,0,0,0,0,0,2,2,2,2,2,2,2,0,0,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,0,0,0,2,2,0,0,0,2,2,0,0,0,2,2,2,2,2,2,2,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,2,2,2},
    {[0]=2,2,2,0,0,0,0,10,0,0,9,0,0,10,0,1,0,10,0,0,9,0,0,10,0,0,0,0,2,2,0,0,0,2,2,0,0,0,0,0,0,0,0,0,0,0,0,0,2,2,2,2,2,2,2,0,0,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,0,0,0,2,2,0,8,0,2,2,0,0,0,2,2,0,0,0,2,2,0,0,9,0,0,0,9,0,0,0,9,0,0,0,9,0,0,0,9,0,0,0,9,0,0,2,2,2},
    {[0]=2,2,2,0,0,0,0,9,0,0,10,0,0,9,0,0,0,9,0,0,10,0,0,9,0,0,0,0,2,2,0,0,0,2,2,0,8,0,0,0,0,0,0,2,2,0,0,0,0,0,0,0,0,0,0,0,0,2,2,9,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,2,2,0,0,0,2,2,0,0,0,2,2,0,8,0,2,2,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,2,2,2},
    {[0]=2,2,2,0,0,0,0,10,0,0,9,0,0,10,0,0,0,10,0,0,9,0,0,10,0,0,0,0,2,2,0,0,0,2,2,0,0,0,2,2,2,2,2,2,2,2,0,0,0,0,0,0,0,0,0,0,0,2,2,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,2,2,2,0,0,0,2,2,0,0,0,0,0,0,0,0,2,2,0,0,0,0,9,0,0,0,9,0,0,0,1,0,0,0,9,0,0,0,9,0,0,0,0,2,2,2},
    {[0]=2,2,2,0,0,0,0,0,0,0,0,0,0,0,0,2,0,0,0,0,0,0,0,0,0,0,0,0,2,2,0,0,0,2,2,9,0,9,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,0,0,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,0,0,0,0,0,0,0,0,2,2,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,2,2,2},
    {[0]=2,2,2,0,0,0,0,0,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,0,0,0,0,0,2,2,0,0,0,2,2,0,0,0,2,2,0,0,0,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,0,0,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,0,0,0,2,2,0,0,0,2,2,0,0,2,2,0,0,9,0,0,0,9,0,0,0,9,0,0,0,9,0,0,2,2,0,0,2,2,2},
    {[0]=2,2,2,0,0,0,0,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,0,0,0,0,2,2,0,0,0,0,0,0,0,0,2,2,0,3,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,9,0,9,0,9,0,9,0,9,0,9,0,9,0,9,0,9,0,0,0,3,0,2,2,0,0,0,2,2,0,0,0,2,2,0,0,2,2,0,0,0,0,0,0,0,0,2,0,0,0,0,0,0,0,0,2,2,0,0,2,2,2},
    {[0]=2,2,2,9,0,9,10,2,2,2,0,0,0,0,2,2,2,0,0,0,0,2,2,2,10,9,0,9,2,2,0,0,0,0,0,0,0,0,2,2,2,0,0,0,0,0,0,0,0,0,0,0,0,0,0,2,2,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,2,2,0,0,0,2,2,0,0,0,2,2,0,0,0,0,0,0,2,0,0,2,0,2,2,2,0,2,0,0,2,0,0,0,0,0,0,2,2,2},
    {[0]=2,2,2,9,0,0,9,2,2,0,0,0,0,0,0,2,0,0,0,0,0,0,2,2,9,0,0,9,2,2,0,0,0,2,2,0,0,0,2,2,2,2,2,2,2,2,2,2,2,2,0,0,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,0,2,2,2,0,0,0,2,2,0,0,0,2,2,0,0,0,0,0,2,0,0,0,0,0,2,2,2,0,0,0,0,0,2,0,0,0,0,0,2,2,2},
    {[0]=2,2,2,10,9,0,9,2,2,0,0,2,2,0,0,0,0,0,2,2,0,0,2,2,9,0,9,10,2,2,0,0,0,2,2,0,0,0,2,2,2,2,2,2,2,2,2,2,2,2,0,0,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,0,2,2,2,0,0,0,2,2,0,0,0,2,2,0,0,0,0,0,0,0,2,2,0,0,2,2,2,0,0,2,2,0,0,0,0,0,0,0,2,2,2},
    {[0]=2,2,2,0,0,0,0,2,2,0,0,0,0,0,0,0,0,0,0,0,0,0,2,2,0,0,0,0,2,2,0,0,0,2,2,0,0,0,0,0,0,0,0,0,0,2,2,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,2,2,0,8,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,2,2,0,0,0,2,2,0,0,0,0,2,0,2,2,2,2,0,2,2,2,0,2,2,2,2,0,2,0,0,0,0,2,2,2},
    {[0]=2,2,2,0,0,0,0,0,0,0,0,1,0,0,0,2,0,0,0,1,0,0,0,0,0,0,0,0,2,2,0,0,0,2,2,2,0,0,0,0,0,0,0,0,0,2,2,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,2,2,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,2,2,2,0,0,0,2,2,0,0,0,0,0,0,2,0,1,2,2,2,2,2,2,2,1,0,2,0,0,0,0,0,0,2,2,2},
    {[0]=2,2,2,0,0,0,0,0,0,0,0,0,0,0,0,2,0,0,0,0,0,0,0,0,0,0,0,0,2,2,9,0,9,2,2,2,2,2,2,2,2,2,2,0,0,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,0,0,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,9,0,9,2,2,0,0,0,0,0,0,0,0,0,2,2,2,2,2,2,2,0,0,0,0,0,0,0,0,0,2,2,2},
    {[0]=2,2,2,0,0,0,0,2,2,0,0,0,0,0,0,0,0,0,0,0,0,0,2,2,0,0,0,0,2,2,0,0,0,2,2,2,2,2,2,2,2,2,2,0,0,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,0,0,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,0,0,0,2,2,0,0,0,0,2,0,2,2,2,2,0,2,2,2,0,2,2,2,2,0,2,0,0,0,0,2,2,2},
    {[0]=2,2,2,10,9,0,9,2,2,0,0,2,2,0,0,0,0,0,2,2,0,0,2,2,9,0,9,10,2,2,0,8,0,0,0,0,0,2,2,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,9,0,9,0,9,0,0,0,2,2,0,0,0,0,0,8,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,2,2,0,0,0,0,0,0,0,2,2,0,0,2,2,2,0,0,2,2,0,0,0,0,0,0,0,2,2,2},
    {[0]=2,2,2,9,0,0,9,2,2,0,0,0,0,0,0,2,0,0,0,0,0,0,2,2,9,0,0,9,2,2,2,0,0,0,0,0,0,2,2,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,2,2,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,2,2,2,0,0,0,0,0,2,0,0,0,0,0,2,2,2,0,0,0,0,0,2,0,0,0,0,0,2,2,2},
    {[0]=2,2,2,9,0,9,10,2,2,2,0,0,0,0,2,2,2,0,0,0,0,2,2,2,10,9,0,9,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,0,0,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,0,0,0,0,0,0,2,0,0,2,0,2,2,2,0,2,0,0,2,0,0,0,0,0,0,2,2,2},
    {[0]=2,2,2,0,0,0,0,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,0,0,0,0,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,0,0,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,0,0,2,2,0,0,0,0,0,0,0,0,2,0,0,0,0,0,0,0,0,2,2,0,0,2,2,2},
    {[0]=2,2,2,0,0,0,0,0,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,2,2,0,0,0,0,0,0,9,0,0,0,9,0,0,0,0,0,0,2,2,0,0,2,2,2},
    {[0]=2,2,2,0,0,0,0,0,0,0,0,0,0,0,0,2,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,3,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,2,2,2},
    {[0]=2,2,2,2,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,9,0,2,2,9,0,2,2,9,0,2,2,9,0,2,2,0,0,2,2,0,9,2,2,0,9,2,2,0,9,2,2,0,9,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,2,2,2,2},
    {[0]=2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2},
    {[0]=2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2},
    {[0]=2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2}
  }
}

