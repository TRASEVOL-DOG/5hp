-- --enemies

-- --enemies are player that have auto behavior and no input check

-- --go to player

enemy_list = {} -- { id : enemy }
local enemy_nextid = 1
              
enemy_const = {
  visible_range = 20,
  hit_time = .05
}

function create_enemy(id, x, y, vx, vy, alive, angle, hp, behavior)
  
  local s = {
    id                  = id,
    update              = update_enemy,
    draw                = draw_enemy,
    regs                = {"to_update", "to_draw0", "enemy"},
    behave              = idle,
    v                   = { x = vx or 0, y = vy or 0 },-- movement vector 
    alive               = alive or true,
    angle               = angle or 0,
    hp                  = hp or 1,
    behavior            = behavior or "idle",
    
    animt               = 0,
    hit_timer           = 0,
    anim_state          = "idle",
    dead_sfx_player     = false,
    bounce              = false,
    
    w                   = 6,
    h                   = 4,
    
    timer_fire          = 0, -- cooldown (seconds) left for bullet fire
    
    speed               = 0,
    
    -- network stuff
    dx_input            = 0,
    dy_input            = 0,
    shot_input          = false,
    diff_x              = 0,
    diff_y              = 0,
    moved_t             = 0,
    server_death        = false
    
  }
  
  if not id then
    castle_print("/!\\ Creating an enemy with no id.")
  end
  
  if behavior == "idle" then behave = idle end
  
  if id then -- assigned by server
    if enemy_list[id] then
      deregister_object(enemy_list[id])
    end
  
    s.id = id
    enemy_nextid = max(enemy_nextid, id + 1)
    
  elseif server_only then -- assigning id now
    s.id = enemy_nextid
    enemy_nextid = enemy_nextid + 1
  end
  
  if s.id then
    enemy_list[s.id] = s
  end
  
  s.x = x or 0
  s.y = y or 0

  register_object(s)
  
  if not server_only then
    for i=1,16 do
      create_smoke(s.x, s.y, 0.75, 1+rnd(1.5), pick{1,2,3})
      -- create_explosion(s.x, s.y, 10+rnd(1.5), pick{1,2,3})
    end
  end
  
  return s
end

function update_enemy(s)
  -- behave
  s.behave(s)
  
  -- cooldown firing gun
  s.timer_fire = s.timer_fire - delta_time
  if s.hit_timer > 0 then s.hit_timer = s.hit_timer - delta_time end
  
end

function draw_enemy(s)
  if s.hit_timer > 0 then
    rectfill(s.x, s.y , s.x + s.w, s.y + s.h, 3)  
  else
    rectfill(s.x, s.y , s.x + s.w, s.y + s.h, 1)  
  end
end

function hit_enemy(s)
  s.hp = s.hp - 1
  s.hit_timer = enemy_const.hit_time
  if s.hp < 1 then kill_enemy(s) end

end

function idle(s)
end

function kill_enemy(s)

  if not server_only then
    for i=1,16 do
      -- function create_smoke(x,y,spd,r,c,a)
      -- function create_explosion(x,y,r,c)
      create_smoke(s.x, s.y, 0.75, 1+rnd(1.5), pick{1,2,3})
      -- create_explosion(s.x, s.y, 10+rnd(1.5), pick{1,2,3})
    end
  end
  sfx("get_hit", s.x, s.y) 
  
  enemy_list[s.id] = nil
  deregister_object(s)
  
end
