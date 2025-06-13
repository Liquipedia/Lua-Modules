---
-- @Liquipedia
-- page=Module:PlayerIntroduction/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local AnOrA = require('Module:A or an')
local Arguments = require('Module:Arguments')
local Class = require('Module:Class')
local Lua = require('Module:Lua')
local String = require('Module:StringUtils')
local Table = require('Module:Table')

local PlayerIntroduction = Lua.import('Module:PlayerIntroduction')

local TRANSFER_STATUS_CURRENT = 'current'
local TYPE_PLAYER = 'player'
local INACTIVE_ROLE = 'inactive'

---@class Formula1PlayerIntroduction: PlayerIntroduction
local CustomPlayerIntroduction = Class.new(PlayerIntroduction)

-- module entry point for PlayerIntroduction
---@param args playerIntroArgsValues?
---@return string
function CustomPlayerIntroduction.run(args)
	return CustomPlayerIntroduction(args):queryPlayerInfo():queryTransferData(true):adjustData():create()
end

-- template entry point for PlayerIntroduction
---@param frame Frame
---@return string
function CustomPlayerIntroduction.templatePlayerIntroduction(frame)
	return CustomPlayerIntroduction.run(Arguments.getArgs(frame))
end

---@param isCurrentTense boolean
---@return string
function CustomPlayerIntroduction:playedOrWorked(isCurrentTense)
	local playerInfo = self.playerInfo
	local transferInfo = self.transferInfo
	local role = self.transferInfo.standardizedRole

	if playerInfo.type ~= TYPE_PLAYER and isCurrentTense then
		return 'working for'
	elseif playerInfo.type ~= TYPE_PLAYER then
		return 'worked for'
	elseif not isCurrentTense then
		return 'drove for'
	elseif transferInfo.role == INACTIVE_ROLE and transferInfo.type == TRANSFER_STATUS_CURRENT then
		return 'is an inactive driver for'
	elseif self.options.showRole and role == 'streamer' or role == 'content creator' then
		return AnOrA.main{role} .. ' for'
	elseif self.options.showRole and String.isNotEmpty(role) then
		return 'driving as ' .. AnOrA.main{role} .. ' for'
	end

	return ' driving for'
end

---@return string?
function CustomPlayerIntroduction:typeDisplay()
	local isNotOfTypePlayer = self.playerInfo.type ~= TYPE_PLAYER
	local typeDisplay = isNotOfTypePlayer and self.playerInfo.type or 'driver'
	return self._addConcatText(typeDisplay)
		.. self._addConcatText(
			isNotOfTypePlayer and String.isNotEmpty(self.playerInfo.role2) and self.playerInfo.role2 or nil,
		' and ')
end

---@return string
function CustomPlayerIntroduction:nameDisplay()
	local nameDisplay = '<b>' .. self.playerInfo.id .. '</b>'

	if Table.isNotEmpty(self.playerInfo.formerlyKnownAs) then
		nameDisplay = nameDisplay .. self._addConcatText('(formerly known as ')
			.. mw.text.listToText(self.playerInfo.formerlyKnownAs, ', ', ' and ')
			.. ')'
	end

	if Table.isNotEmpty(self.playerInfo.alsoKnownAs) then
		nameDisplay = nameDisplay .. self._addConcatText('(also known as ')
			.. mw.text.listToText(self.playerInfo.alsoKnownAs, ', ', ' and ')
			.. ')'
	end

	return nameDisplay
end

return CustomPlayerIntroduction
