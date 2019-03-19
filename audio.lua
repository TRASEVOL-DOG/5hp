-- BLAST FLOCK source files
-- by TRASEVOL_DOG (https://trasevol.dog/)

function init_audio()
  local music_list={
--    theme= "Cyanotype_loop.ogg"
  }
 
  local sfx_list={
--    shootorder= "shootorder.ogg",
--    shoot=           "shoot.ogg",
--    enemyshoot=  "enemshoot.ogg",
--    boost=           "boost.ogg",
--    helix=           "helix.ogg",
--    hole=             "hole.ogg",
--    levelup=       "levelup.ogg",
--    boom1=           "boom1.ogg",
--    boom2=           "boom2.ogg",
--    boom3=           "boom3.ogg",
--    scrap=           "scrap.ogg",
--    save=             "save.ogg",
--    gameover=     "gameover.ogg",
--    select=         "select.ogg",
--    confirm=       "confirm.ogg",
--    slider=      "sliderset.ogg",
--    dog=               "dog.ogg"
  }
  local sfx_list={
   menu_select        = "select.ogg",
   menu_confirm       = "confirm.ogg",
   menu_slider        = "sliderset.ogg",
   tab                = "tab.ogg",
   shoot              = "shoot.ogg",
   enemy_shoot        = "enemy_shoot.ogg",
   cant_shoot         = "cant_shoot.ogg",
   steps              = "step.ogg",
   get_hit            = "get_hit.ogg",
   get_hit_player     = "get_hit_player.ogg",
   gameover           = "gameover.ogg",
   startplay          = "startplay.ogg",
   cactus_hit         = "cactus_hit.ogg",
   bullet_wall_bounce = "bullet_bounce.ogg",
   wind_a             = "wind_a.ogg",
   wind_b             = "wind_b.ogg",
   wind_c             = "wind_c.ogg",
   wind_d             = "wind_d.ogg",
   wind_e             = "wind_e.ogg"
  }
  
  musics={}
  sfxs={}
   
  for n,f in pairs(music_list) do
    musics[n]=love.audio.newSource("assets/"..f,"stream")
    musics[n]:setLooping(true)
  end
  for n,f in pairs(sfx_list) do
    sfxs[n]=love.audio.newSource("assets/sfx/"..f,"static")
  end
 
  --sfx_vol=100
  --music_vol=0--100
  --master_vol=100
  
  sfx_volume(100)
  music_volume(60)
  master_volume(100)
  
  curmusic=nil
end


function sfx(name,x,y,pitch,volume)
  if server_only then return end

  local s=sfxs[name]
  if not s then return end
  
  if pitch then
    s:setPitch(pitch)
  end
  
  if volume then
    s:setVolume(volume/100 * sfx_vol/100)
  end
  
  if x and y then
    local k=50
    local scrnw,scrnh = screen_size()
    x,y=(x-cam.x-scrnw/2)/k,(y-cam.y-scrnh/2)/k
    s:setPosition(x,y,1)
  end
  
  if s:isPlaying() then
    s:seek(0)
  else
    s:play()
  end
end

function music(name)
  if server_only then return end

  if curmusic then
    musics[curmusic]:stop()
  end
  
  curmusic=name
  
  if not name then
    return
  end
  
  local m = musics[name]
  if not m then return end
  love.audio.play(m)
end

function music_lowpass(enable)
  if server_only then return end

  if enable then
    for n,m in pairs(musics) do
      m:setFilter{type="lowpass",highgain=.4,volume=music_vol/100}
    end
  else
    for n,m in pairs(musics) do
      m:setFilter()
    end
  end
end

function listener(x,y)
  if server_only then return end

  love.audio.setPosition(x,y)
end

function sfx_volume(v)
  if server_only then return end

  if not v then
    return sfx_vol
  end
  
  for n,s in pairs(sfxs) do
    s:setVolume(v/100)
  end
  
  sfx_vol=v
end

function music_volume(v)
  if server_only then return end

  if not v then
    return music_vol
  end
  
  for n,m in pairs(musics) do
    m:setVolume(v/100)
  end
  
  music_vol=v
end

function master_volume(v)
  if server_only then return end

  if not v then
    return master_vol
  end
  
  love.audio.setVolume(v/100)
  
  master_vol=v
end