---
-- @Liquipedia
-- wiki=rocketleague
-- page=Module:TransferRow/Display/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Logic = require('Module:Logic')
local Lua = require('Module:Lua')

local TransferDisplay = Lua.import('Module:TransferRow/Display')

local OpponentLibraries = require('Module:OpponentLibraries')
local Opponent = OpponentLibraries.Opponent
local OpponentDisplay = OpponentLibraries.OpponentDisplay

---@class RLTransferRowDisplay: TransferRowDisplay
---@field players2 standardPlayer[]?
local CustomTransferDisplay = Class.new(TransferDisplay, function(self, transfers)
		self.players2 = transfers[1].players2
		return self
end)

---@return self
function CustomTransferDisplay:to()
	if Logic.isEmpty(self.transfer.to.teams) and Logic.isNotEmpty(self.players2) then
		self.display:node(self:_displayPlayers2())
	else
		self.display:node(self:_displayTeam{
			data = self.transfer.to,
			date = self.transfer.date,
			isOldTeam = false,
		})
	end

	return self
end

---@return Html
function CustomTransferDisplay:_displayPlayers2()
	local players = self.players2
	---@cast players -nil

	-- build a fake opponent for display purposes
	---@type standardOpponent
	local opponent = {players = players, type = Opponent.quad}

	local showTeamName = self.config.showTeamName
	local cell = mw.html.create('div')
		:addClass('divCell Team NewTeam')

	if showTeamName then
		cell:css('text-align', 'left')
	end

	cell:node(OpponentDisplay.BlockPlayers{
		opponent = opponent
	})

	if Logic.isEmpty(self.transfer.to.roles) then
		return cell
	end

	return cell
		:wikitext('<br>')
		:node(self:_createRole(self.transfer.to.roles, ''))
end

return CustomTransferDisplay
