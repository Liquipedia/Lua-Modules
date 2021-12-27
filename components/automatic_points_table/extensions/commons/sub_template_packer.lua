---
-- @Liquipedia
-- wiki=commons
-- page=Module:SubTemplatePacker
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

---- This module fetches the arguments from a sub-template (A template used inside another template)

local Class = require('Module:Class')
local getArgs = require('Module:Arguments').getArgs
local split = require('Module:StringUtils').split

local SubTemplatePacker = {}

-- there's always the possibility of a team/tournament name having one of those two
-- characters in its name, however these are two less common characters so it'd be
-- a very rare occurence
local delimiters = {'ɖ', '≃'}

--- Packs the template call into a string.
-- Packs the template call into a string.
-- @param frame frame.
-- @return string a string representing the fetched arguments
function SubTemplatePacker.pack(frame)
  local args = getArgs(frame)
  local fetchedArgs = ''
  for key, val in pairs(args) do
    if type(key) == 'string' then
      fetchedArgs = fetchedArgs .. delimiters[1] .. key .. delimiters[2] .. val
    end
  end
  return fetchedArgs
end

--- Unpacks the sub-template string into a table.
-- Unpacks the sub-template string into a table.
-- @tparam string packedString the string representing the sub-template
-- @treturn table unpacked sub-template arguments
function SubTemplatePacker.unpack(packedString)
  local unpackedArgs = {}
  local packedArgs = split(packedString, delimiters[1])
  for _, argVal in pairs(packedArgs) do
    if string.find(argVal, delimiters[2]) then
      local ss = split(argVal, delimiters[2])
      unpackedArgs[ss[1]] = ss[2]
    end
  end
  return unpackedArgs
end

return Class.export(SubTemplatePacker)
