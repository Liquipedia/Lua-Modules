---
-- @Liquipedia
-- page=Module:Features/ProfileTabs/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local ProfileTabsController = Lua.import('Module:Features/ProfileTabs/Controller')

---Template entry point.
---@param frame Frame
---@return Renderable?
local function run(frame)
	return ProfileTabsController.run(frame)
end

return {
	run = run,
}
