
require("input")

player_list = {} -- { id : player }
-- last_pickup_crown = nil -- timestamp to compare and count points for the currently crowned player

old_scores = {}

death_history = {
                  kills = {}, -- { killed = killed.name , killer = killed.name, count } 
                  last_victim = {}, -- { killed = killed.name , killer = killed.name }
                  last_killer = {} -- { killed = killed.name , killer = killed.name }
                }

function create_player(id,x,y)
  
  local s = {
    id                  = id,
    name                = "",
    hp                  = 10,
  
    animt               = 0,
    anim_state          = "idle",
    hit_timer           = 0,
    flash               = false,
    update              = update_player,
    update_movement     = update_movement,
    draw                = draw_player,
    regs                = {"to_update", "to_draw0", "player"},
    alive               = true,
    dead_sfx_player     = false,
    score               = old_scores[id] or 0,
    bounce              = false,
    last_killer_name    = "accident",
    last_killer_id      = "accident",
    last_hit_bullet     = -1,
    
    w                   = 6,
    h                   = 7,
    
    timer_fire          = 0, -- cooldown (seconds) left for bullet fire
    weapon_id           = 1,
    ammo                = 0,
    rafale_on           = false,
    rafale_shot         = 0, -- keep tracks of how many the bullets the player shot this rafale
    
    v                   = { x = 0, y = 0 },-- movement vector 
    angle               = 0,
    speed               = 0,
    
    skin                = pick{13, 11, 7, 3, 0},
    
    -- { killed_by = {name : count}, killed = {name : count}, last_killer = player.name, last_killed = player.name}
    
    
    --network stuff
    dx_input            = 0,
    dy_input            = 0,
    shot_input          = false,
    diff_x              = 0,
    diff_y              = 0,
    moved_t             = 0,
    server_death        = false
    --
  }
  
  if not id then
    castle_print("/!\\ Creating a player with no id.")
  end
  
  player_list[s.id or 0] = s
  
  
  if x and y then
    s.x = x
    s.y = y
  else
    q = get_spawn()
    
    s.x = q.x
    s.y = q.y
  end
  
  
  register_object(s)
  if my_id == s.id then sfx("startplay", s.x, s.y) end
  
  if not server_only then
    local cs = s.id == my_id and {14,12,9} or {14,11,7}
    for i=1,16 do
      create_smoke(s.x, s.y, 0.75, 1+rnd(1.5), pick(cs))
    end
  end
  
  return s
end

function update_player(s)
  -- cooldown firing gun
  s.timer_fire = s.timer_fire - delta_time
  
  -- change anime time
  s.animt = s.animt - delta_time
  if s.hit_timer > 0 then s.hit_timer = s.hit_timer - delta_time end
 
  -- debuggg = s.hp .. " / 10"
  
  
  if crowned_player == s.id and s.alive then add_score(s) end
  
  if s.hp > 11 then s.hp = s.hp - delta_time/2 end -- slow decrease of health according to time if above the 10 maximum
  
  if s.id == my_id and s.server_death and s.animt < -1.5 and querry_menu() == nil and not (restarting or not connected) then
    game_over()
  end
  
  if s.id == my_id and s.server_death and s.animt < 0 then
    if s.animt < -1.5 and querry_menu() == nil and not (restarting or not connected) then
      game_over()
    end
  end

  s:update_movement()
  
  return
end

