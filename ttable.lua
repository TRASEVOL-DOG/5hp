-- BLAST FLOCK source files
-- by TRASEVOL_DOG (https://trasevol.dog/)

require("maths")

add=table.insert
delat=table.remove
sort=table.sort

function all(ar)
  local i=0
  local k=#ar
  local lr=nil
  
  return function()
    if lr==ar[i] then
      i=i+1
    end
    lr=ar[i]
    
    if i<=k then
      return ar[i]
    end
  end
end

function del(ar,val) for i,v in ipairs(ar) do if v==val then delat(ar,i) return end end end

function pick(ar) return ar[irnd(#ar)] end

function pick_and_remove(ar) 
  index = irnd(#ar)
  temp = ar[index]
  delat(ar,index)
  return temp
end

function copy_table(ar, deep) -- /!\ be cautious with deep copy: avoid double-linked tables!
  local arr = {}
  
  if deep then
    for k,v in pairs(ar) do
      if type(v) == "table" then
        arr[k] = copy_table(v, true)
      else
        arr[k] = v
      end
    end
  else
    for k,v in pairs(ar) do
      arr[k] = v
    end
  end
  
  return arr
end