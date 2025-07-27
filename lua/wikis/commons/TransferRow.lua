---
-- @Liquipedia
-- page=Module:TransferRow
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local Class = Lua.import('Module:Class')
local Faction = Lua.import('Module:Faction')
local Flags = Lua.import('Module:Flags')
local FnUtil = Lua.import('Module:FnUtil')
local Json = Lua.import('Module:Json')
local Logic = Lua.import('Module:Logic')
local Namespace = Lua.import('Module:Namespace')
local String = Lua.import('Module:StringUtils')
local Table = Lua.import('Module:Table')
local Variables = Lua.import('Module:Variables')

local PlayerExt = Lua.import('Module:Player/Ext/Custom')
local PositionConvert = Lua.requireIfExists('Module:PositionName/data', {loadData = true})
local TransferRowDisplay = Lua.import('Module:TransferRow/Display')
local References = Lua.import('Module:Transfer/References')

local HAS_PLATFORM_ICONS = Lua.moduleExists('Module:Platform/data')
local VALID_CONFIDENCES = {
	'certain',
	'likely',
	'possible',
	'unlikely',
	'unknown',
}

---@class TransferRow: BaseClass
---@field config {storage: boolean, isRumour: boolean}
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

---@return {storage: boolean, isRumour: boolean}
function TransferRow:readConfig()
	local isRumour = Logic.readBool(self.args.isRumour)
	return {
		storage = not isRumour and
			not Logic.readBool(self.args.disable_storage) and
			not Logic.readBool(Variables.varDefault('disable_LPDB_storage'))
			and Namespace.isMain(),
		isRumour = isRumour,
	}
end

