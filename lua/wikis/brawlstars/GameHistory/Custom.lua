---
-- @Liquipedia
-- page=Module:GameHistory/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Arguments = Lua.import('Module:Arguments')
local Class = Lua.import('Module:Class')
local GameHistory = Lua.import('Module:GameHistory')

---@class BrawlStarsGameHistory: GameHistory
---@operator call(table): BrawlStarsGameHistory
local Custom = Class.new(GameHistory)

---@param frame Frame
---@return Widget
function Custom.create(frame)
	local args = Arguments.getArgs(frame)
	return Custom(args):readConfig():query():build()
end

-- Override functions from GameHistory

---@param opponentIndex integer
---@param playerIndex integer
---@return string
function Custom:getCharacterKey(opponentIndex, playerIndex)
	return 'team' .. opponentIndex .. 'brawler' .. playerIndex
end

return Custom
