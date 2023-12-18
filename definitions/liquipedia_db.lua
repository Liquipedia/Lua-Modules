---@meta
-- luacheck: ignore
local lpdb = {}

---@class LpdbBaseData
---@field pageid integer
---@field pagename string
---@field namespace integer
---@field objectname string

---@class LpdbBroadcaster:LpdbBaseData
---@field id string
---@field name string
---@field page string
---@field position string
---@field language string
---@field flag string
---@field weight number
---@field date string
---@field parent string
---@field extradata table

---@class LpdbPlacement:LpdbBaseData
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

---@class LpdbTournament:LpdbBaseData
---@field name string
---@field shortname string
---@field tickername string
---@field banner string
---@field bannerdark string
---@field icon string
---@field icondark string
---@field seriespage string
---@field previous string
---@field previous2 string
---@field next string
---@field next2 string
---@field game string
---@field mode string
---@field patch string
---@field endpatch string
---@field type string
---@field organizers table
---@field startdate string
---@field enddate string
---@field sortdate string
---@field locations table
---@field prizepool number
---@field participantsnumber integer
---@field liqupediatier string # to be converted to integer
---@field liqupediatiertype string
---@field publishertier string
---@field status string
---@field maps string
---@field format string
---@field sponsors table
---@field extradata table

---@param obj table
---@return string
---Encode a table to a JSON object. Errors are raised if the passed value cannot be encoded in JSON.
function lpdb.lpdb_create_json(obj) end

---@param obj any[]
---@return string
---Encode an Array to a JSON array. Errors are raised if the passed value cannot be encoded in JSON.
function lpdb.lpdb_create_array(obj) end

return lpdb
