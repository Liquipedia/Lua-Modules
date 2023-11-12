---
-- @Liquipedia
-- wiki=commons
-- page=Module:Infobox/Manufacturer/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Lua = require('Module:Lua')

local Manufacturer = Lua.import('Module:Infobox/Manufacturer', {requireDevIfEnabled = true})

local CustomManufacturer = Class.new()

---@param frame Frame
---@return Html
function CustomManufacturer.run(frame)
	local manufacturer = Manufacturer(frame)

	-- add custom code here

	return manufacturer:createInfobox()
end

return CustomManufacturer
