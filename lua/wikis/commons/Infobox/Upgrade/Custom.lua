---
-- @Liquipedia
-- page=Module:Infobox/Upgrade/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Class = Lua.import('Module:Class')

local Upgrade = Lua.import('Module:Infobox/Upgrade')

---@class CustomUpgradeInfobox: UpgradeInfobox
local CustomUpgrade = Class.new(Upgrade)

---@param frame Frame
---@return Html
function CustomUpgrade.run(frame)
	local customUpgrade = CustomUpgrade(frame)
	return customUpgrade:createInfobox()
end

return CustomUpgrade
