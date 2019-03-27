
destroyable_list = {} -- { id : destroyable }
local destroyable_nextid = 1

flower_colors = {12,8,13,8,13,12}

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
    skin                = 0,
    typ                 = 0,
    faceleft            = chance(50)
  }
  
  s.typ = irnd(6)
  s.skin = 420 + (s.typ-1)*2
  
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
  palt(1,true)
  palt(6,false)

  if s.white_frame > 0 then
    all_colors_to(14)
    spr(s.white_skin, s.x, s.y-1, 2, 2, 0, s.faceleft)
    all_colors_to()
  else
    spr(s.skin, s.x, s.y-1, 2, 2, 0, s.faceleft)
  end
  
  palt(1,false)
  palt(6,true)
end

function kill_destroyable(s, killer_id)
  if s.alive then
    sfx("cactus_hit", s.x, s.y, 0.9+rnd(0.2))
    s.white_frame = 0.05
    s.white_skin = s.skin
    s.alive = false
    s.skin = 416 + (irnd(2)-1)*2
    s.t_respawn = 10 + rnd(5)
    s.killer = killer_id
    
    local c = flower_colors[s.typ]
    local k = 4+irnd(3)
    for i=1,k do
      create_leaf(s.x, s.y, c, c_drk[c])
    end
    
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
    s.skin = 420 + (s.typ-1)*2
    s.killer = nil
    s.white_frame = 0.1
    s.white_skin = s.skin
  end
end