
destroyable_list = {} -- { id : destroyable }
local destroyable_nextid = 1

function create_destroyable(id, x, y)
  local s = {
    w                   = 6,  -- Remy was here: moved w and h and lowered them both
    h                   = 6,
    update              = update_destroyable,
    draw                = draw_destroyable,
    regs                = {"to_update", "to_draw0", "destroyable"},
    alive               = true,
    killer              = nil,
    t_respawn           = 0,
    white_frame         = 0,
    white_skin          = 0,
    skin                = 0 -- 48 ~ 48 + 3 and 54 -- 48 + 4 ~ 48 + 6 and 55
  }
  
  s.skin = 47 + irnd(6)
  
  -- setting position
  if x and y then  -- position is provided by server
    s.x = flr(x)
    s.y = flr(y)
  else             -- seeking position
    q = get_spawn()
    if q == nil then
      return
    end
    s.x = (q.x)
    s.y = (q.y)
  end
  
  -- setting id
  if id then -- assigned by server
    if destroyable_list[id] then
      deregister_object(destroyable_list[id])
    end
  
    s.id = id
    destroyable_nextid = max(destroyable_nextid, id + 1)
    
  else       -- assigning id now - probably running server
    s.id = destroyable_nextid
    destroyable_nextid = destroyable_nextid + 1
  end
  destroyable_list[s.id] = s
  
  
  register_object(s)
  
  return s
end

function update_destroyable(s)
  if server_only and not s.alive then
    s.t_respawn = s.t_respawn - delta_time 
    if s.t_respawn < 0 then respawn_destroyable(s) end
  end
  
  if s.white_frame > 0 then
    s.white_frame = s.white_frame - delta_time
  end
end

function draw_destroyable(s)
  if s.white_frame > 0 then
    all_colors_to(3)
    spr(s.white_skin, s.x-1, s.y-2)
    spr(s.white_skin, s.x+1, s.y-2)
    spr(s.white_skin, s.x, s.y-3)
    spr(s.white_skin, s.x, s.y-2)
    all_colors_to()
  else
    all_colors_to(0)
    spr(s.skin, s.x-1, s.y-2)
    spr(s.skin, s.x+1, s.y-2)
    spr(s.skin, s.x, s.y-3)
    all_colors_to()
    pal(1,0)
    spr(s.skin, s.x, s.y-2)
    pal(1,1)
  end
end

function kill_destroyable(s, killer_id)
  if s.alive then
    sfx("cactus_hit", s.x, s.y, 0.9+rnd(0.2))
    s.white_frame = 0.05
    s.white_skin = s.skin
    s.alive = false
    s.skin = (s.skin < 52) and 54 or 55
    s.t_respawn = 10 + rnd(5)
    s.killer = killer_id
    
    if killer_id then
      local b = bullet_list[killer_id]
      if b then
        kill_bullet(b)
      else
        dead_bullets[killer_id] = true
      end
    end
  end
end

function respawn_destroyable(s)
  if not s.alive then
    s.alive = true
    s.skin = 47 + irnd(6)
    s.killer = nil
    s.white_frame = 0.1
    s.white_skin = s.skin
  end
end