function update_movement(s)
  
  if s.id == my_id and not in_pause then
    if s.alive and s.speed > 0.5 then
      local a,b,c = anim_step("player", "run", s.animt)
      if b and a%8 == 1 then
        sfx("steps", s.x, s.y, 1+rnd(0.2))
      end
    end
  
    s.dx_input = 0
    s.dy_input = 0
    
    -- gets angle
    -- move cam
    cam.follow = {x = lerp(s.x+s.diff_x, cursor.x, .25), y = lerp(s.y+s.diff_y, cursor.y, .25)}
        
    get_inputs(s)
    
    if s.shot_input then
      client_shoot()
    end
  end
  
  if server_only or s.id == my_id then
    
    -- MOVEMENT
    
    local delta_time = delta_time
    if s.delay then
      delta_time = delta_time + 0.5 * delay
    end
    
    update_vec(s, delta_time)    
    
  else
      -- we need the speed to figure out state on draw_player
    s.speed = dist(s.v.x, s.v.y)
  
  end
  
  if not server_only then
    if s.id == my_id then
      
      if abs(s.dx_input) + abs(s.dy_input) > 0 then
        s.moved_t = delay*4
      else
        s.moved_t = max(s.moved_t - delta_time, 0)
      end
      
      local max_speed = player_const.max_speed
      
      local dd = mid(1 - (s.speed / max_speed) - (s.moved_t/delay*4-3), 0, 1)
      
      local odx, ody = s.diff_x, s.diff_y
      
      s.diff_x = lerp(s.diff_x, 0, (dd + 0.01) * 10 * delta_time)
      s.diff_y = lerp(s.diff_y, 0, (dd + 0.01) * 10 * delta_time)
      
      local diff_x = s.diff_x-odx
      local diff_y = s.diff_y-ody
      local ndiff = dist(diff_x, diff_y)
      if ndiff > max_speed*0.5 then
        diff_x = diff_x / ndiff * max_speed*0.5
        diff_y = diff_y / ndiff * max_speed*0.5
        s.diff_x = odx + diff_x
        s.diff_y = ody + diff_y
      end
      
      s.speed = dist(s.v.x + diff_x, s.v.y + diff_y)
    else
      s.diff_x = lerp(s.diff_x, 0, 20*delta_time)
      s.diff_y = lerp(s.diff_y, 0, 20*delta_time)
    end
  end
  
  -- translate vector to position according to delta (30 fps)
  apply_v_to_pos(s)
  
  check_firing(s)
  
end

function get_inputs(s)
  if s.alive then
    -- left   = 0
    -- right  = 1
    -- up     = 2
    -- down   = 3
    s.angle = atan2(cursor.x - s.x, cursor.y - s.y)
    if btn(0) then s.dx_input =             -1 end
    if btn(1) then s.dx_input = s.dx_input + 1 end
    if btn(2) then s.dy_input =             -1 end
    if btn(3) then s.dy_input = s.dy_input + 1 end
    
    if btn(6) then 
      -- spawn_weapon(s, 3)
      loot_crown(s)
    end
    
    s.shot_input = mouse_btnp(0) or s.rafale_on
  end
end

function update_vec(s, delta_time)
    
  local acc = player_const.acceleration * delta_time * 10
  local dec = player_const.deceleration * delta_time * 10
  
  if server_only then
    acc = acc * 1.25
    dec = dec * 1.25
  else
    acc = acc * 0.75
    dec = dec * 0.75
  end
  
  -- decelerate speed every frame
  if s.v.x > dec*1.3 then
    s.v.x = s.v.x - dec
  elseif s.v.x < - dec * 1.3 then
    s.v.x = s.v.x + dec
  else
    s.v.x = 0
  end
  
  if s.v.y > dec * 1.3 then
    s.v.y = s.v.y - dec
  elseif s.v.y < - dec * 1.3 then
    s.v.y = s.v.y + dec
  else
    s.v.y = 0
  end
  
  -- accelerate on input
  s.v.x = s.v.x + acc * s.dx_input
  s.v.y = s.v.y + acc * s.dy_input
     
  collide_with_dest(s, acc)  
  collide_with_enemy(s, acc)  
  
  cap_speed(s)
  
end

function cap_speed(s)
  s.speed = dist(s.v.x, s.v.y)
  local max_speed = player_const.max_speed
  
  if s.speed > max_speed then
    s.v.x = s.v.x / s.speed * max_speed
    s.v.y = s.v.y / s.speed * max_speed
    s.speed = max_speed
  end
end

function collide_with_dest(s, acc)
  local destroyable = collide_objgroup(s,"destroyable")
  if destroyable and destroyable.alive then  -- Remy was here: made this use delta time (and acceleration)
    s.v.x = s.v.x + sgn(s.x - destroyable.x) * acc * 0.5
    s.v.y = s.v.y + sgn(s.y - destroyable.y) * acc * 0.5
  end
end

function collide_with_enemy(s, acc)
  local enemy = collide_objgroup(s,"enemy")
  if enemy and enemy.alive then  -- Remy was here: made this use delta time (and acceleration)
    s.v.x = s.v.x + sgn(s.x - enemy.x) * acc * 0.5 * 2
    s.v.y = s.v.y + sgn(s.y - enemy.y) * acc * 0.5 * 2
  end
end

