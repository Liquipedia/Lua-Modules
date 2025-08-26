---
-- @Liquipedia
-- page=Module:PlayerIntroduction/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')
local String = require('Module:StringUtils')
local PlayerIntroduction = Lua.import('Module:PlayerIntroduction')

--- Overrides the name display.
---@return string
function PlayerIntroduction:nameDisplay()
	return '<b>' .. self.playerInfo.id .. '</b>'
end

local originalParsePlayerInfo = PlayerIntroduction._parsePlayerInfo

--- Extends the original _parsePlayerInfo to include chess-specific data.
---@param args table
---@param playerInfo table
function PlayerIntroduction:_parsePlayerInfo(args, playerInfo)
	originalParsePlayerInfo(self, args, playerInfo)

	if playerInfo and playerInfo.extradata then
		self.playerInfo.chessTitle = playerInfo.extradata.chesstitle
		self.playerInfo.banned = playerInfo.extradata.banned == true
	end
end

local originalGameDisplay = PlayerIntroduction._gameDisplay

--- Customizes how the game is displayed.
---@return string
function PlayerIntroduction:_gameDisplay()
	local title = self.playerInfo.chessTitle
	local game = self.playerInfo.game

	if String.isNotEmpty(title) and String.isNotEmpty(game) then
		return self._addConcatText(game)
	else
		return originalGameDisplay(self)
	end
end

local originalTypeDisplay = PlayerIntroduction.typeDisplay

--- Customizes the player type display.
---@return string
function PlayerIntroduction:typeDisplay()
	local title = self.playerInfo.chessTitle

	if self.playerInfo.banned then
		return self._addConcatText('chess player')
	elseif String.isNotEmpty(title) then
		return self._addConcatText('chess ' .. title)
	else
		return originalTypeDisplay(self)
	end
end

return PlayerIntroduction
