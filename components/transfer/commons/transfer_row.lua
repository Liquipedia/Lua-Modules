---
-- @Liquipedia
-- wiki=commons
-- page=Module:TransferRow
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

--[[old one:
https://liquipedia.net/commons/index.php?title=Module:Transfer/dev&action=edit
]]

local Array = require('Module:Array')
local Class = require('Module:Class')
local Json = require('Module:Json')
local Logic = require('Module:Logic')
local Lua = require('Module:Lua')
local Namespace = require('Module:Namespace')
local Table = require('Module:Table')
local Variables = require('Module:Variables')

local Info = Lua.import('Module:Info', {loadData = true})
local PlayerExt = Lua.import('Module:Player/Ext/Custom')
local TransferRowDisplay = Lua.import('Module:TransferRow/Display')

---@class TransferRowConfig
---@field displayTeamName boolean
---@field iconFunction string?
---@field iconModule string?
---@field iconParam string?
---@field iconTransfers boolean
---@field platformIcons boolean
---@field referencesAsTable boolean
---@field storage boolean?
---@field syncPlayers boolean

---@class TransferRow: BaseClass
---@field config TransferRowConfig
---@field transfers transfer[]
---@field args table
---@field baseData table
local TransferRow = Class.new(
	---@param args table
	---@return self
	function(self, args)
		self.args = args

		return self
	end
)

---@return self
function TransferRow:read()
	self.config = self:readConfig()
	self.transfers = self:readInput()

	return self
end

---@return TransferRowConfig
function TransferRow:readConfig()
	return Table.merge(Info.config.squads, {
		storage = not Logic.readBool(self.args.disable_storage) and
			not Logic.readBool(Variables.varDefault('disable_LPDB_storage'))
			and Namespace.isMain()
	})
end

---@return transfer[]
function TransferRow:readInput()
	local transferSortIndex = tonumber(Variables.varDefault('transfer_sort_index')) or 0
	local args = self.args

	self.baseData = self:_readBaseData()
	self.references = self:_readReferences()

	local transfers Array.map(self:readPlayers(), function(player, playerIndex)
		playerIndex = playerIndex == 1 and '' or playerIndex

		local transfer = self:_convertToTransferStructure{
			player = player,
			index = playerIndex,
			sortIndex = transferSortIndex
		}

		transferSortIndex = transferSortIndex + 1
		return transfer
	end)

	Variables.varDefine('transfer_sort_index', transferSortIndex)

	return transfers
end

---@return table
function TransferRow:_readBaseData()
	--TODO

	--[[
			fromteam = fromTeam or '',
			fromteamtemplate = fromTeamTemplate or '',
			toteam = toTeam or '',
			toteamtemplate = toTeamTemplate or '',
			role1 = args.role1,
			role2 = args.role2,
			date = date,
			wholeteam = Logic.readBool(args.wholeteam) and 1 or 0,
			extradata = mw.ext.LiquipediaDB.lpdb_create_json({
				displaydate = args.date or '',
				fromteamsec = args.team1_2 and mw.ext.TeamTemplate.teampage(args.team1_2, date) or '',
				toteamsec = args.team2_2 and mw.ext.TeamTemplate.teampage(args.team2_2, date) or '',
				role1sec = args.role1_2 or '',
				role2sec = args.role2_2 or '',
				platform = args.platform or '',
				notable = Logic.readBool(args.notableTransfer) and 1 or nil,
			})
	]]
end

---@return standardPlayer[]
function TransferRow:readPlayers()
	local args = self.args
	local players = {}
	for _, _, playerIndex in Table.iter.pairsByPrefix(args, 'name', {requireIndex = false}) do
		playerIndex = playerIndex == 1 and '' or playerIndex
		local player = self:readPlayer(playerIndex)
		if self.config.syncPlayers then
			player = PlayerExt.syncPlayer(player)
		end
		table.insert(players, player)
	end

	return players
end

---@param playerIndex integer|string
---@return standardPlayer
function TransferRow:readPlayer(playerIndex)
	local args = self.args

	local name = args['name' .. playerIndex]

	return {
		displayName = name,
		flag = args['flag' .. playerIndex],
		pageName = args['link' .. playerIndex] or mw.getContentLanguage():ucfirst(name),
	}
end

---@param data {player: standardPlayer, index: integer|string, sortIndex: integer, references: table<integer, string[]>}
---@return transfer
function TransferRow:_convertToTransferStructure(data)
	local args = self.args
	local playerIndex = data.index
	local player = data.player

	local subs = {args['sub' .. playerIndex], args['sub' .. playerIndex .. '_2']}
	local iconData = self:readIconsAndPosition(data.player, playerIndex)

	local transfer = {}
	Table.deepMergeInto(transfer, self.baseData, {
		player = player.pageIsResolved and player.pageName or mw.ext.TeamLiquidIntegration.resolve_redirect(player.pageName),
		nationality = player.flag,
		role1 = self.baseData.role1 or self.baseData.fromteam and subs[1] and 'Substitute' or nil,
		role2 = self.baseData.role2 or self.baseData.toteam and subs[2] and 'Substitute' or nil,
		reference = todo,
		extradata = {
			position = iconData.position,
			icon = iconData.icon or '',
			icon2 = iconData.icon2 or '',
			icontype = subs[1] and 'Substitute' or '',
			displayname = player.displayName or '',
			sortindex = data.sortIndex,
		},
	})

	return transfer
end

---@param player standardPlayer
---@param playerIndex integer|string
---@return {icon: string?, icon2: string?, position: string?}
function TransferRow:readIconsAndPosition(player, playerIndex)
	--todo
end

---@return table<integer, string[]>
function TransferRow:_readReferences()
	--todo
end

---@return self
function TransferRow:store()
	if not self.config.storage then	return self end

	Array.forEach(self.transfers, function(transfer, transferIndex)
		mw.ext.LiquipediaDB.lpdb_transfer(TransferRow._objectName(transfer), Json.stringifySubTables(transfer))
	end)

	return self
end

---@param transfer transfer
---@return string
function TransferRow._objectName(transfer)
	return 'transfer_' .. transfer.date .. '_' .. string.format('%06d', transfer.extradata.transferSortIndex)
end

---@return Html?
function TransferRow:build()
	return TransferRowDisplay.run(self.transfers)
end

return TransferRow
