// BLAST FLOCK source files
// by TRASEVOL_DOG (https://trasevol.dog/)

#define PAL_SIZE 15

varying vec2 v_vTexcoord;
varying vec4 v_vColour;

extern vec3 opal[PAL_SIZE];
extern int swaps[PAL_SIZE];
extern float trsps[PAL_SIZE];

vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords)
{
  vec4 col=Texel( texture, texture_coords );
  
  int c=0;
  for (int i=0; i<PAL_SIZE; i++){
    //if (abs(col.r-opal[i].r)<0.05 && abs(col.g-opal[i].g)<0.05 && abs(col.b-opal[i].b)<0.05){
    //  c=i;
    //  break;
    //}
    
    c += i * int(max(-2.0-sign(abs(col.r-opal[i].r)-0.05)-sign(abs(col.g-opal[i].g)-0.05)-sign(abs(col.b-opal[i].b)-0.05), 0.0));
  }
  
  float trsp=1.0-trsps[c];
  
  return vec4(opal[swaps[c]],trsp);
}