xinspect = (o, i) ->
  i = ""  if typeof i is "undefined"
  return "[MAX ITERATIONS]"  if i.length > 50
  r = []
  for p of o
    t = typeof o[p]
    r.push i + "\"" + p + "\" (" + t + ") => " + ((if t is "object" then "object:" + xinspect(o[p], i + "  ") else o[p] + ""))
  r.join i + "\n"
