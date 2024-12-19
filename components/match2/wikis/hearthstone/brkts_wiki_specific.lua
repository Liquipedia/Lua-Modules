---
-- @Liquipedia
-- wiki=hearthstone
-- page=Module:Brkts/WikiSpecific
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local FnUtil = require('Module:FnUtil')
local Lua = require('Module:Lua')
local Table = require('Module:Table')

local BaseWikiSpecific = Lua.import('Module:Brkts/WikiSpecific/Base')

---@class HearthstoneBrktsWikiSpecific: BrktsWikiSpecific
local WikiSpecific = Table.copy(BaseWikiSpecific)

WikiSpecific.matchFromRecord = FnUtil.lazilyDefineFunction(function()
	local CustomMatchGroupUtil = Lua.import('Module:MatchGroup/Util/Custom')
	return CustomMatchGroupUtil.matchFromRecord
end)


return WikiSpecific
