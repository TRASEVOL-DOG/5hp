
map_data = nil

local map_w, map_h
local map_index

local map_ground_surf
local map_wall_surf
local map_water_surf

local wall_hp = {}
local wall_flash = {}

local walls = {[2] = true}
local walls_water = {[2] = true, [12] = true}
local wall_hpmax = 3

local player_spawns = {}
local player_spawns_n = 0


function init_map()
  if LOAD_MAP_FROM_PNG then
    local map = load_png(nil, "map.png", palettes.pico8, false)
    target(map)
    local w,h = target_size()
    
    local data = {}
    for y = 0, h-1 do
      local line = {}
      for x = 0, w-1 do
        line[x] = pget(x, y)
      end
      data[y] = line
    end
    
    target()
    
    maps[1] = encode_map(data)
    write_clipboard("\""..maps[1].."\",")
  end

  map_index = 1
  map_data = decode_map(maps[map_index])
  map_w = #map_data[0]
  map_h = #map_data
  
  gen_mapsurf()

  local flower_spawns = {}
  local weapon_spawns = {}
  local heal_spawns = {}
  
  for y = 0, map_h-1 do
    wall_hp[y] = {}
    for x = 0, map_w-1 do
      local m = map_data[y][x]

      if m == 2 then
        wall_hp[y][x] = wall_hpmax
      end
    end
  end
  
  local crown
  if IS_SERVER then
    for y = 0, map_h-1 do
      for x = 0, map_w-1 do
        local m = map_data[y][x]
        
        local p = {
          x = x*8+4,
          y = y*8+4
        }
        
        if m == 7 and gm_values.gm == 1 and not crown then
          if map_data[y][x+1] == 7 then p.x = p.x + 4 end
          if map_data[y+1][x] == 7 then p.y = p.y + 4 end
          crown = p
        elseif m == 8 then
          add(player_spawns, p)
        elseif m == 1 then
          add(weapon_spawns, p)
        elseif m == 3 then
          add(heal_spawns, p)
        elseif m == 9 then
          add(flower_spawns, p)
        end
      end
    end
    
    player_spawns_n = #player_spawns
  
    init_destructibles(flower_spawns)
    init_loot(weapon_spawns, heal_spawns, crown)
  end
end

function draw_map()
  local w,h = screen_size()
  local x,y = get_camera_pos()
  local sx,sy = 0,0

  palt(0,false)
  spr_sheet(map_water_surf, -x, -y)
  
  palt(6,true)
  apply_camera()
  for s in group("water") do
    s:draw()
  end
  palt(6,false)
  camera()
  
  palt(9, true)
  palt(12, true)
  spr_sheet(map_ground_surf, -x, -y)
  palt(9, false)
  palt(12, false)
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



function check_mapcol(s, x, y, w, h, water_stop)
  local sx = x or s.x
  local sy = y or s.y
 
  local dirs = {{-1,-1},{1,-1},{-1,1},{1,1}}
  nirs=dirs
  
  local dd = 0.5
  local w  = w or s.w
  local h  = h or s.h
  
  local walls = walls
  if water_stop then
    walls = walls_water
  end
  
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
  x, y = flr(x), flr(y)

  if not map_data[y] then return nil end
  return map_data[y][x]
end

