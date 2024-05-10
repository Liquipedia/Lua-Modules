---
-- @Liquipedia
-- wiki=ageofempires
-- page=Module:Brkts/WikiSpecific
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')
local FnUtil = require('Module:FnUtil')
local Table = require('Module:Table')

local BaseWikiSpecific = Lua.import('Module:Brkts/WikiSpecific/Base')

---@class AoEBrktsWikiSpecific: BrktsWikiSpecific
local WikiSpecific = Table.copy(BaseWikiSpecific)

-- Needed for LegacyBracket to work
WikiSpecific.processMap = FnUtil.identity

return WikiSpecific