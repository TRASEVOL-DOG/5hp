weapons = {}

-- weapons have base attributes and have update (cooldown, etc) and shoot (trigger basically) functions  

function create_weapon(name)
  return weapons[name] and weapons[name].get_attributes()  
end

function update_weapon(p) -- p for player
  weapons[p.weapon.name].update(p)
end

function shoot(p) -- p for player
  log("shooting with " .. p.weapon.name)
  weapons[p.weapon.name].shoot(p)
end

do -- Weapons --

  -- Gun           = "gun"
  -- Assault rifle = "ar"

  -- Gun 
  weapons.gun = {
    get_attributes =  function()
                        local att = {name = "gun"}  
                        return att
                      end
                      
    ,update =         function(p)
                        local w = p.weapon  
                        if w.time_shot == 10 then p.weapon = create_weapon("gun") end  
                      end
                      
    ,shoot  =         function(p)
                        local w = p.weapon                      
                      end
  }
  
  -- Assault rifle
  weapons.ar = {
    get_attributes =  function()
                        local att = {name = "ar"}  
                        return att
                      end
                      
    ,update =         function(p)
                        local w = p.weapon  
                        if w.time_shot == 10 then p.weapon = create_weapon("gun") end  
                      end
                      
    ,shoot  =         function(p)
                        local w = p.weapon  
                        w.time_shot = (w.time_shot or 0) + 1
                      end
  }  
  
end











