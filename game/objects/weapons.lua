weapons = {}

-- weapons have base attributes and have update (cooldown, etc) and shoot (trigger basically) functions  

function create_weapon(id)
  return weapons[id] and weapons[id].get_attributes() 
end

function update_weapon(p) -- p for player
  weapons[p.weapon.id].update(p)
end

function shoot(p) -- p for player
  local w = weapons[p.weapon.id]
  w.shoot(p)
  if not IS_SERVER then
    add_shake(4 * (p.weapon.shake_mult or 1))
  end
end

function do_shoot(p)
  if not p.weapon then p.weapon = create_weapon("gun") end
  return weapons[p.weapon.id].do_shoot(p)
end

do -- Weapons --

  -- Done
  ------------------------------
  -- Gun                = "gun"
  -- Assault rifle      = "ar"
  -- Shotgun            = "shotgun"
  -- Grenade Launcher   = "gl"
  -- Heavy Rifle        = "hr"
  -- Flamethrower       = "ft"
  
  -- TODO
  -- {"Mini Gun"}
  
  -- Gun 
  weapons.gun = {
    get_attributes =  function()
                        local att = {id = "gun", name = "Gun", arm_sprite = 0x260, loot_sprite = 0x240, bullet_type = 1, fire_rate = .3 }  
                        return att
                      end
                      
    ,do_shoot =       function(p) -- determine if weapon should shoot this frame
                        local w = p.weapon   
                        
                        if p.shoot_held and t() - (w.t_last_shot or 0) > w.fire_rate then return true
                        end                        
                      end
                      
    ,shoot  =         function(p)
                        local w = p.weapon     
                        w.t_last_shot = t()
                        create_bullet(p.id, nil, w.bullet_type, p.angle )
                      end
  }
  
  -- Assault rifle
  weapons.ar = {
    get_attributes =  function()
                        local att = {id = "ar", name = "Assault Rifle", bullet_type = 2, ammo = 60, rafale_length = 3, fire_rate = .1, arm_sprite = 0x262, loot_sprite = 0x242}  
                        return att
                      end
                      
    ,do_shoot =       function(p) -- determine if weapon should shoot this frame
                        local w = p.weapon
                        
                        if p.shoot_trigger then
                          w.rafale_started = true
                          w.rafale_left = w.rafale_length - 1
                          return true
                        elseif w.rafale_started then
                          if w.rafale_left > 0 and t() - (w.t_last_shot or 0) > w.fire_rate then 
                              w.rafale_left = w.rafale_left - 1
                              return true
                          else w.rafale_started = false 
                          end
                        end                        
                      end
                      
    ,shoot  =         function(p)
                        local w = p.weapon  
                        w.t_last_shot = t()
                        w.ammo = w.ammo - 1
                        create_bullet(p.id, nil, w.bullet_type, p.angle)
                        if w.ammo < 1 then p.weapon = create_weapon("gun") end
                      end
  }  
  
  -- Shotgun
  weapons.shotgun = {
    get_attributes =  function()
                        local att = {id = "shotgun", name = "Shotgun", bullet_type = 2, ammo = 36, fire_rate = .6, arm_sprite = 0x261, loot_sprite = 0x241, shake_mult = 1.3}  
                        return att
                      end
                      
    ,do_shoot =       function(p) -- determine if weapon should shoot this frame
                        local w = p.weapon
                        
                        if p.shoot_trigger and t() - (w.t_last_shot or 0) > w.fire_rate then return true
                        end                       
                      end
                      
    ,shoot  =         function(p)
                        local w = p.weapon  
                        w.t_last_shot = t()
                        local m = min ( 4, w.ammo)
                        local i = 0
                        local spread = .06
                        
                        while i < m do
                          local angle = p.angle - spread/2 + rnd(1) * spread 
                          local spd_mult = (0.5+rnd(0.5))
                          create_bullet(p.id, nil, w.bullet_type, angle, spd_mult)
                          
                          w.ammo = w.ammo - 1
                          i = i + 1
                        end
                        if w.ammo < 1 then p.weapon = create_weapon("gun") end
                      end
  }
  
  -- Grenade Launcher 
  weapons.gl = {
    get_attributes =  function()
                        local att = {id = "gl", name = "Grenade Launcher", bullet_type = 3, arm_sprite = 0x264, loot_sprite = 0x244, fire_rate = 1.3 , ammo = 15 , shake_mult = 1.3}  
                        return att
                      end
                      
    ,do_shoot =       function(p) -- determine if weapon should shoot this frame
                        local w = p.weapon   
                        
                        if p.shoot_trigger and t() - (w.t_last_shot or 0) > w.fire_rate then return true
                        end                        
                      end
                          
    ,shoot  =         function(p)
                        local w = p.weapon     
                        w.t_last_shot = t()
                        local params = {type = w.type}
                        create_bullet(p.id, nil, w.bullet_type, p.angle, nil)
                        w.ammo = w.ammo - 1
                        if w.ammo < 1 then p.weapon = create_weapon("gun") end
                      end
  }
  
  -- Heavy Rifle 
  weapons.hr = {
    get_attributes =  function()
                        local att = {id = "hr", name = "Heavy Rifle", arm_sprite = 0x263, loot_sprite = 0x243, bullet_type = 4, ammo = 60, fire_rate = .3 , shake_mult = 10.3}  
                        return att
                      end
                      
    ,do_shoot =       function(p) -- determine if weapon should shoot this frame
                        local w = p.weapon   
                        
                        if p.shoot_held and t() - (w.t_last_shot or 0) > w.fire_rate then return true
                        end                        
                      end
    
    ,shoot  =         function(p)
                        local w = p.weapon     
                        w.t_last_shot = t()
                        create_bullet(p.id, nil, w.bullet_type, p.angle )
                        w.ammo = w.ammo - 1
                        if w.ammo < 1 then p.weapon = create_weapon("gun") end
                      end
  }
  
  -- Mini gun
  weapons.mg = {
    get_attributes =  function()
                        local att = {id = "mg", name = "Mini Gun", arm_sprite = 0x265, loot_sprite = 0x245, ammo = 45, bullet_type = 2, fire_rate = .13 , shake_mult = .8}  
                        return att
                      end
                      
    ,do_shoot =       function(p) -- determine if weapon should shoot this frame
                        local w = p.weapon   
                        
                        if p.shoot_held and t() - (w.t_last_shot or 0) > w.fire_rate then return true
                        end                        
                      end
                      
    ,shoot  =         function(p)
                        local w = p.weapon     
                        w.t_last_shot = t()
                        w.ammo = w.ammo - 1
                        create_bullet(p.id, nil, w.bullet_type, p.angle )
                        if w.ammo < 1 then 
                          p.weapon = create_weapon("gun")
                        end
                        -- if w.ammo < 40 then p.weapon = weapons.gun.get_attributes() end
                      end
  }
  
  -- Flamethrower
  weapons.ft = {
    get_attributes =  function()
                        local att = {id = "ft", name = "Flamethrower", arm_sprite = 0x266, loot_sprite = 0x246, ammo = 100, bullet_type = 5, fire_rate = 0.1, shake_mult = 0.3}  
                        return att
                      end
                      
    ,do_shoot =       function(p) -- determine if weapon should shoot this frame
                        local w = p.weapon   
                        
                        if p.shoot_held and t() - (w.t_last_shot or 0) > w.fire_rate then return true
                        end                        
                      end
                      
    ,shoot  =         function(p)
                        local w = p.weapon     
                        w.t_last_shot = t()
                        w.ammo = w.ammo - 1
                        create_bullet(p.id, nil, w.bullet_type, p.angle + give_or_take(0.07))
                        
                        if w.ammo < 1 then 
                          p.weapon = create_weapon("gun")
                        end
                      end
  }
  
end











