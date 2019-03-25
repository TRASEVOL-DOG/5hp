

require("maths")


MAP_W = 128
MAP_H = 72

WALL_HP = 5

map = nil

spawn_points = {}
spawn_points_copy = {}
cacti_spawn_points = {}
--ground = {}

wall_hp = {}

local walls = {2}

original_map = {}

map_data = {[0]=
  {[0]=2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2},
  {[0]=2,2,2,2,2,2,2,2,2,0,0,0,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2},
  {[0]=2,2,2,2,2,2,0,0,0,0,0,0,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,0,0,0,0,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,0,0,0,0,2,2,0,0,0,0,2,2,0,0,0,0,0,0,0,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2},
  {[0]=2,2,2,2,2,0,0,0,0,0,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,0,0,0,0,0,0,0,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,0,0,0,0,0,2,2,0,0,0,0,2,2,0,0,0,0,0,0,0,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2},
  {[0]=2,2,2,2,2,0,0,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,0,0,0,0,8,0,0,0,0,0,0,0,0,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,8,0,0,0,0,0,9,0,0,0,0,0,0,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2},
  {[0]=2,2,2,2,0,0,0,0,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,8,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,2,2,2,2,2,2,2,2,2,2},
  {[0]=2,2,2,2,0,8,0,0,2,2,2,2,0,0,0,0,2,2,2,2,2,2,2,2,2,2,2,2,2,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,2,2,2},
  {[0]=2,2,2,2,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,2,2,2,2,2,2,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,9,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,8,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,2,2},
  {[0]=2,2,2,2,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,9,0,2,2,2,2,0,0,0,0,0,0,9,0,0,0,0,0,0,0,8,0,0,0,0,0,9,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,9,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,2,2,2,2,2,2,2,2,2,2,2,2,2,2,0,0,8,0,0,0,2,2},
  {[0]=2,2,2,2,2,2,0,0,0,0,0,0,0,0,0,0,0,0,0,8,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,9,0,0,0,0,0,0,0,0,2,2,2,2,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,9,0,0,0,0,0,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,0,0,0,0,0,2,2},
  {[0]=2,2,2,2,2,2,0,0,0,0,0,0,0,0,0,0,0,9,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,9,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,0,0,0,0,0,2,2},
  {[0]=2,2,2,2,2,2,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,9,0,0,0,0,0,9,0,0,0,0,0,0,0,0,0,9,0,0,0,0,0,0,0,0,0,0,9,0,0,0,0,0,0,9,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,9,0,0,0,0,0,0,0,0,0,0,2,2,2,0,0,0,2,2,0,0,0,0,2,2,2,2,0,0,0,0,0,2,2},
  {[0]=2,2,2,2,2,2,0,0,0,0,0,0,9,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,9,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,2,2,2,0,0,0,2,2,0,0,0,0,0,2,2,2,0,0,0,0,0,2,2},
  {[0]=2,2,2,2,2,2,2,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,9,0,0,0,0,0,0,0,0,0,0,0,0,0,9,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,2,2,2,0,8,0,0,0,0,0,8,0,0,2,2,2,0,0,0,0,0,2,2},
  {[0]=2,2,2,2,2,2,2,0,0,0,0,0,0,0,0,0,0,0,0,0,9,0,0,0,0,0,0,0,0,0,0,0,0,0,9,0,0,0,0,0,0,0,9,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,9,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,2,2,2,0,0,0,0,0,9,0,0,0,0,2,2,2,0,0,0,8,0,2,2},
  {[0]=2,2,2,2,2,2,2,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,9,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,9,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,2,2,0,0,0,9,0,0,0,9,0,0,2,2,2,0,0,0,0,0,2,2},
  {[0]=2,2,2,2,2,2,0,0,0,0,0,0,0,0,0,0,9,0,0,0,0,0,0,9,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,2,2,2,2,2,2,2,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,9,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,9,0,0,0,0,2,2,2,0,0,0,0,2,2,2},
  {[0]=2,2,2,2,2,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,9,0,0,0,0,0,0,9,0,0,0,0,0,9,0,0,0,0,0,0,0,0,0,0,0,0,0,0,2,2,2,2,2,2,2,0,0,0,0,0,0,0,2,2,2,0,0,2,2,2,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,9,0,0,0,0,0,0,0,0,0,0,0,0,9,0,0,0,0,0,0,2,2,2,2,0,0,0,2,2,2,2},
  {[0]=2,2,2,2,2,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,8,0,0,0,2,2,2,0,0,2,2,2,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,2,2,2,2,2,2,2,2,0,0,0,2,2,2,2},
  {[0]=2,2,2,2,2,0,8,0,0,0,0,0,0,0,0,0,0,0,0,0,0,9,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,2,2,0,0,0,0,0,0,0,0,0,2,2,0,0,0,0,2,2,2,2,2,2,2,2,0,0,0,0,0,9,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,2,2,2,2,2,2,2,2,2,2,2,2,0,0,0,2,2,2,2},
  {[0]=2,2,2,2,2,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,2,2,0,9,0,0,0,0,0,9,0,2,2,0,0,2,2,2,2,2,0,0,2,2,2,2,2,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,2,2,2,2,2,2,2,2,2,2,2,0,0,0,0,2,2,2,2},
  {[0]=2,2,2,2,2,0,0,0,0,0,0,9,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,9,0,0,0,0,0,2,2,2,2,2,0,0,0,0,2,2,2,2,2,2,2,2,2,2,0,0,0,0,2,2,0,0,9,0,0,0,9,0,0,2,2,0,0,2,2,2,2,2,0,0,2,2,2,2,2,0,0,0,0,0,0,0,0,0,9,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,2,2,2,2},
  {[0]=2,2,2,2,2,0,0,0,0,0,0,0,0,0,0,0,0,9,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,2,2,2,2,2,0,0,0,0,2,2,2,2,2,2,2,2,2,2,0,0,0,0,2,2,0,0,0,0,0,0,0,0,0,2,2,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,2,2,2,2},
  {[0]=2,2,2,2,2,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,8,0,0,0,0,0,0,0,0,0,0,0,2,2,2,2,2,0,0,0,0,0,0,0,2,2,2,2,2,2,2,0,0,0,0,2,2,0,0,0,0,0,0,0,0,0,2,2,0,0,0,0,0,0,0,8,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,2,2,2,2},
  {[0]=2,2,2,2,2,2,0,0,0,0,0,0,0,0,9,0,0,0,0,0,0,0,0,9,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,8,0,0,0,0,0,2,2,2,2,2,2,2,0,0,0,0,2,2,2,2,2,2,2,2,2,2,2,2,2,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,2,2,2,2},
  {[0]=2,2,2,2,2,2,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,2,2,0,0,0,0,0,0,0,0,0,2,2,2,2,2,2,2,2,2,2,2,2,2,0,0,0,0,0,0,0,0,0,0,0,0,0,2,2,2,2,2,2,2,2,2,2,0,0,0,0,0,0,0,0,0,0,0,0,9,0,0,0,0,0,0,0,0,0,9,0,0,0,0,0,0,0,0,0,0,2,2,2},
  {[0]=2,2,2,2,2,2,2,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,9,0,0,0,2,2,2,2,2,0,2,2,2,2,2,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,2,2,2,2,2,2,0,0,0,2,2,2,2,2,2,2,2,2,2,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,2,2,2},
  {[0]=2,2,2,2,2,2,2,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,2,2,2,2,2,0,2,2,2,2,2,0,0,0,0,0,0,0,0,0,0,9,0,0,0,8,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,2,2,2,2,2,2,0,0,0,2,2,2,2,2,2,2,2,2,2,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,2,2,2},
  {[0]=2,2,2,2,2,2,2,0,0,0,0,0,0,0,0,0,9,0,0,0,9,0,0,0,0,0,0,0,0,0,2,2,2,2,2,0,2,2,2,2,2,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,2,2,2,2,2,2,0,0,0,0,0,0,0,0,0,2,2,2,0,0,0,0,0,9,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,2,2,2},
  {[0]=2,2,2,2,2,2,2,0,0,0,0,0,9,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,9,0,0,0,2,2,2,2,2,2,2,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,2,2,2,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,9,0,0,0,0,0,2,2,2},
  {[0]=2,2,2,2,2,2,2,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,2,2,2,2,2,2,2,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,9,0,0,0,0,0,0,0,0,0,0,0,0,0,2,2,2},
  {[0]=2,2,2,2,2,2,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,9,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,8,0,0,0,0,0,0,0,0,0,0,0,2,2,2,2,2,2,2,2,2,0,0,2,2,2,2,2,2,2,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,8,0,0,0,0,0,0,2,2,2,2,2,2,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,2,2,2},
  {[0]=2,2,2,2,2,2,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,2,2,2,2,0,0,0,0,0,0,2,2,2,2,2,2,2,2,2,0,0,2,2,2,2,2,2,2,0,0,2,2,2,2,2,2,2,2,2,0,0,0,2,2,0,0,0,0,0,0,2,2,2,2,2,2,2,2,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,2,2,2},
  {[0]=2,2,2,2,2,2,0,0,0,0,9,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,9,0,0,2,2,2,2,0,0,0,0,0,0,0,0,0,2,2,2,2,2,2,0,0,0,0,0,0,0,0,0,0,0,2,2,2,2,2,2,2,2,2,0,0,0,2,2,0,0,0,0,0,0,2,2,2,2,2,2,2,2,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,8,0,2,2,2},
  {[0]=2,2,2,2,2,2,2,0,0,0,0,0,0,0,0,9,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,2,2,2,2,0,0,0,2,2,2,2,0,0,0,0,0,0,0,0,0,2,2,2,2,2,2,0,0,0,0,0,0,0,0,0,0,0,2,2,0,0,0,0,0,2,2,0,0,0,2,2,0,0,0,0,0,0,0,2,2,2,2,2,2,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,2,2},
  {[0]=2,2,2,2,2,2,2,2,0,0,0,0,0,0,0,0,0,0,0,0,0,9,0,0,0,0,0,0,9,0,0,0,0,0,0,0,2,2,2,2,0,0,0,2,2,2,2,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,2,2,0,0,0,0,0,2,2,0,0,0,2,2,2,2,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,2,0,0,0,0,0,0,0,0,0,0,0,0,2,0,0,0,0,2,2},
  {[0]=2,2,2,2,2,2,2,2,2,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,9,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,9,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,2,2,0,0,0,0,0,2,2,0,0,0,2,2,2,2,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,2,0,9,0,0,0,0,2,2,0,0,0,0,2,2},
  {[0]=2,2,2,2,2,2,2,2,2,0,0,8,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,3,0,1,0,0,0,0,2,2,0,0,0,0,0,2,2,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,9,0,0,0,0,0,0,0,0,0,0,0,0,0,0,2,2,0,0,0,0,2,2},
  {[0]=2,2,2,2,2,2,2,2,2,2,0,0,0,0,0,0,0,0,9,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,9,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,2,2,2,2,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,2,0,2,2,0,0,0,0,2,2},
  {[0]=2,2,2,2,2,2,2,2,2,2,2,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,9,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,2,2,2,2,2,0,0,2,2,2,2,0,0,0,1,0,0,9,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,2,2,2,2,0,2,2,2,2,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,2,2,0,0,0,0,2,2},
  {[0]=2,2,2,2,2,2,2,2,2,2,2,2,0,0,0,0,0,0,0,0,0,0,0,0,0,9,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,2,2,2,2,2,0,0,2,2,2,2,0,0,9,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,2,2,2,2,0,2,2,2,2,0,0,0,0,0,0,0,2,2,0,0,0,0,2,2,0,0,0,0,0,9,0,0,0,2,2,0,0,0,0,2,2},
  {[0]=2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,0,0,0,0,0,0,8,0,0,0,0,0,0,0,9,0,0,0,0,0,0,0,9,0,0,0,0,0,0,0,0,0,0,0,0,0,2,2,0,2,2,0,0,0,0,2,2,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,2,2,2,2,0,2,2,2,2,0,0,0,0,0,0,0,0,0,0,0,0,2,2,0,0,8,0,2,2,0,0,0,0,0,0,0,0,0,2,2,0,0,0,0,2,2},
  {[0]=2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,9,0,0,0,2,2,2,2,0,0,0,0,0,0,0,0,0,0,0,2,2,0,0,0,0,0,0,0,0,0,0,0,0,0,0,2,2,2,2,0,2,2,2,2,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,2,0,0,0,0,0,2,2,0,0,0,0,2,2},
  {[0]=2,2,2,0,0,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,0,0,0,0,0,0,0,0,0,0,0,0,0,2,2,2,2,0,0,0,0,0,0,0,9,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,9,0,0,0,2,2,2,2,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,2,0,0,0,0,2,2},
  {[0]=2,2,2,0,0,0,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,2,2,2,2,0,0,0,0,0,0,0,0,0,0,0,9,0,0,0,2,2,0,0,0,0,8,0,0,0,0,0,0,0,0,2,0,0,0,0,2,2},
  {[0]=2,2,2,0,0,0,0,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,0,0,0,0,0,0,0,0,0,0,0,0,0,9,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,8,0,0,0,0,0,2,2,2,2,2,2,2,2,2,2,0,0,0,0,0,0,0,0,0,0,0,2,2,2,2,2,0,0,0,0,0,0,0,0,2,0,0,0,0,0,0,2,2,0,0,0,0,0,0,0,0,0,0,2,0,0,0,0,0,0,0,2,2},
  {[0]=2,2,2,2,0,0,0,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,0,0,0,0,0,0,0,2,2,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,2,2,2,2,2,2,0,2,2,2,2,0,2,2,2,2,2,2,2,2,2,2,0,2,2,2,0,2,2,2,2,2,0,2,2,2,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,9,0,0,0,0,0,0,0,0,0,0,0,0,2,2},
  {[0]=2,2,2,2,2,0,0,0,0,0,0,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,0,0,0,0,0,0,0,0,2,2,0,0,0,0,0,0,9,0,0,0,0,0,0,9,0,0,2,2,2,2,2,2,0,2,2,2,2,0,2,2,2,2,2,2,2,2,2,2,0,2,2,2,0,2,2,2,2,2,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,2,2,2},
  {[0]=2,2,2,2,2,0,8,0,0,0,0,0,2,2,2,2,2,2,2,2,2,2,0,2,2,2,2,0,0,0,0,0,0,0,0,2,2,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,2,2,2,0,2,2,2,2,0,2,2,0,0,2,2,0,0,2,2,0,0,0,0,0,2,2,2,2,2,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,2,2,0,0,0,0,2,2,0,0,0,0,0,0,0,0,0,0,0,0,0,0,2,2,2},
  {[0]=2,0,0,2,2,2,0,0,0,0,0,0,0,2,2,2,2,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,2,2,2,2,0,9,0,0,0,0,0,2,2,2,0,0,0,0,0,0,0,0,0,2,2,2,0,0,0,0,0,0,2,2,0,0,0,0,0,0,2,2,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,9,0,0,0,0,0,0,0,2,2,0,8,0,0,2,2,0,0,0,0,0,9,0,0,0,0,2,0,0,0,2,2,2},
  {[0]=2,0,0,0,2,0,0,0,2,2,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,2,2,2,2,2,2,2,2,0,0,0,0,0,0,0,2,2,2,0,0,9,0,0,0,0,0,0,2,2,2,0,0,0,0,0,0,0,0,0,8,0,0,8,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,8,0,2,2,2},
  {[0]=2,0,0,0,0,0,0,0,2,2,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,2,2,2,2,2,2,2,2,0,0,0,0,0,0,0,0,2,2,2,2,0,0,0,0,9,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,2,2,2,2,2,2,0,0,0,0,0,0,0,9,0,0,0,0,0,0,0,2,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,2,0,0,0,0,9,0,0,0,0,0,2,2,2},
  {[0]=2,2,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,2,2,2,2,0,0,0,0,0,2,2,2,2,2,2,2,2,2,2,0,0,0,0,9,0,0,0,2,2,2,2,0,2,2,2,0,0,0,0,0,0,0,0,2,2,2,2,2,2,2,0,2,2,2,2,2,2,2,0,2,2,2,2,2,2,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,9,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,2,2,2,2},
  {[0]=2,2,2,0,8,0,2,0,0,0,0,2,0,0,0,0,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,0,0,0,0,0,0,0,0,0,0,0,0,0,2,2,2,0,0,0,0,0,0,0,0,2,2,2,2,2,2,2,0,0,2,2,2,2,2,0,0,2,2,2,2,2,2,0,0,0,0,0,0,0,0,0,2,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,9,0,0,0,0,0,0,2,2,2,2},
  {[0]=2,2,2,0,0,2,2,2,2,0,0,2,2,0,0,0,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,0,0,0,0,0,0,0,0,0,0,0,0,0,2,2,2,0,2,2,2,2,2,0,0,2,2,2,2,2,2,2,0,0,2,2,2,2,2,0,0,0,2,2,2,2,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,2,0,0,9,0,2,2,2,2},
  {[0]=2,2,2,2,2,2,2,2,2,0,0,2,2,2,0,0,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,2,2,2,2,2,0,0,2,2,0,0,0,2,2,0,2,2,2,2,2,2,2,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,2,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,2,2,2,2},
  {[0]=2,2,2,2,2,2,2,2,2,0,0,2,2,2,0,0,0,0,0,0,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,0,0,0,0,0,0,0,2,2,2,2,2,2,0,0,0,0,0,0,0,0,0,0,0,0,2,2,0,0,0,2,2,0,0,2,2,2,2,2,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,9,0,0,0,0,0,0,0,0,0,0,9,0,0,0,0,0,0,0,0,0,0,0,2,2,2,2},
  {[0]=2,2,2,2,2,2,2,2,0,0,0,2,2,0,0,0,0,0,0,0,0,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,0,0,0,9,0,0,0,2,2,2,2,2,2,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,9,0,0,0,0,0,0,0,0,0,8,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,2,2,2,2},
  {[0]=2,2,2,2,0,0,2,0,0,0,0,2,2,0,0,0,0,0,0,0,0,2,2,2,2,2,2,2,2,2,2,2,2,2,0,0,0,0,0,0,0,0,0,0,2,2,2,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,2,0,0,9,0,0,0,0,0,2,2,2,2},
  {[0]=2,2,2,0,0,0,0,0,0,2,2,2,2,0,0,9,0,0,0,0,0,0,0,0,0,2,2,2,2,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,2,2,2,0,0,0,0,0,0,0,2,2,2,0,2,2,2,2,2,2,2,2,2,0,2,2,2,2,2,2,2,2,2,0,0,0,9,0,0,0,9,0,0,0,0,0,0,0,0,0,9,0,0,0,0,0,0,0,0,0,0,0,0,0,0,2,0,0,0,0,0,0,0,0,0,0,0,2,0,0,2,2,2,2},
  {[0]=2,2,2,0,0,0,0,0,0,2,2,2,2,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,2,2,2,0,0,0,0,0,0,0,8,0,0,0,0,0,2,2,2,0,2,2,2,2,2,2,2,2,2,0,2,2,2,2,2,2,2,2,2,0,0,0,0,0,0,0,0,0,0,0,0,9,0,0,0,0,0,0,0,0,0,2,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,2,2,2,2},
  {[0]=2,2,0,0,0,0,0,0,0,2,2,2,2,0,0,0,0,0,9,0,0,2,2,0,0,0,0,0,0,0,0,2,2,2,0,0,0,0,2,2,2,2,2,0,0,0,0,0,0,0,0,0,0,0,2,2,2,0,2,2,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,2,2,0,0,0,0,0,2,2,2,2,2,0,8,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,9,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,2,2,2},
  {[0]=2,2,0,0,2,2,2,0,0,2,2,2,2,0,0,0,0,0,0,0,0,2,2,2,2,2,2,0,2,2,2,2,2,2,2,2,0,0,0,2,2,2,2,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,2,2,0,8,0,0,9,0,9,0,9,0,9,0,0,8,0,2,2,0,0,0,0,0,2,2,2,2,2,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,2,2,2},
  {[0]=2,2,0,0,2,2,2,0,0,2,2,2,2,2,0,0,0,0,0,0,2,2,2,2,2,2,2,0,2,2,2,2,2,2,2,2,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,2,2,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,2,2,0,0,9,0,0,2,2,2,2,2,0,2,2,2,2,0,0,0,0,0,0,0,0,0,0,0,2,0,0,0,0,0,0,0,0,0,0,9,0,0,0,2,0,0,0,0,0,0,2,2,2},
  {[0]=2,2,0,0,2,2,2,0,0,2,2,2,2,2,2,0,0,0,2,2,2,2,2,2,2,2,2,0,2,2,2,2,2,2,2,2,0,0,9,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,0,0,0,0,0,0,0,0,0,0,0,2,2,2,2,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,2,0,0,0,0,0,0,0,0,0,0,0,0,0,2,2,2,2},
  {[0]=2,2,0,0,2,2,2,0,0,2,2,2,2,2,2,0,0,0,2,2,2,2,2,2,2,2,2,0,2,2,2,2,2,2,2,2,0,8,0,0,0,0,0,9,0,0,0,0,0,0,0,0,9,0,0,0,0,0,2,2,2,2,2,2,2,2,0,0,0,2,2,2,2,2,2,2,2,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,2,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,8,0,2,2,2,2},
  {[0]=2,2,0,0,0,0,0,0,0,2,2,2,2,2,2,2,0,0,2,2,2,2,2,2,2,2,0,0,2,2,2,2,2,2,2,2,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,9,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,9,0,0,0,0,0,0,0,0,0,0,0,0,0,0,9,0,0,0,0,0,0,0,0,0,2,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,2,2,2,2},
  {[0]=2,2,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,2,2,2,2,0,0,2,2,0,0,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,8,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,2,2,2,2,2,2,2,2},
  {[0]=2,2,0,0,0,0,0,0,0,0,0,0,0,0,0,0,8,0,2,2,2,2,0,0,0,0,0,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,0,8,0,9,0,0,0,0,0,0,0,0,0,0,8,0,2,2,2,2,2,2,2,2,2,2,2,0,0,0,0,0,0,0,0,2,2,2,2,2,2,2,2,2,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,8,0,0,0,0,0,2,2,2,2,2,2,2,2,2,2,2,2,2,2},
  {[0]=2,2,2,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,2,2,2,2,0,8,0,0,0,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2},
  {[0]=2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,0,0,0,0,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2},
  {[0]=2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2}
}

