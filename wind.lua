
windgoright = false

function create_wind()
 local s = {
    animt               = 0,
    anim_state          = "a",
    update              = update_wind,
    draw                = draw_wind,
    flipx               = 0,
    flipy               = 0,
    regs                = {"to_update", "to_draw0", "wind"},
    alive               = true,
    skin                = 0 -- 48 ~ 48 + 3 and 54 -- 48 + 4 ~ 48 + 6 and 55
  }
  
  local found = false
  local scrnw,scrnh = screen_size()
  local mx,my = get_camera_pos()
  while not found do
    if chance(5) then return end
    s.x = flr((mx+rnd(scrnw+32)-16)/8)
    s.y = flr((my+rnd(scrnh+32)-16)/8)
    found = (get_maptile(s.x, s.y) == 0 and get_maptile(s.x + (windgoright and -1 or 1), s.y) == 0)
  end
  s.x = s.x * 8 + 4
  s.y = s.y * 8 + 4
  
  local state = irnd(3)
  if state == 3 then
    s.anim_state = "a"
    s.a_t = 0.06 * 15
  elseif state == 2 then
    s.anim_state = "b"
    s.a_t = 0.06 * 15
  else
    s.anim_state = "c"
    s.a_t = 0.06 * 10
  end
  
  s.flipx = windgoright
  s.flipy = chance(50)
  state = anim_info["wind"][s.anim_state]
  s.a_t = state.dt * #state.sprites
  
  register_object(s)
  
  return s
end

function update_wind(s)
  s.animt = s.animt + delta_time

  if s.animt > s.a_t then
    deregister_object(s)  
  end
end

function draw_wind(s)
  -- all_colors_to(0)
  -- spr(s.skin, s.x-1, s.y-2)
  -- spr(s.skin, s.x+1, s.y-2)
  -- spr(s.skin, s.x, s.y-3)
  -- all_colors_to()
  -- spr(s.skin, s.x, s.y-2)

  local step = anim_step("wind", s.anim_state, s.animt)
  local x = s.x + step*(s.flipx and -1 or 1) -- makes it move
  draw_anim(x, s.y-2, "wind", s.anim_state, s.animt, 0, s.flipx, s.flipy)
end