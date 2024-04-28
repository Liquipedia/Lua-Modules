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
local String = require('Module:StringUtils')
local Table = require('Module:Table')
local Variables = require('Module:Variables')

local Info = Lua.import('Module:Info', {loadData = true})
local PlayerExt = Lua.import('Module:Player/Ext/Custom')
local TransferRowDisplay = Lua.import('Module:TransferRow/Display')

---@class TransferRowConfig
---@field showTeamName boolean
---@field iconModule string?
---@field iconParam string?
---@field iconTransfers boolean
---@field platformIcons boolean
---@field positionConvert string?
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

	self.baseData = self:_readBaseData()
	local players = self:readPlayers()
	self.references = self:_readReferences(#players)

	local transfers = Array.map(players, function(player, playerIndex)
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
	local args = self.args

	---@param str string?
	---@return string?
	local ucFirst = function(str)
		return str and String.upperCaseFirst(str) or nil
	end

	---@param data string[]
	---@return string[]
	local switchInactiveIfAppropriate = function(data)
		if data[1] ~= 'Inactive' or Logic.isEmpty(data[2]) or data[2] == 'Inactive' then
			return data
		end
		return {data[2], data[1]}
	end

	local fromRole = switchInactiveIfAppropriate(Array.map({args.role1, args.role1_2}, ucFirst))
	local toRole = switchInactiveIfAppropriate(Array.map({args.role2, args.role2_2}, ucFirst))

	local date = args.date_est or args.date
	local fromDate = TransferRow._shiftDate(date)

	---@param teamInput string?
	---@param dateInput string?
	---@return {name: string?, template: string?}
	local checkTeam = function(teamInput, dateInput)
		if not teamInput or not mw.ext.TeamTemplate.teamexists(teamInput) then
			return {}
		end
		local teamData = mw.ext.TeamTemplate.raw(teamInput, dateInput)
		return {name = teamData.page, template = teamData.templatename}
	end

	local toTeam = Array.map({args.team2, args.team2_2}, function(input) return checkTeam(input, date) end)
	local fromTeam = Array.map({args.team1, args.team1_2}, function(input) return checkTeam(input, fromDate) end)

	return {
		date = date,
		fromteam = toTeam[1].name or '',
		fromteamtemplate = toTeam[1].template or '',
		toteam = fromTeam[1].name or '',
		toteamtemplate = fromTeam[1].template or '',
		role1 = fromRole[1],
		role2 = toRole[1],
		wholeteam = Logic.readBool(args.wholeteam) and 1 or 0,
		extradata = {
			displaydate = args.date or '',
			fromteamsec = fromTeam[1].name or '',
			fromteamsectemplate = fromTeam[1].template or '',
			toteamsec = toTeam[2].name or '',
			toteamsectemplate = toTeam[2].template or '',
			notable = Logic.readBool(args.notableTransfer) and 1 or nil,
			role1sec = fromRole[2] or '',
			role2sec = toRole[2] or '',
			platform = self:readPlatform(),
		},
	}
end

---@return string
function TransferRow:readPlatform()
	if not self.config.platformIcons then return '' end
	local getPlatform = require('Module:Platform')
	self.args.platform = getPlatform._getName(self.args.platform) or ''
	return self.args.platform
end

---@param dateInput string?
---@return string?
function TransferRow._shiftDate(dateInput)
	if type(dateInput) ~= 'string' then return dateInput end

	local year, month, day = dateInput:match('(%d+)-(%d+)-(%d+)')
	local date = os.time{day=day, month=month, year=year}
	date = date - 86400
	return os.date( "%Y-%m-%d", date) --[[@as string]]
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
	local icons, positions = self:readIconsAndPosition(data.player, playerIndex)

	return Table.deepMergeInto({}, self.baseData, {
		player = player.pageIsResolved and player.pageName or mw.ext.TeamLiquidIntegration.resolve_redirect(player.pageName),
		nationality = player.flag,
		role1 = self.baseData.role1 or self.baseData.fromteam and subs[1] and 'Substitute' or nil,
		role2 = self.baseData.role2 or self.baseData.toteam and subs[2] and 'Substitute' or nil,
		reference = self.references.applyAll and self.references.refs or self.references.refs['reference' .. playerIndex],
		extradata = {
			position = positions[1] or '',
			icon = icons[1] or '',
			icon2 = icons[2] or '',
			icontype = subs[1] and 'Substitute' or '',
			displayname = player.displayName or '',
			sortindex = data.sortIndex,
		},
	})
end

---@param player standardPlayer
---@param playerIndex integer|string
---@return string[] #icons
---@return string[] #positions
function TransferRow:readIconsAndPosition(player, playerIndex)
	local args = self.args
	local iconParam = self.config.iconParam or 'pos'

	local postfixes = {playerIndex, playerIndex .. '_2'}

	local positions = Array.map(postfixes, function(postfix) return args[iconParam .. postfix] end)

	if self.config.positionConvert then
		self.positionConvert = self.positionConvert or mw.loadData(self.config.positionConvert)
		positions = Array.map(positions, function(pos)
			return self.positionConvert[(pos or ''):lower()] or pos
		end)
	end

	local icons = Array.map(positions, function(iconInput, iconIndex)
		if not iconInput or not args['sub' .. postfixes[iconIndex]] then
			return iconInput
		end
		return iconInput .. '_Substitute'
	end)

	return icons, positions
end

---@param numberOfPlayers integer
---@return {refs: table, applyAll: boolean}
function TransferRow:_readReferences(numberOfPlayers)
	if Logic.isEmpty(self.args.ref) or not self.config.referencesAsTable then
		return {refs = {reference1 = self.args.ref or ''}, applyAll = true}
	end

	local referencesArray = Array.parseCommaSeparatedString(self.args.ref, ';;;')

	local references = Table.map(referencesArray, function(indedx, ref)
		return 'reference' .. indedx, Logic.isNotEmpty(ref) and ref or nil
	end)

	local numberOfReferences = Table.size(references)

	-- same amount of players and references? individually allocate them for LPDB storage
	-- special case: 2 refs/players (often times this will be a reference from both teams)
	local allRef = numberOfReferences == numberOfPlayers and
		(numberOfReferences > 2 or not Logic.isEmpty(self.args.team1) or Logic.isEmpty(self.args.team2))

	return {refs = references, applyAll = allRef}
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
	return TransferRowDisplay(self.transfers):build()
end

return TransferRow