function init_map()
  original_map = copy_table(map_data, true)
  
  local owalls = walls
  walls = {}
  for _,i in ipairs(owalls) do
    walls[i] = true
  end

  local i,j = 0, 0
  for i = 0,  (MAP_H-1) do
    wall_hp[i] = {}
    for j = 0,  (MAP_W-1) do
      local m = map_data[i][j]
      if m == 8 then
        add(spawn_points, {x = j*8+4, y = i*8+4})
      elseif m == 2 then
        wall_hp[i][j] = WALL_HP
      end
    end
  end
  
  spawn_points_copy = copy_table(spawn_points_copy)
  
  gen_mapsurf()
end


function draw_map()
  local w,h = screen_size()
  local x,y = get_camera_pos()
  local sx,sy = 0,0

  if x<0 then sx,x,w = -x,0,w-x end
  if y<0 then sy,y,h = -y,0,h-y end
  
  local ssw,ssh = surface_size(map_ground_surf)
  if x+w > ssw then w = ssw-x end
  if y+h > ssh then h = ssh-y end

  palt(0,false)
  draw_surface(map_ground_surf, sx, sy, x, y, w, h)
  palt(0,true)
  
  pal(7,14)
  for _,s in pairs(wall_flash) do
    local xx,yy = s.x*8+4, s.y*8+4
    spr(0,xx-x+sx, yy-y+sy)
  end
  pal(7,7)
