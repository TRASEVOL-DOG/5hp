


local selected_shader = "all"
local shader_crt = 0.05
local shader_scanlines = 0.25
local shader_glow = 1

local shader_code = {
  all = [[
  varying vec2 v_vTexcoord;
  varying vec4 v_vColour;
  
  extern float glow_strength;
  extern float crt; // default: 0.05
  extern float scanlines; // default: 0.25
  
  const float PI = 3.1415926535897932384626433832795;
  
  vec4 effect(vec4 color, Image texture, vec2 coords, vec2 screen_coords)
  {
    coords = coords * 2.0 - vec2(1.0, 1.0);
    coords += (coords.yx * coords.yx) * coords * crt;
    
    float mask = ceil(1.0 - max(abs(coords.x), abs(coords.y)));
    
    coords = coords / 2.0 + vec2(0.5, 0.5);
    
    float v = mod(coords.y * SCREEN_SIZE.y, 1.0) * 2.0 - 1.0;
    mask *= 1.0 - scanlines * v*v;
    
    vec4 col = Texel_color(texture, coords);
    
    float n = 0.9;
    vec2 tca = vec2(0.98 * n, 0.2 * n) / SCREEN_SIZE;
    vec2 tcb = vec2(-0.98 * n, 0.2 * n) / SCREEN_SIZE;
    vec2 tcc = vec2(0.2 * n, 0.98 * n) / SCREEN_SIZE;
    vec2 tcd = vec2(-0.2 * n, 0.98 * n) / SCREEN_SIZE;
    
    vec4 glow = 0.125 * (
      Texel_color(texture, coords + tca) +
      Texel_color(texture, coords - tca) +
      Texel_color(texture, coords + tcb) +
      Texel_color(texture, coords - tcb) +
      Texel_color(texture, coords + tcc) +
      Texel_color(texture, coords - tcc) +
      Texel_color(texture, coords + tcd) +
      Texel_color(texture, coords - tcd)
    );
    
    tca *= 2.0;
    tcb *= 2.0;
    tcc *= 2.0;
    tcd *= 2.0;
    
    glow += 0.0625 * (
      Texel_color(texture, coords + tca) +
      Texel_color(texture, coords - tca) +
      Texel_color(texture, coords + tcb) +
      Texel_color(texture, coords - tcb) +
      Texel_color(texture, coords + tcc) +
      Texel_color(texture, coords - tcc) +
      Texel_color(texture, coords + tcd) +
      Texel_color(texture, coords - tcd)
    );
    
    tca *= 1.5;
    tcb *= 1.5;
    tcc *= 1.5;
    tcd *= 1.5;
    
    glow += 0.03 * (
      Texel_color(texture, coords + tca) +
      Texel_color(texture, coords - tca) +
      Texel_color(texture, coords + tcb) +
      Texel_color(texture, coords - tcb) +
      Texel_color(texture, coords + tcc) +
      Texel_color(texture, coords - tcc) +
      Texel_color(texture, coords + tcd) +
      Texel_color(texture, coords - tcd)
    );
    
    return vec4(mix(col + glow_strength * glow, glow, 0.25).rgb * mask, 1.0);
  }
]],

no_glow = [[
  varying vec2 v_vTexcoord;
  varying vec4 v_vColour;
  
  extern float crt; // default: 0.05
  extern float scanlines; // default: 0.25
  
  const float PI = 3.1415926535897932384626433832795;
  
  vec4 effect(vec4 color, Image texture, vec2 coords, vec2 screen_coords)
  {
    coords = coords * 2.0 - vec2(1.0, 1.0);
    coords += (coords.yx * coords.yx) * coords * crt;
    
    float mask = ceil(1.0 - max(abs(coords.x), abs(coords.y)));
    
    coords = coords / 2.0 + vec2(0.5, 0.5);
    
    float v = mod(coords.y * SCREEN_SIZE.y, 1.0) * 2.0 - 1.0;
    mask *= 1.0 - scanlines * v*v;
    
    vec4 col = Texel_color(texture, coords);
    
    return vec4(col.rgb * mask, 1.0);
  }
]]
}

function select_shader(name, crt, scanlines)
  selected_shader  = name or selected_shader
  shader_crt       = crt or shader_crt
  shader_scanlines = scanlines or shader_scanlines
  
  if selected_shader == "no_glow" and shader_crt == 0 and shader_scanlines == 0 then
    selected_shader = "none"
  elseif selected_shader == "none" and (shader_crt > 0 or shader_scanlines > 0) then
    selected_shader = "no_glow"
  end

  screen_shader(shader_code[selected_shader])
  screen_shader_input({
    crt = shader_crt,
    scanlines = shader_scanlines
  })
end

function glow_strength(v)
  if v then
    shader_glow = v / 100
  
    if cam then
      cam.glow = 0.75
    end
    save_setting("glow_str", v/100)
    
    return shader_glow * 100
  end
  
  return shader_glow * 100
end

function shader_params()
  return selected_shader, shader_crt, shader_scanlines
end

function update_shader()
  screen_shader_input({glow_strength = cam.glow * shader_glow})
end