request = function()
  wrk.method = "GET"
  return wrk.format(nil, "/")
end
