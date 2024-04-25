---
-- @Liquipedia
-- wiki=starcraft2
-- page=Module:TransferRow/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--


local Arguments = require('Module:Arguments')
local Class = require('Module:Class')
local Lua = require('Module:Lua')
local Table = require('Module:Table')

local PlayerExt = Lua.import('Module:Player/Ext/Starcraft', {requireDevIfEnabled = true})
local TransferRow = Lua.import('Module:TransferRow', {requireDevIfEnabled = true})
local TransferRowDisplay = Lua.import('Module:TransferRow/Display', {requireDevIfEnabled = true})

---@class Starcraft2TransferRow: TransferRow
local CustomTransferRow = Class.new(TransferRow)

---@param frame Frame
---@return Html?
function CustomTransferRow.run(frame)
	local args = Arguments.getArgs(frame)

	--todo: move this into a function that overwrites parts of the player parsing instead of doing it in run
	for _, name, playerIndex in Table.iter.pairsByPrefix(args, 'name', {requireIndex = false}) do
		if playerIndex == 1 then
			playerIndex = ''
		end

		local race = args['race' .. playerIndex]
		local flag = args['flag' .. playerIndex]
		if not race or not flag then
			local link = args['link' .. playerIndex] or name
			local player = PlayerExt.syncPlayer{
				displayName = name,
				flag = flag,
				pageName = args['link' .. playerIndex] or mw.getContentLanguage():ucfirst(name),
				race = race,
			}
			args['race' .. playerIndex] = race or player.race
			args['flag' .. playerIndex] = flag or player.flag
			args['link' .. playerIndex] = player.pageName
		end
	end

	return CustomTransferRow(args):read():store():build()
end

---@return self
function CustomTransferRow:read()
	self.config = Table.merge(self:readConfig(), {
		iconModule = 'Module:Faction',
		iconFunction = 'Icon',
		iconParam = 'race',
		iconTransfers = false,
	})
	self.transfers = self:readInput()
	self.references = self:readReferences()

	return self
end

CustomTransferRow.displayRow = TransferRowDisplay.run

return CustomTransferRow