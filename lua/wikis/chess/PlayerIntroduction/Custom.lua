---
-- @Liquipedia
-- page=Module:PlayerIntroduction/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')
local String = require('Module:StringUtils')
local Class = require('Module:Class')
local Arguments = require('Module:Arguments')

local PlayerIntroduction = Lua.import('Module:PlayerIntroduction')

---@class CustomPlayerIntroduction: PlayerIntroduction
local CustomPlayerIntroduction = Class.new(PlayerIntroduction)

--- Module entry point for PlayerIntroduction
---@param args playerIntroArgsValues?
---@return string
function CustomPlayerIntroduction.run(args)
	return CustomPlayerIntroduction(args):queryPlayerInfo():queryTransferData(true):adjustData():create()
end

--- Template entry point for PlayerIntroduction
---@param frame Frame
---@return string
function CustomPlayerIntroduction.templatePlayerIntroduction(frame)
	return CustomPlayerIntroduction.run(Arguments.getArgs(frame))
end

--- Overrides the name display.
---@return string
function CustomPlayerIntroduction:nameDisplay()
	return '<b>' .. self.playerInfo.id .. '</b>'
end

--- Extends the original _parsePlayerInfo to include chess-specific data.
---@param args table
---@param playerInfo table
function CustomPlayerIntroduction:_parsePlayerInfo(args, playerInfo)
	PlayerIntroduction._parsePlayerInfo(self, args, playerInfo)

	if playerInfo and playerInfo.extradata then
		self.playerInfo.chessTitle = playerInfo.extradata.chesstitle
		self.playerInfo.banned = playerInfo.extradata.banned == true
	end
end

--- Customizes how the game is displayed.
---@return string
function CustomPlayerIntroduction:_gameDisplay()
	local title = self.playerInfo.chessTitle
	local game = self.playerInfo.game

	if String.isNotEmpty(title) and String.isNotEmpty(game) then
		return self._addConcatText(game)
	else
		return PlayerIntroduction._gameDisplay(self)
	end
end

--- Customizes the player type display.
---@return string
function CustomPlayerIntroduction:typeDisplay()
	local title = self.playerInfo.chessTitle

	if self.playerInfo.banned then
		return self._addConcatText('chess player')
	elseif String.isNotEmpty(title) then
		return self._addConcatText('chess ' .. title)
	else
		return PlayerIntroduction.typeDisplay(self)
	end
end

return CustomPlayerIntroduction