function get_mapsize()
  return map_w, map_h
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
  
  map_ground_surf = map_ground_surf or new_surface(map_w*8, map_h*8-8, "map_ground")
  map_wall_surf = map_wall_surf or new_surface(map_w*8, map_h*8, "map_walls")
  map_water_surf = map_water_surf or new_surface(map_w*8, map_h*8-8, "map_water")
  
  target(map_ground_surf)
  cls(10)
  
  local flippable = {1,2,3,4,5,6,7,8,9,10,11,12,13,14,15}
  local is_flippable = {}
  for _,n in pairs(flippable) do is_flippable[n] = true end
  
  palt(0, false)
  
  local crown
  
  for y = 0,map_h-2 do
    local d_line = map_data[y]
    for x = 0,map_w-1 do
      local v = d_line[x]
      local n = 0

      if v == 1 or v == 3 then
        n = 243
      elseif v == 9 or v == 10 then
        n = 228 + irnd(3)
      elseif v == 12 then
        if d_line[x-1] ~= 12 then n = n + 1 end
        if d_line[x+1] ~= 12 then n = n + 2 end
        
        local line = map_data[y-1]
        if line and line[x] ~= 12 then n = n + 4 end
        local line = map_data[y+1]
        if line and line[x] ~= 12 then n = n + 8 end
        
        n = n + 0x2B0
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

      if v == 2 or v == 9 or v == 10 or v == 12 then
        local left,right,up,down
        
        local left  = (x>0       and d_line[x-1] ~= 2    and d_line[x-1] ~= 9    and d_line[x-1] ~= 10    and d_line[x-1] ~= 12   )
        local right = (x<map_w-1 and d_line[x+1] ~= 2    and d_line[x+1] ~= 9    and d_line[x+1] ~= 10    and d_line[x+1] ~= 12   )
        local up    = (y>0       and map_data[y-1][x]~=2 and map_data[y-1][x]~=9 and map_data[y-1][x]~=10 and map_data[y-1][x]~=12)
        local down  = (y<map_h-1 and map_data[y+1][x]~=2 and map_data[y+1][x]~=9 and map_data[y+1][x]~=10 and map_data[y+1][x]~=12)
        
        local downleft  = (y<map_h-1 and x>0       and map_data[y+1][x-1]~=2 and map_data[y+1][x-1]~=9 and map_data[y+1][x-1]~=10 and map_data[y+1][x-1]~=12)
        local downright = (y<map_h-1 and x<map_w-1 and map_data[y+1][x+1]~=2 and map_data[y+1][x+1]~=9 and map_data[y+1][x+1]~=10 and map_data[y+1][x+1]~=12)
        local upleft    = (y>0       and x>0       and map_data[y-1][x-1]~=2 and map_data[y-1][x-1]~=9 and map_data[y-1][x-1]~=10 and map_data[y-1][x-1]~=12)
        local upright   = (y>0       and x<map_w-1 and map_data[y-1][x+1]~=2 and map_data[y-1][x+1]~=9 and map_data[y-1][x+1]~=10 and map_data[y-1][x+1]~=12)
        
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
          
          if not downleft then
            spr(26, xx-8, yy)
          end
        end
        
        if right then
          if up then
            spr(17, xx+8, yy-8)
          end
          
          if down then
            spr(19, xx+8, yy+8)
          end
          
          spr(22+irnd(2), xx+8, yy)
          
          if not downright then
            spr(26, xx+8, yy)
          end
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
  
  local crown
  for y = 0,map_h-2 do
    local d_line = map_data[y]
    for x = 0,map_w-1 do
      local v = d_line[x]
      local xx, yy = x*8, y*8
      local n

      if v == 7 and not crown then
        if d_line[x+1] == 7      then xx = xx + 4 end
        if map_data[y+1][x] == 7 then yy = yy + 4 end
        n = 242
        crown = true
      elseif v == 1 then
        n = 241
      elseif v == 3 then
        n = 240
      end
      
      if n then
        spr(n, xx, yy)
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
  
  target(map_water_surf)
  spr_sheet(map_ground_surf, 0, 0)
  
  target()
  palt(0,true)
end



function get_player_spawn()
  local i = irnd(player_spawns_n)+1
  
  local p = player_spawns[i]
  
  del_at(player_spawns, i)
  add(player_spawns, p)
  player_spawns_n = (player_spawns_n - 2) % #player_spawns + 1
  
  return p
end


local dec2hex = {[0] = '0','1','2','3','4','5','6','7','8','9','a','b','c','d','e','f'}
local hex2dec = {['0'] = 0,['1'] = 1,['2'] = 2,['3'] = 3,['4'] = 4,['5'] = 5,['6'] = 6,['7'] = 7,['8'] = 8,['9'] = 9,['a'] = 10,['b'] = 11,['c'] = 12,['d'] = 13,['e'] = 14,['f'] = 15}
function encode_map(data)
  local w, h = #data[1], #data
  local str = string.format("%x-%x-", w, h)
  
  for y = 0, h-1 do
    local line = data[y]
    for x = 0, w-1 do
      str = str..dec2hex[line[x]]
    end
  end

  return str