---@return transfer[]
function TransferRow:readInput()
	local transferSortIndex = tonumber(Variables.varDefault('transfer_sort_index')) or 0

	self.baseData = self:_readBaseData()
	local players = self:readPlayers()
	self.references = self:_readReferences(#players)

	local transfers = Array.map(players, function(player, playerIndex)
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

	local date = args.date_est or args.date
	local fromDate = TransferRow._shiftDate(date)

	---@param dateInput string?
	---@param teamInput string
	---@return {name: string?, template: string?}
	local checkTeam = function(dateInput, teamInput)
		local teamData = Logic.isNotEmpty(teamInput) and mw.ext.TeamTemplate.raw(teamInput, dateInput)
		if not teamData then
			return {}
		end
		return {name = teamData.page, template = teamData.templatename}
	end

	local toTeam = Array.map({args.team2 or '', args.team2_2 or ''}, FnUtil.curry(checkTeam, date))
	local fromTeam = Array.map({args.team1 or '', args.team1_2 or ''}, FnUtil.curry(checkTeam, fromDate))

	if Logic.isDeepEmpty(fromTeam) and String.isNotEmpty(args.team1) then
		error('Missing team template for team ' .. args.team1)
	end
	if Logic.isDeepEmpty(toTeam) and String.isNotEmpty(args.team2) then
		error('Missing team template for team ' .. args.team2)
	end
	---@param str string?
	---@return string?
	local ucFirst = function(str)
		return str and String.upperCaseFirst(str) or nil
	end

	---@param data {name: string?, template: string?}[]
	---@param teamData string[]
	---@return string[]
	---@return {name: string?, template: string?}[]
	local switchInactiveIfAppropriate = function(data, teamData)
		if data[1] ~= 'Inactive' or Logic.isEmpty(data[2]) or data[2] == 'Inactive' then
			return data, teamData
		end
		return {data[2], data[1]}, {teamData[2], teamData[1]}
	end

	local fromRole, toRole
	fromRole, fromTeam = switchInactiveIfAppropriate(Array.map({args.role1, args.role1_2}, ucFirst), fromTeam)
	toRole, toTeam = switchInactiveIfAppropriate(Array.map({args.role2, args.role2_2}, ucFirst), toTeam)

	return {
		date = date,
		fromteam = fromTeam[1].name or '',
		fromteamtemplate = fromTeam[1].template or '',
		toteam = toTeam[1].name or '',
		toteamtemplate = toTeam[1].template or '',
		role1 = fromRole[1],
		role2 = toRole[1],
		wholeteam = Logic.readBool(args.wholeteam) and 1 or 0,
		extradata = Table.merge(self:_getRumourInformation(), {
			displaydate = args.date or '',
			fromteamsec = fromTeam[2].name or '',
			fromteamsectemplate = fromTeam[2].template or '',
			toteamsec = toTeam[2].name or '',
			toteamsectemplate = toTeam[2].template or '',
			notable = Logic.readBool(args.notableTransfer) and 1 or nil,
			role1sec = fromRole[2] or '',
			role2sec = toRole[2] or '',
			platform = self:readPlatform(),
		}),
	}
end

---@return {}
function TransferRow:_getRumourInformation()
	if not self.config.isRumour then return {} end

	local args = self.args

	local confidence = (args.confidence or 'unknown'):lower()
	assert(Table.includes(VALID_CONFIDENCES, confidence), 'Invalid confidence "' .. confidence .. '"')

	local confirmed = Logic.readBoolOrNil(args.confirmed)

	return {
		confirmed = confirmed and 'correct' or (confirmed == false and 'wrong') or 'uncertain',
		confidence = confidence,
		isRumour = true,
	}

end

---@return string
function TransferRow:readPlatform()
	if not HAS_PLATFORM_ICONS then return '' end
	local Platform = Lua.import('Module:Platform')
	self.args.platform = Platform._getName(self.args.platform) or ''
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

---@return transferPlayer[]
function TransferRow:readPlayers()
	local args = self.args
	local players = {}
	for _, _, playerIndex in Table.iter.pairsByPrefix(args, 'name', {requireIndex = false}) do
		table.insert(players, PlayerExt.syncPlayer(self:readPlayer(playerIndex == 1 and '' or playerIndex)))
	end

	return players
end

---@param playerIndex integer|string
---@return transferPlayer
function TransferRow:readPlayer(playerIndex)
	local args = self.args

	local name = args['name' .. playerIndex]

	return {
		displayName = name,
		flag = args['flag' .. playerIndex],
		pageName = args['link' .. playerIndex] or mw.getContentLanguage():ucfirst(name),
		faction = args['faction' .. playerIndex] or args['race' .. playerIndex],
		chars = Array.parseCommaSeparatedString(args['head' .. playerIndex]),
	}
end

---@param data {player: transferPlayer, index: integer|string, sortIndex: integer}
---@return transfer
function TransferRow:_convertToTransferStructure(data)
	local args = self.args
	local playerIndex = data.index == 1 and '' or data.index
	local player = data.player

	local subs = {args['sub' .. playerIndex], args['sub' .. playerIndex .. '_2']}
	local icons, positions = self:readIconsAndPosition(playerIndex)

	return Table.merge(self.baseData, {
		player = player.pageIsResolved and player.pageName or mw.ext.TeamLiquidIntegration.resolve_redirect(player.pageName),
		nationality = Flags.CountryName{flag = player.flag},
		role1 = self.baseData.role1 or self.baseData.fromteam and subs[1] and 'Substitute' or nil,
		role2 = self.baseData.role2 or self.baseData.toteam and subs[2] and 'Substitute' or nil,
		reference = self.references[data.index] or self.references.all or {reference1 = ''},
		extradata = Table.merge(self.baseData.extradata, {
			position = positions[1] or '',
			icon = icons[1] or '',
			icon2 = icons[2] or '',
			icontype = subs[1] and 'Substitute' or '',
			displayname = player.displayName or '',
			sortindex = data.sortIndex,
			faction = player.faction and Faction.read(player.faction),
			chars = player.chars,
		}),
	})
end

---@param playerIndex integer|string
---@return string[] #icons
---@return string[] #positions
function TransferRow:readIconsAndPosition(playerIndex)
	local args = self.args

	local postfixes = {playerIndex, playerIndex .. '_2'}

	local positions = Array.map(postfixes, function(postfix) return args['pos' .. postfix] end)

	if PositionConvert then
		positions = Array.map(positions, function(pos)
			return PositionConvert[(pos or ''):lower()] or pos
		end)
	end

	local icons = Array.map(positions, function(iconInput, iconIndex)
		if not iconInput or not args['sub' .. postfixes[iconIndex]] then
			return iconInput
		end
		return iconInput .. '_Substitute'
	end)

	icons[2] = icons[2] or icons[1]

	return icons, positions
end

---@param numberOfPlayers integer
---@return table
function TransferRow:_readReferences(numberOfPlayers)
	if Logic.isEmpty(self.args.ref) then
		return {}
	end

	local references = References.read(self.args.ref)

	-- same amount of players and references? individually allocate them for LPDB storage
	-- special case: 2 refs/players (often times this will be a reference from both teams)
	local allRef = #references ~= numberOfPlayers or
		(#references <= 2 and Logic.isNotEmpty(self.args.team1) and Logic.isNotEmpty(self.args.team2))

	if not allRef then
		return Array.map(references, function(ref)
			return References.addReferenceToStorageData({}, ref, 1)
		end)
	end

	return {all = References.toStorageData(references)}
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
	return 'transfer_' .. transfer.date .. '_' .. string.format('%06d', transfer.extradata.sortindex)
end

---@return Html?
function TransferRow:build()
	return TransferRowDisplay(self.transfers):build()
end

return TransferRow
