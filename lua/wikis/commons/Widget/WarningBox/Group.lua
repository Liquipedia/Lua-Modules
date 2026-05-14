---
-- @Liquipedia
-- page=Module:Widget/WarningBox/Group
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local Logic = Lua.import('Module:Logic')

local Component = Lua.import('Module:Widget/Component')
local WarningBox = Lua.import('Module:Widget/WarningBox')

---@param props {data: (string|number)[]?}
---@return VNode[]?
function WarningBoxGroup(props)
	local data = props.data
	if Logic.isEmpty(data) then
		return
	end
	---@cast data -nil
	return Array.map(data, function (warning)
		return WarningBox{text = warning}
	end)
end

return Component.component(WarningBoxGroup)
