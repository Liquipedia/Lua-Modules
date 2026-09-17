---
-- @Liquipedia
-- page=Module:Countdown
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Class = Lua.import('Module:Class')

local CountdownWidget = Lua.import('Module:Widget/Countdown')

---@alias CountdownArgs CountdownWidgetProps

local Countdown = {}

---@deprecated Use Widget/Countdown instead.
---@param args CountdownArgs
---@return string
function Countdown.create(args)
	return tostring(CountdownWidget(args))
end

return Class.export(Countdown, {exports = {'create'}})