function apply_v_to_pos(s)
  -- client syncing stuff
  local apply_diff = (s.id == my_id and abs(s.dx_input) + abs(s.dy_input) > 0)
  if apply_diff then
    s.x, s.y = s.x + s.diff_x, s.y + s.diff_y
  end
  
  -- actual move update
  local nx = s.x + s.v.x * delta_time * 10
  local col = check_mapcol(s,nx)
  if col then
    local tx = flr((nx + col.dir_x * s.w * 0.5) / 8)
    s.x = tx * 8 + 4 - col.dir_x * (8 + s.w + 0.5) * 0.5
    
    --col = check_mapcol(s,nx,nil,true) or col
    --s.v.y = s.v.y - 1* col.dir_y * s.acceleration * delta_time * 10
    s.y = s.y - 1* col.dir_y * delta_time * 20
  else
    s.x = nx
  end
  
  local ny = s.y + s.v.y * delta_time * 10
  local col = check_mapcol(s,nil,ny)
  if col then
    local ty = flr((ny + col.dir_y * s.h * 0.5) / 8)
    s.y = ty * 8 + 4 - col.dir_y * (8 + s.h + 0.5) * 0.5
    
    --col = check_mapcol(s,nil,ny,true) or col
    --s.v.x = s.v.x - 1* col.dir_x * s.acceleration * delta_time * 10
    s.x = s.x - 1* col.dir_x * delta_time * 20
  else
    s.y = ny
  end
  
  -- more client syncing bullshit
  if apply_diff then
    s.x, s.y = s.x - s.diff_x, s.y - s.diff_y
  end
end

function check_firing(s)
  
  if ( server_only or s.id == my_id ) and s.shot_input then
    if s.timer_fire < 0 then
    
      fire(s)
      
      add_shake()
    else
      sfx("cant_shoot", s.x, s.y)
    end
  end
end

function fire(s)

  type = s.weapon_id
  weapon_const.fire_mod[type](s)
  if s.ammo < 1 and s.weapon_id ~= 1 then  set_default_weapon(s) end
  s.timer_fire = weapon_const.fire_rate[type]

end

function update_mov_bullet_like(s)
  if not server_only and s.id == my_id then cam.follow = {x = lerp(s.x+s.diff_x, cursor.x, .25), y = lerp(s.y+s.diff_y, cursor.y, .25)} end
  
  -- client syncing stuff
  s.diff_x = lerp(s.diff_x, 0, 20*delta_time)
  s.diff_y = lerp(s.diff_y, 0, 20*delta_time)
  s.x, s.y = s.x + s.diff_x, s.y + s.diff_y
  
  -- actual move update
  local nx = s.x + s.v.x * delta_time * 10
  local col = check_mapcol(s,nx)
  if col then
    local tx = flr((nx + col.dir_x * s.w * 0.5) / 8)
    s.x = tx * 8 + 4 - col.dir_x * (8 + s.w + 0.5) * 0.5
    s.v.x = s.v.x *-1
    s.speed = s.speed * .9 -- Remy was here: made bullet lose lifetime on bounce
  else
    s.x = nx
  end
  
  local ny = s.y + s.v.y * delta_time * 10
  local col = check_mapcol(s,s.x,ny)
  if col then
    local ty = flr((ny + col.dir_y * s.h * 0.5) / 8)
    s.y = ty * 8 + 4 - col.dir_y * (8 + s.h + 0.5) * 0.5
    s.v.y = s.v.y *-1
    s.speed = s.speed * .9
  else
    s.y = ny
  end
  
  -- more client syncing bullshit
  s.x, s.y = s.x - s.diff_x, s.y - s.diff_y
  
  s.speed = dist(s.v.x, s.v.y)
  if s.speed > 0 then
    local nspeed = max(s.speed - 10*delta_time, 0)
    s.v.x = lerp(s.v.x/s.speed*nspeed, 0, 0.8*delta_time)
    s.v.y = lerp(s.v.y/s.speed*nspeed, 0, 0.8*delta_time)
    s.speed = nspeed
  end
end

