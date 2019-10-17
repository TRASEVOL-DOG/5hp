weapons = {}

-- weapons have base attributes and have update (cooldown, etc) and shoot (trigger basically) functions  

function create_weapon(name)
  return weapons[name] and weapons[name].get_attributes()  
end

function update_weapon(p) -- p for player
  weapons[p.weapon.name].update(p)
end

function shoot(p) -- p for player
  weapons[p.weapon.name].shoot(p)
end

function do_shoot(p)
  return weapons[p.weapon.name].do_shoot(p)
end

do -- Weapons --

  -- Done
  -- Gun                = "gun"
  -- Assault rifle      = "ar"
  -- Shotgun            = "shotgun"
  -- Grenade Launcher   = "gl"
  
  -- TODO
  -- {"Grenade Launcher", "Heavy Rifle", "Mini Gun"}
  
  -- Gun 
  weapons.gun = {
    get_attributes =  function()
                        local att = {name = "gun", arm_sprite = 120, fire_rate = .3 , }  
                        return att
                      end
                      
    ,do_shoot =       function(p) -- determine if weapon should shoot this frame
                        local w = p.weapon   
                        
                        if p.shoot_trigger then return true
                        elseif p.shoot_held and t() - (w.t_last_shot or 0) > w.fire_rate then return true
                        end                        
                      end
    
    ,update =         function(p)
                        local w = p.weapon
                      end
                      
    ,shoot  =         function(p)
                        local w = p.weapon     
                        w.t_last_shot = t()
                        local params = {angle = p.angle}
                        create_bullet(p.id, nil, params)
                      end
  }
  
  -- Assault rifle
  weapons.ar = {
    get_attributes =  function()
                        local att = {name = "ar", ammo = 60, rafale_length = 3, fire_rate = .1, arm_sprite = 122, sfx_vol = .75}  
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
                      
    ,update =         function(p)
                        local w = p.weapon
                        if w.ammo < 1 then p.weapon = create_weapon("gun") end
                      end
                      
    ,shoot  =         function(p)
                        local w = p.weapon  
                        w.t_last_shot = t()
                        w.ammo = w.ammo - 1
                        local params = {angle = p.angle, sfx_vol = sfx_vol}
                        create_bullet(p.id, nil, params)
                      end
  }  
  
  -- Shotgun
  weapons.shotgun = {
    get_attributes =  function()
                        local att = {name = "shotgun", ammo = 35, fire_rate = .6, arm_sprite = 121}  
                        return att
                      end
                      
    ,do_shoot =       function(p) -- determine if weapon should shoot this frame
                        local w = p.weapon
                        
                        if p.shoot_trigger and t() - (w.t_last_shot or 0) > w.fire_rate then return true
                        end                       
                      end
                      
    ,update =         function(p)
                        local w = p.weapon
                        if w.ammo < 1 then p.weapon = create_weapon("gun") end
                      end
                      
    ,shoot  =         function(p)
                        local w = p.weapon  
                        w.t_last_shot = t()
                        local m = min ( 5, w.ammo)
                        local i = 0
                        local spread = .06
                        
                        while i < m do
                          local angle = p.angle - spread/2 + rnd(1) * spread 
                          local params = {angle = angle, spd_mult = (0.5+rnd(0.5))}
                          local b = create_bullet(p.id, nil, params)
                          
                          w.ammo = w.ammo - 1
                          i = i + 1
                        end  
                        
                        
                      end
  }  
  
  -- Grenade Launcher 
  weapons.gl = {
    get_attributes =  function()
                        local att = {name = "gl", arm_sprite = 124, fire_rate = 1.3 , ammo = 15, type = 2, resistance = .90 }  
                        return att
                      end
                      
    ,do_shoot =       function(p) -- determine if weapon should shoot this frame
                        local w = p.weapon   
                        
                        if p.shoot_trigger and t() - (w.t_last_shot or 0) > w.fire_rate then return true
                        end                        
                      end
    
    ,update =         function(p)
                        local w = p.weapon
                      end
                      
    ,shoot  =         function(p)
                        local w = p.weapon     
                        w.t_last_shot = t()
                        local params = {angle = p.angle, type = w.type, resistance = w.resistance}
                        create_bullet(p.id, nil, params)
                      end
  }
  
end











