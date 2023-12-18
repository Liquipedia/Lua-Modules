---@meta
-- luacheck: ignore
local lpdb = {}

---@class LpdbTable
---@field pageid integer
---@field pagename string
---@field namespace integer
---@field objectname string

---@class LpdbPlacement:LpdbTable
---@field tournament string
---@field series string
---@field parent string
---@field startdate string
---@field date string #end date
---@field placement string
---@field prizemoney number
---@field individualprizemoney number
---@field prizepoolindex integer
---@field weight number
---@field mode string
---@field type string
---@field liqupediatier string # to be converted to integer
---@field liqupediatiertype string
---@field publishertier string
---@field icon string
---@field icondark string
---@field game string
---@field lastvsdata table
---@field opponentname string
---@field opponenttemplate string
---@field opponenttype string
---@field opponentplayers table
---@field qualifier string
---@field qualifierpage string
---@field qualifierurl string
---@field extradata table

---@param obj table
---@return string
---Encode a table to a JSON object. Errors are raised if the passed value cannot be encoded in JSON.
function lpdb.lpdb_create_json(obj) end

---@param obj any[]
---@return string
---Encode an Array to a JSON array. Errors are raised if the passed value cannot be encoded in JSON.
function lpdb.mw.ext.LiquipediaDB.lpdb_create_array(obj) end

return lpdb