function draw_player(s)
  
  local flash = s.hit_timer > 0.1
  if flash then
    all_colors_to(14)
  end 
    
  -- if s.id == my_id then
    -- debuggg = tostring(s.hp) end
    
  local x = s.x + s.diff_x
  local y = s.y + s.diff_y

  local state = "idle"
  local a = cos(s.angle) < 0
  local animt = s.animt * (s.v.x > 0 == a and 1 or -1)
  
  if s.alive then
    if s.hit_timer > 0 then
      state = "hurt"
    elseif s.speed > 0.5 then
      state = "run"
    end
  else
    if s.animt > 0 then
      state = "hurt"
    else
      state = "dead"
    end
  end
  
  palt(6,false)
  palt(1,true)
  pal(7,flash and 14 or s.skin)
  
  if s.id ~= my_id then
    pal(9,8)
    pal(12,11)
  end
  
  if state ~= "dead" then
    -- drawing body outline
    draw_anim(x, y-2, "player", state, animt, 0, a)
    
    -- drawing arm + gun
    --spr(200, x, y-1.5, 1, 1, s.angle, false, a, 1/8, 5/8)
    spr(weapon_const.sprites[s.weapon_id], x, y-1.5, 1, 1, s.angle, false, a, 1/8, 5/8)
    
    -- drawing rest of body
    palt(6,true)
    draw_anim(x, y-2, "player", state, animt, 0, a)
    palt(6,false)
    
    if crowned_player == s.id then
      draw_player_crown(s, x, y)
    end
    
  else
    -- drawing body outline
    spr(142, x, y-1, 2, 2, 0)
    
    -- drawing arm + gun
    spr(weapon_const.sprites[s.weapon_id], x, y-1.5, 1, 1, s.angle, false, a, 1/8, 5/8)
    
    -- drawing body
    palt(6,true)
    spr(142, x, y-1, 2, 2, 0)
    palt(6,false)
  end
  
  -- syncing debug
  if debug_mode then
    all_colors_to(14)
    --if s.id == my_id then
    --  draw_anim(s.rx, s.ry-2, "player", state, s.animt * (s.v.x > 0 == a and -1 or 1), 0, 0, a)
    --else
      draw_anim(s.x, s.y-2, "player", "run", s.animt * (s.v.x > 0 == a and -1 or 1), 0, 0, a)
    --end
    all_colors_to()
  end
  
  palt(1,false)
  palt(6,true)
  pal(7,7)
  
  if s.id ~= my_id then
    pal(9,9)
    pal(12,12)
  end
  
  if flash  then
    all_colors_to()
  end
  
end

function hit_player(s, id_attacker, bullet, enemy)
  
  if server_only then
    if bullet and s.last_hit_bullet ~= bullet.id then
      s.hp = s.hp - get_damage_from_type(bullet.type)
      s.last_hit_bullet = bullet.id
    else
      s.hp = s.hp - 1
    end
  end
  
  if s.hp < 1 then
    s.hp = 0
    local killer = bullet or enemy or { v = {x = s.x, y = s.y}}
      
    send_player_off(s, killer.v.x, killer.v.y )
      
    kill_player (s, id_attacker) 
  end
  
  s.hit_timer = player_const.hit_time
end

function get_damage_from_type(typeb)
  local dmg = weapon_const.damage[typeb]
  if not dmg then return 1 end
  return weapon_const.damage[typeb]
end

function kill_player(s, id_killer)
  
  s.alive = false
  s.score = math.floor(s.score)
  old_scores[s.id] = s.score
  if crowned_player == s.id then loot_crown(s) end
  s.animt = player_const.t_death_anim
  s.update_movement = update_mov_bullet_like
  
  if id_killer then
    local p = player_list[id_killer]
    
    if p then
      s.last_killer_name = p.name
    end
  end
  if s.id == my_id then
    add_shake(5)
    sfx("get_hit_player", s.x, s.y) 
  else
    sfx("get_hit", s.x, s.y) 
  end
  
end

function loot_crown(s)
  crowned_player = nil
  create_loot(0, 0, s.x + 10 , s.y) -- create_loot(id, type, x, y, weapon_id)
end

function send_player_off(s, vx, vy) -- bullet to player vector

  s.bounce = true

  s.v.x = 30 * vx
  s.v.y = 30 * vy
  
end
    
function resurrect(s)
  s.alive = true
  s.server_death = false
  s.update_movement = update_movement
end

function add_death(victim, killer) -- two players

  
  if(death_history) then
    local lcount = 1
    local death = {}
    
    for i,v in pairs(death_history.kills) do
      if (v.killer == killer.id) and (v.victim == victim.id) then
        lcount = lcount + 1 
      end
    end
    
    lcount = lcount
    death = { victim = victim.id , killer = killer.id, count = lcount}
    add( death_history.kills, death)
    
    ----------
    local found = false
    
    for i,v in pairs(death_history.last_victim) do
    
      if v.killer == killer.id then
        v.victim = victim.id 
      end
      
    end
    
    if not found then death_history.last_victim[killer.id] = death end
    
    ----------
    
    found = false
    
    for i,v in pairs(death_history.last_killer) do
    
      if v.victim == victim.id then
        v.killer = killer.id 
        found = true
      end
    end
    if not found then death_history.last_killer[victim.id] = death end
    add_score(killer)
    
  end