end

function decode_map(str)
  local data = {}
  
  local n = str:find("-")
  local w = tonumber("0x"..str:sub(1, n-1))
  
  local m = str:find("-", n+1)
  local h = tonumber("0x"..str:sub(n+1, m-1))
  
  str = str:sub(m+1, #str)
  
  local i = 1
  for y = 0, h-1 do
    local line = {}
    for x = 0, w-1 do
      line[x] = hex2dec[str:sub(i,i)]
      i = i+1
    end
    data[y] = line
  end
  
  return data
end


maps = {
  "23-23-222222222222222222222222222222222222222222222222222222222222222222222222299a900a900a9a9aaaaa9a9aaa9a9a9222299a90309a009a9a90109a9aaa9a9aa99222999a00aa9a9aaa9a000a9a9a9a9a77aa2229aa9a9a9a9a9aaa9a9a9a9a9a9aa77a92229a0a9a9a009a9a9a9a9a009a9a99aa9a222a009a9a900a9a00000a900a9a9a9a9a922290009a9a9a9a10aaa00a9a9a9a9a9a9a222a900a9a9a9a009ccc900a9a9a9aaa9a92229a009a00aa90accccca0900a9aaa9a00222a900a90109a0accccca0a010a9a9a9002229a009aa00a90accccca090009a9a9a9a222a000a9a9a9a009ccc900a9a9a9a9a009222900a9a9a9a9a00aaa00a9a9a9a9a010a222a009a9a9a9a9a00000a9a9aaa9a90009222900a9a9a9a9a9a9a9a9a9aa03a9a9a9a222a009a9a9aa00a9a9a9a9a9a00aa9a9a92229a9a9a9a90109a9a9a9a9a9aaa900a9a222a9a9a9a9a00aa9aaaaaaa9a9a9a009a9222000a9a9a9a9a9a0accc9aaaa9a9a9a9a2220809a000a9a9a90accccc9aaa9a9a9a9222000a90809a9a9a0acccccc9aaa9a000a222a9a9a000a9a9a90a9ccccccaa9a0aaa02229a9a9a9a9a9a9a0a999ccccaaa90a9a0222a9a9a9a9a9000900aaaa13aaa9a0aaa02229a9a9a9a9a080a90000000009a9a000a222a00000a9a90009a9a9a9a9a9a9a9a9a92220101010a9a9a9a9a9a9a9a9a9a9a9a9a22200000009a9a9a9a90009a900a009a9a92220101010a9a9a9a9a080a900202009a9a22200000009a9a000a90009a0202020a0092220101010a9a90809a9a9a900202009030222200000a9a9a000a9a9a9a900a009aa02222222222222222222222222222222222222",
  "12-43-2222222222222222222222222222222222222299ccc9aaa9ccc992229cccca070acccc9222ccccca070accccc222cccca00000acccc222caaaa00000aaaac2229aaaaa000aaaaa922299ccaaaaaaacc9922299ccaacccaacc9922299ccaacccaacc9922299ccaacccaacc9922299ccaacccaacc9922299ccaacccaacc9922299ccaacccaacc9922299ccaacccaacc99222a9ccaacccaacc9a2220aaaaacccaaaaa022200000aaaaa000002222000000000000022222222220002222222222222220002222222220000000000022992220000000000022aa222002222222222200222002222222222200222002200000000000222002203aaa90000022200220accca0220022200220ac2ca0220022200220accca02200222000009aaa302200222000000000002200222002222222222200222002222222222200222aa22000000000002229922000000000002222222220002222222222222220002222222222999a00000a999222200000000000000022200220000000220022202220001000222022202220000000222022202220002000222022202290102010922022209900002000099022200000200020000022200010201020100022200000200020000022200000000000000022201000102010001022200000002000000022200202002002020022202202202022022022209202902092029022202202202022022022202909202029092022202202202022022022202a0a20202a0a2022202a8a20202a8a2022202aaa20202aaa202220222220202222202220aa2aa020aa2aa022208a2a80208a2a80222aaa2aaa2aaa2aaa2222222222222222222",
  "26-26-2222222222222222222222222222222222222222222222222222222222222222222222222222220000000000a9999193919999a00000000002220800000000a9ccc9ccc9ccc9a00000000802220022222200a9999999999999a00222222002220022222200aaaaaaaaaaaaaaa00222222002220022000000000000000000000000000220022200220800000000000000000000000802200222002200002222222201022222222000022002220022000002222222000222222200000220022200000020000000000000000000002000000222000000220000000a9a9a0000000220000002222222002200cccccccaccccccc00220022222222222002200cccccccaccccccc00220022222220000802200cc222ccacc222cc00220800002220000002200cc292ccacc292cc00220000002220022222200cc222ccacc222cc0022222200222002222220acccccccaccccccca0222222002220000000009ccccccaaacccccc9000000000222030000100aaaaaaaa7aaaaaaaa0010000302220000000009ccccccaaacccccc9000000000222002222220acccccccaccccccca0222222002220022222200cc222ccacc222cc00222222002220000002200cc292ccacc292cc00220000002220000802200cc222ccacc222cc00220800002222222002200cccccccaccccccc00220022222222222002200cccccccaccccccc0022002222222000000220000000a9a9a0000000220000002220000002000000000000000000000200000022200220000022222220002222222000002200222002200002222222201022222222000022002220022080000cc99cc000cc99cc000080220022200220000000cccc00000cccc0000000220022200222222c00000000c00000000c2222220022200222222c0001000c2c0001000c2222220022208000000000000000c0000000000000008022200000000000000000000000000000000000222222222222222222222222222222222222222",
  "3f-1f-2222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222299a000000000000000008000aa92222229aa000000000000000000000a992220000000100000000000000000009222290000000000000000000100000002220002220002a222222222222222009aa900222222222222222220002220002220002220002a22222222222222220000002222222222222222220002220002220002220002a20000000000000222200222200000000000002220002220002220002220002a2030000000000002220022200000000000030222000222000222000222ccc2a2000202222220022220022222002222222000222cc0aaa000222000222ccc2aa000202222220022220022222002222222000222ccc222000222000222ccc222000200000220000091090000000000222080222ccc2220002220002220002220802220802200000000000000000802220002220002220002220002220002220002220002222222222222222220002222222220002220002220802220002220009a90002222222222222222220002222222220002220002220009a90002220000000002229a9a9229a9a92220002220002220009a90002220300000002222222220000aa010107701010aa00002220802220000000302220000000002222222220000aa000007700000aa00002220002220000000002220009a90002220002220002229a9a9229a9a92220002220002220009a90002220002220002220802220002222222222222222220009a9000222000222000222000222000222000222000222222222222222222000000000222000222000222000222000222000222000000000000000000222000222000222000222000222000222ccc222000222000000000090190000222000222000222ccc222000222000222ccc222000222220022222220022200222222222000222ccc222080222000aaa0cc2220002222200222222200222002222222220002aa0cc222000222000222000222030000000000002220022200000000000030aa20002220002220002220002220000000000000222200222200000000000002a20002220002220002220002222222222222222220000002222222222222222a200022200022200022200022222222222222222009aa900222222222222222a200022200022200000001000000000000000000092222900000000000000000001000000022299a000000000000000000000aa92222229aa000000000000000000000a992222222222222222222222222222222222222222222222222222222222222222",
  "3f-1f-2222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222299a000000000000000008000aa92222229aa000000000000000000000a992220000000100000000000000000009222290000000000000000000100000002220002220002a222222222222222009aa900222222222222222220002220002220002220002a22222222222222220000002222222222222222220002220002220002220002a20000000000000222200222200000000000002220002220002220002220002a20300000000000022200222000000000000302220002220002220002220002a2000202222220022220022222002222222000222000aaa0002220002220002aa0002022222200222200222220022222220002220002220002220002220002220002000002200000910900000000002220802220002220002220002220002220802220802200000000000000000802220002220002220002220002220002220002220002222222222222222220002222222220002220002220802220002220009a90002222222222222222220002222222220002220002220009a90002220000000002229a9a9229a9a92220002220002220009a90002220300000002222222220000aa010107701010aa00002220802220000000302220000000002222222220000aa000007700000aa00002220002220000000002220009a90002220002220002229a9a9229a9a92220002220002220009a90002220002220002220802220002222222222222222220009a9000222000222000222000222000222000222000222222222222222222000000000222000222000222000222000222000222000000000000000000222000222000222000222000222000222000222000222000000000090190000222000222000222000222000222000222000222000222220022222220022200222222222000222000222080222000aaa0002220002222200222222200222002222222220002aa000222000222000222000222030000000000002220022200000000000030aa20002220002220002220002220000000000000222200222200000000000002a20002220002220002220002222222222222222220000002222222222222222a200022200022200022200022222222222222222009aa900222222222222222a200022200022200000001000000000000000000092222900000000000000000001000000022299a000000000000000000000aa92222229aa000000000000000000000a992222222222222222222222222222222222222222222222222222222222222222",
  "7f-47-22222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222200000000000000000000000000000000000022222222222222222222222222222222222222222222222220000000000000000000000002222222222222222222902290229022902200220922092209220922222222222222222220000000000000000000000002222220000000000000000000000000000000000000000000000000000000000003000000000000000000000000000000000000000000000000200000000000022222000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000222222222222222000002222200022000000020000000220002222222222222222222222222222222222200222222222222222222222222222222222220000222222222222222220000222220002200009022209000022000222222222222222222222222222222222220022222222222222222222222222222222222909a22200002220000222a9092222200000020000222000020000002220000000000000000220000000000002200090909000000000000900900000000002229009220000002000000229009222220000000022022202200000000220800000000000000022080000000080220000000000000000000000000000000000022a90922000000000000022909a2222200000020000222000020000002200022222222222222220022222222002222222222222222222222200222222222000220000200002000002000020000222220002200010222220100022000229092222222222222222002222222200222222222222222222222220022222222290922000000010200000201000000022222000220000022222000002200022000222000000000000000000000000000100000000000800000000000000002220002200000000020000020000000002222200000020000222000020000002200022000000000000000000000000000000000000000000000000000000000022000220000200002000002000020000222220000000022022202200000000220002200022222220022222222222222222222222222222222222222222220002200022a90922000000000000022909a2222200000020000222000020000002200022909222222200222222222222222222222222222222222222222222290922000229009220000002000000229009222220002200009022209000022000220002200022200000008022000000000009009000000000000000000002220002200022909a22200002220000222a9092222200022000000020000000220002200022000220300000000220000000000000000000000000000000000302200022000220000222222222222222220000222220000000000000000000000000220002200022000222222222220222222222002222222222200222222000220002200022000002222222222222220000022222000009090900000090909000022000220002200022222222220022222222200222222222220022222200022000220002200000000000020000000000002222200000a00000000000000a000022000220002200000000000009220800000000000000080220000022200022000220002200009a9a9a90009a9a9a0000022222000009000000100000009000022000220002200000000000000220000000000000000000220000002200022000220002200000000000000000000000002222200000a00000000000000a00002200022000220002200022002222222222222222222222222222000220900000022080220000000000001000000000000222220000090900000000009090000220002200022080220002200222222222222222222222222222200022000000002200022000000000000000000000000022222000000000000000000000000022000220002200022000220000000000000000000000000002220002222222000220002200000000000000000000000002222200000a9a9a90009a9a9a9000022000220002200022000220000000000000000000000000000220002222222000222222200009a9a9a90009a9a9a00000222220300000000000000000000000220002200022222220002222222222222222222220022220002200022000220002222222000000000000000000000003022222000022222222022222222200022909220002222222000222222222222222222222002222000220002208022000000002200022222222202222222200002222200002000000000000200020002200000000220002200022200000000000000000000022200022000220002200000000220002000000000200000020000222220000202222222222020202000220000000022080220002208000000000090090000000220802200022000220002200022000202222202220222202000022222a900222000002000000202000222222200022000220002200022909222220022222909220002200022000220002200022000200000200000200202009a222220000200022202022222202000222222200022000000002200022000222220022222000220002200022000000002200022000222220222222220202000022222009a202020000000020202000220002200022090000000000022000222a9009a222000220002200022000000002200022000200020200000000202a90022222000020202022222202020200022080220002200022000220002200022a000000a22000220002200022000220802290922000202020222222020202000022222a900202220210012220002000220002200022000220002200022000229010010922000220002200022000220002200022000222022210012020202009a2222200092020202000000222020002200000010220002200022000220300000000000000302200022000220102200022000220002000200000020200029000222220009200022200002020202000220000000022000220802200022000000000000000000220000000022000222222200022000202220200002022202900022222a900222020210012000202000220002200022000229092200022000229010010922000220900009022000222222200022000202000210012000202009a22222000020002022222222020200022000220002200022000220002200022a000000a22000220002200022000220002200022000202022222222020202000022222009a202020000000020202000220002290922000222222200022000222a9009a222000222222222222000220802200022000200020000020020202a900222220000202022022222020202000000002200022000222222200022000222220022222000222222222222000220000000022000202020222022220202000022222a900202000000002000202000220002200022000220002200022909222220022222909220900009022000220000000022000222000002000000202009a22222000020222222222222220200022000220002200022989220002200000009009000000022000000002200022000220002200020222220222222220200002222200002000002000000000020002200022000220002200022000222000000000000000022200022000220002200022000220002000000020000000020000222220000222222220222222222000220002208022000220002200022222200222222222222220002200022000220002208022000222222222022222222000022222030000000000000000000000022000220002200022000220002222220022222222222222000220002200000000220002200000000000000000000000302222200009a9a9a90009a9a9a900002200022000220002200022080000000000000002200000008022000220000000022000220000009a9a90009a9a90000002222200000000000000000000000002200022222220002200022200000000000000002200000000222000220002200022222220000900000009000000090000222220000900a009000900a00900002200022222220000000022222220022222222222222222222222000220002200022222220000000000000000000000000222220000a00900a010a00900a00002200022000000000000022222220022222222222222222222222000220802200022000220090009000900090009000900222220000900a009000900a00900002200022080000002200000000000022900000000000000000000000220002200022080220000000000000000000000000222220000a00900a000a00900a0000220002200022222222000000000002200000000000000000000000222000220000000022000090009000100090009000022222000000000000200000000000022000229092222222222222222222220022222222222222222222222222222000000002200000000000000000000000002222200000222222222222222000002200022000220002222222222222222002222222222222222222222222222200022000220022009000900090009002200222220000222222222222222220000220000000022030000000000000000000000009090909090909090900030220002200022002200000000200000000220022222909a22200002220000222a9092200000000222000000000000002200000000000000000000000000000002200022000220000002002022202002000000222229009220000002000000229009220002200022222222222200222222222222222222222222222222222202220002200022000002000002220000020000022222a90922002200000220022909a2200022000222222222222002222222222222222222222222222222222022200022000220000000220022200220000000222220000220000000000000220000220002200000000002200000000000000000100002208000000000000000000002200022000020222202220222202000022222000000001000200010000000022000222000000000220000000000000000000000220000000000000000000002220002200000020122222221020000002222200000000000020000000000002290922222222220022222222222222222222220022222222222222222222222222909220000000002222222000000000222220000220000000000000220000220002222222222002222222222222222222222002222222222222222222222222200022000020222202220222202000022222a90922002200000220022909a2208000002200000000000000000090909000220000080000000000000000000000000220000000220022200220000000222229009220000002000000229009222000000220000000000000000000000000022000000000000000000000000000000222000002000002220000020000022222909a22200002220000222a909222222222222222222222222222222222220022222222222222222222222222222222222000000200202220200200000022222000022222222222222222000022222222222222222222222222222222222002222222222222222222222222222222222200220000000020000000022002222200000222222222222222000000000000000000000000000000000000000000000000000000000000000000000000000000022000000900090000002200222220000000000002000000000000000000000000000000000000000000000000300000000000000000000000000000000000000000000000000000000000022222200000000000000000000000022222222222222222229022902290229022002209220922092209222222222222222222200000000000000000000000022222222222222222222222222222222222222222222222220000000000000000000000000000000000002222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222",
}