end

function draw_map_top()
  local w,h = screen_size()
  local x,y = get_camera_pos()
  local sx,sy = 0,0
  
  y = y + 8

  if x<0 then sx,x,w = -x,0,w-x end
  if y<0 then sy,y,h = -y,0,h-y end
  
  local ssw,ssh = surface_size(map_wall_surf)
  if x+w > ssw then w = ssw-x end
  if y+h > ssh then h = ssh-y end

  palt(0,false)
  draw_surface(map_wall_surf, sx, sy, x, y, w, h)
  palt(0,true)
  
  pal(7,14)
  for i,s in pairs(wall_flash) do
    local xx,yy = s.x*8+4, s.y*8+4
    spr(0,xx-x+sx, yy-y+sy)
    
    s.t = s.t-delta_time
    if s.t <= 0 then
      delat(wall_flash, i)
    end
  end
  pal(7,7)
end

wall_flash = {}

-- x and y have to be tile coordinates (so flr(world_x/8))
function hurt_wall(x,y,dmg)
  if not server_only then
    add(wall_flash,{x=x, y=y, t=0.03})
    
    for i=1,2 do
      create_leaf(x*8+4, y*8+4)
    end
    
    return
  end
  
  -- if x==0 or y==0 or x==MAP_W-1 or y==MAP_H-1 then return end
  if x<=0 or y<=0 or x>=MAP_W-1 or y>=MAP_H-1 then return end
  
  local hp = wall_hp[y][x]
  if not hp then
    castle_print("/!\\ Attempt to damage an inexistant wall!")
    return
  end
  
  hp = hp-dmg
  
  if hp <= 0 then
    hp = 0
    update_map_wall(x,y,false)
    castle_print("destroying wall!!")
  end
  
  wall_hp[y][x] = hp