end

function add_score(s)
  s.score = s.score + delta_time
end

function draw_player_crown(s, x, y)
  x = x or s.x
  y = y or s.y
--  rectfill(x, y , x + 2, y + 6 , 1)
  
  local dy = -10+cos(s.animt*0.5)

  spr(224, x, y+dy)
end

function draw_player_names()
  local c0,c1,c2 = 14,8,6
  local cm0,cm1,cm2 = 14,9,6 -- when your player
  local cd0,cd1,cd2 = 8,0,6 -- when player dead
  
  for s in group("player") do
    local x = s.x + s.diff_x
    local y = s.y + s.diff_y
  
    local str = s.name or ""
    if not s.alive and s.animt < 0 then
      draw_text(str, x, y+6, 1, cd0,cd1,cd2)
    elseif s.id == my_id then
      draw_text(str, x, y+6, 1, cm0,cm1,cm2)
    else
      draw_text(str, x, y+6, 1, c0,c1,c2)
    end
  end
end

function spawn_weapon(s, weapon_id)
  -- weapon_id = weapon_id
  create_loot(0, 0, s.x + 10 , s.y, weapon_id) -- create_loot(id, type, x, y, weapon_id)
end

function set_default_weapon(s)
  s.weapon_id = 1
  s.ammo = 0
  s.rafale_on = false
  s.rafale_shot = 0
end

player_const = {
  t_death_anim        = .245 * 2,
  time_fire           = .1, -- max cooldown (seconds)  for bullet fire
  max_speed           = 7.0,
  deceleration        = 4.5,
  acceleration        = 8,
  hit_time = .15
}

weapon_const = {
  names           = {"Pistol", "Shotgun", "Assault Rifle", "Grenade Launcher", "Heavy Rifle"},
  loot_sprites    = {112   , 113 , 114 , 116 , 116    },
  sprites         = {120   , 121 , 122 , 124 , 124    },
  fire_rate       = {.1    , .6  , .05 , 1.3 , 1.3    },
  ammo            = {0     , 12  , 30  , 5   , 5      },
  damage          = {1     , 4                  },
  explosion_range =  20 ,
  bullet_type     = {1     , 1   , 1   , 2   , 2      },
  fire_mod        = { -- 1
                    function (s)
                      local b = create_bullet(s.id)
                      b.type = weapon_const.bullet_type[1]
                    end
                    ,
                    -- 2 
                    function (s)
                      local angle = s.angle
                      local open = .05
                      local m = min ( 4, s.ammo)
                      local i = 0
                      
                      while i < m do
                        s.ammo = s.ammo - 1
                        s.angle = angle - open + rnd(open*2*100)/100
                        local b = create_bullet(s.id)
                        b.type = weapon_const.bullet_type[2]
                        b.speed = b.speed * rnd(1, 2)
                        i = i + 1
                      end        
                      
                      s.angle = angle 
                    end
                    ,
                    -- 3 
                    function (s)
                      s.rafale_on = true
                      local angle = s.angle
                      s.ammo = s.ammo - 1
                      
                      if s.rafale_shot < 3 then
                      
                        s.angle = angle + 0.05 *  rnd(-1, 1)
                        local b = create_bullet(s.id)
                        b.type = weapon_const.bullet_type[3]
                        s.rafale_shot = s.rafale_shot + 1
                        
                        if s.rafale_shot == 3 then 
                          s.rafale_on = false
                          s.rafale_shot = 0
                        end
                        
                        s.angle = angle 
                      end
                    end
                    ,
                    -- 4 
                    function(s)
                      s.ammo = s.ammo - 1
                      b = create_bullet(s.id)
                      b.speed = b.speed * 2.5
                      b.time_despawn = 0.8 * 2.5
                      b.type = weapon_const.bullet_type[4]
                    end
                    ,
                    -- 5 
                    function(s)
                      s.ammo = s.ammo - 1
                      b = create_bullet(s.id)
                      b.speed = b.speed * 2.5
                      b.time_despawn = 0.8 * 2.5
                      b.type = weapon_const.bullet_type[4]
                    end
                  }
}


