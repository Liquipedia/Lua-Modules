---
-- @Liquipedia
-- wiki=rocketleague
-- page=Module:TransferRow/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Arguments = require('Module:Arguments')
local Class = require('Module:Class')
local Flags = require('Module:Flags')
local Logic = require('Module:Logic')
local Lua = require('Module:Lua')
local Table = require('Module:Table')

local PlayerExt = Lua.import('Module:Player/Ext/Custom')
local TransferRow = Lua.import('Module:TransferRow')

---@class rlTransfer: transfer
---@field players2 standardPlayer[]?

---@class RLCustomTransferRow: TransferRow
---@field transfers rlTransfer
local CustomTransferRow = Class.new(TransferRow)

---@param frame Frame
---@return Html?
function CustomTransferRow.transfer(frame)
	return CustomTransferRow(Arguments.getArgs(frame)):read():store():build()
end

---@param frame Frame
---@return Html?
function CustomTransferRow.rumour(frame)
	local args = Arguments.getArgs(frame)
	args.isRumour = true
	return CustomTransferRow(args):read():store():readPlayers2():build()
end

---@return self
function CustomTransferRow:readPlayers2()
	local args = self.args

	local players = {}
	for prefix, displayName in Table.iter.pairsByPrefix(args, 'team2p') do
		table.insert(players, PlayerExt.populatePlayer{
			displayName = displayName,
			flag = Logic.nilIfEmpty(Flags.CountryName(args[prefix .. 'flag'])),
			pageName = args[prefix .. 'link'] or displayName,
		})
	end

	self.transfers[1].players2 = players

	return self
end

return CustomTransferRow
