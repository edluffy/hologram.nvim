local m = {}

function m.keys_to_string(keys)
  local entries = {}
  for k, v in pairs(keys) do
    table.insert(entries, k .. '=' .. v)
  end
  return table.concat(entries, ',')
end

function m.bytes_to_string(data)
  local bytes = vim.tbl_flatten(data)
  local s = {}
  for i = 1, #bytes do
    s[i] = string.char(bytes[i])
  end
  return table.concat(s)
end

return m