end

growth_t = 0
function grow_walls()
  if not server_only then return end

  growth_t = growth_t - delta_time
  if growth_t > 0 then return end
  
  for i=1,16 do
    local x,y = irnd(MAP_W)-1, irnd(MAP_H)-1
    local hp = wall_hp[y][x]
  
    if hp and hp < WALL_HP then
      hp = min(hp+0.5+rnd(1), WALL_HP)
      
      if hp == WALL_HP and map_data[y][x] == 0 then
        update_map_wall(x, y, true)
      end
      
      wall_hp[y][x] = hp
    end
  end
  
  growth_t = 0.03
end

-- x and y have to be tile coordinates (so flr(world_x/8))
-- exists is true (growth) or false (destroyed)
function update_map_wall(x,y,exists,fx)
  if fx then
    add(wall_flash,{x=x, y=y, t=0.03})
    
    for i=1,4 do
      create_leaf(x*8+4, y*8+4)
    end
  end
  
  map_data[y][x] = exists and 2 or 0
  castle_print(""..map_data[y][x])
  
  update_walltile(x,y,true)
end

function update_walltile(x,y,recursive)
  if server_only then return end

  if recursive then
    update_walltile(x-1,y)
    update_walltile(x+1,y)
    update_walltile(x,y-1)
    update_walltile(x,y+1)
  end
  
  local d_line = map_data[y]
  local v = d_line[x]
  
  local xx = x*8+4
  local yy = y*8+4
  
  if v == 0 then
    if original_map[y][x] == 0 then
      return
    end
    
    draw_to(map_ground_surf)
    spr(59+irnd(4),xx,yy)
    
    draw_to(map_wall_surf)
    pal(7,6)
    spr(0,xx,yy)
    pal(7,7)
  elseif v == 2 then
    local n
    local left = (d_line[x-1] == 0)
    local right = (d_line[x+1] == 0)
    
    if left and right then
      n = 53
    elseif left then
      n = 51
    elseif right then
      n = 52
    else
      n = 47+irnd(3)
    end
    
    draw_to(map_ground_surf)
    spr(n,xx,yy)
  
  
    draw_to(map_wall_surf)
  
    local k = 0
    if x<=0       or d_line[x-1] == 2    then k = k+1 end
    if x>=MAP_W-1 or d_line[x+1] == 2    then k = k+2 end
    if y<=0       or map_data[y-1][x]==2 then k = k+4 end
    if y>=MAP_H-1 or map_data[y+1][x]==2 then k = k+8 end

    local s = 55+irnd(4)
    
    if k == 15 then
      local i = min(x,y,MAP_W-1-x,MAP_H-1-y)
      if i < 2 then
        s = 30+i
      end
    end
    
    spr(s, xx, yy)
    
    local poss = {{0},{1},{2},{0},{1},{2},{0,1},{1,2},{2,0}}
    local p = pick(poss)
    pal(11,5)
    pal(12,5)
    pal(13,5)
    for c in all(p) do
      pal(11+c,14)
    end
    
    spr(32+k, xx, yy)
    
    pal(11,11)
    pal(12,12)
    pal(13,13)
  end
  
  draw_to()
