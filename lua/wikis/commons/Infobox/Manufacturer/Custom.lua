---
-- @Liquipedia
-- page=Module:Infobox/Manufacturer/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Class = Lua.import('Module:Class')

local Manufacturer = Lua.import('Module:Infobox/Manufacturer')

---@class CustomManufacturerInfobox: ManufacturerInfobox
local CustomManufacturer = Class.new(Manufacturer)

---@param frame Frame
---@return Html
function CustomManufacturer.run(frame)
	local manufacturer = CustomManufacturer(frame)

	-- add custom code here

	return manufacturer:createInfobox()
end

return CustomManufacturer
