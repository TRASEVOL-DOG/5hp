
  local shadcode = [[
    varying vec2 v_vTexcoord;
    varying vec4 v_vColour;
    
    extern Image tex;
    
    vec4 effect(vec4 color, Image texture, vec2 coords, vec2 screen_coords)
    {
      vec4 col = Texel(tex, coords);
      
      return col;
    }
  ]]

  local status, message = love.graphics.validateShader(true, shadcode)
  if status then
    shader = love.graphics.newShader(shadcode)
  else
    print("Could not validate shader: "..message)
  end
  
  print("All done!")