end

function check_mapcol(s,x,y,further)
  local sx = x or s.x
  local sy = y or s.y
 
  local dirs = {{-1,-1},{1,-1},{-1,1},{1,1}}
  nirs=dirs
  
  local dd = further and (server_only and 0.8 or 0.7) or 0.5
  local w = s.w
  local h = further and (s.h+2) or s.h
  
  local res,b={0,0}
 
  for k,d in pairs(dirs) do
    local x = sx+w*dd*d[1]
    local y = sy+h*dd*d[2]
    
    local tx = flr(x/8)
    local ty = flr(y/8)
    
    if tx < 0 or tx >= MAP_W or ty < 0 or ty >= MAP_H or walls[map_data[ty][tx]] then
      res[1] = res[1] + d[1]
      res[2] = res[2] + d[2]
      b=true
    end
  end
  
  if res[1]~=0 then res[1] = sgn(res[1]) end
  if res[2]~=0 then res[2] = sgn(res[2]) end
  
  return b and {dir_x = res[1], dir_y = res[2]}
end

function get_maptile(x,y)
  if not map_data[y] then return nil end
  return map_data[y][x]
end



map_ground_surf = nil
map_wall_surf = nil
function gen_mapsurf()
  if server_only then return end
  
  map_ground_surf = map_ground_surf or new_surface(MAP_W*8, MAP_H*8)
  map_wall_surf = map_wall_surf or new_surface(MAP_W*8, MAP_H*8)
  
  draw_to(map_ground_surf)
  cls(6)
  
  local flippable = {1,2,3,4,5,6,7,8,9,10,11,12,13,14,15}
  local is_flippable = {}
  for _,n in pairs(flippable) do is_flippable[n] = true end
  
  palt(0,false)
  
  for y = 0,MAP_H-2 do
    local d_line = map_data[y]
    for x = 0,MAP_W-1 do
      local v = d_line[x]
      local n = 0

      if v == 2 then
        local left = (d_line[x-1] == 0)
        local right = (d_line[x+1] == 0)
        
        if left and right then
          n = 53
        elseif left then
          n = 51
        elseif right then
          n = 52
        else
          n = 47+irnd(3)
        end
      else
        if chance(0.5) then
          n = 15
        elseif chance(1) then
          n = 6+irnd(8)
        elseif chance(20) then
          n = irnd(7)-1
        end
      end
      
      spr(n, x*8+4, y*8+4, 1, 1, 0, is_flippable[n] and chance(50))
    end
  end

  
  palt(6,true)
  for y = MAP_H-2,0,-1 do
    local d_line = map_data[y]
    for x = 0,MAP_W-1 do
      local v = d_line[x]

      if v == 2 then
        local left,right,up,down
        
        local left  = (x>0       and d_line[x-1] ~= 2)
        local right = (x<MAP_W-1 and d_line[x+1] ~= 2)
        local up    = (y>0       and map_data[y-1][x]~=2)
        local down  = (y<MAP_H-1 and map_data[y+1][x]~=2)
        
        local downleft  = (y<MAP_H-1 and x>0       and map_data[y+1][x-1]~=2)
        local downright = (y<MAP_H-1 and x<MAP_W-1 and map_data[y+1][x+1]~=2)
        
        local xx = x*8+4
        local yy = y*8+4
        
        if left then
          if up then
            spr(16, xx-8, yy-8)
          end
          
          if down then
            spr(18, xx-8, yy+8)
          end
          
          spr(19+irnd(2), xx-8, yy)
        end
        
        if right then
          if up then
            spr(17, xx+8, yy-8)
          end
          
          if down then
            spr(19, xx+8, yy+8)
          end
          
          spr(21+irnd(2), xx+8, yy)
        end
        
        if up then
          spr(26, xx, yy-8)
        end
        
        if down then
          if downleft and downright then
            spr(26+irnd(3), xx, yy+8)
          elseif downleft then
            spr(24, xx, yy+8)
          elseif downright then
            spr(25, xx, yy+8)
          else
            spr(79, xx, yy+8)
          end
        end
      end
    end
  end
  
  
  draw_to(map_wall_surf)
  cls(6)
  
  for y = 0,MAP_H-1 do
    local line = {}
    local d_line = map_data[y]
    for x = 0,MAP_W-1 do
      local v = d_line[x]

      if v == 2 then
        local k = 0
        if x<=0       or d_line[x-1] == 2    then k = k+1 end
        if x>=MAP_W-1 or d_line[x+1] == 2    then k = k+2 end
        if y<=0       or map_data[y-1][x]==2 then k = k+4 end
        if y>=MAP_H-1 or map_data[y+1][x]==2 then k = k+8 end

        local s = 55+irnd(4)
        
        if k == 15 then
          local i = min(x,y,MAP_W-1-x,MAP_H-1-y)
          if i < 2 then
            s = 30+i
          end
        end
        
        local xx = x*8+4
        local yy = y*8+4
        
        spr(s, xx, yy)
        
        local poss = {{0},{1},{2},{0},{1},{2},{0,1},{1,2},{2,0}}
        local p = pick(poss)
        pal(11,5)
        pal(12,5)
        pal(13,5)
        for c in all(p) do
          pal(11+c,14)
        end
        
        spr(32+k, xx, yy)
      end
      
    end
  end
  
  pal(11,11)
  pal(12,12)
  pal(13,13)


  
  draw_to()
  palt(0,true)
end


function reset_spawn()

  spawn_points_copy = copy_table(spawn_points)
  
end


function get_spawn()

  if #spawn_points_copy < 1 then reset_spawn() end
  
  return pick_and_remove(spawn_points_copy)
end

