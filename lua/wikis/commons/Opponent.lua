---
-- @Liquipedia
-- page=Module:Opponent
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local Faction = Lua.import('Module:Faction')
local Flags = Lua.import('Module:Flags')
local FnUtil = Lua.import('Module:FnUtil')
local Logic = Lua.import('Module:Logic')
local Page = Lua.import('Module:Page')
local PlayerExt = Lua.import('Module:Player/Ext/Custom')
local String = Lua.import('Module:StringUtils')
local Table = Lua.import('Module:Table')
local TeamTemplate = Lua.import('Module:TeamTemplate')
local TypeUtil = Lua.import('Module:TypeUtil')

local BYE = 'bye'

--[[
Structural type representation of an opponent.

Examples:
{type = Opponent.solo, players = {displayName = 'Neeb'}}
{type = Opponent.team, template = 'alpha x 2020'}
{type = Opponent.literal, name = 'B2'}

See Opponent.types.Opponent for the exact encoding scheme and required fields.

- For opponent display components, see Module:OpponentDisplay.
- For input from wikicode, use {{1Opponent|...}}, {{TeamOpponent|...}} etc.
- Used by: PrizePool, GroupTableLeague, match2 Matchlist/Bracket,
StarcraftMatchSummary
- Wikis may add additional wiki-specific fields to the opponent representation.

]]
local Opponent = {types = {}}

---@enum OpponentType
local OpponentTypes = {
	team = 'team',
	solo = 'solo',
	duo = 'duo',
	trio = 'trio',
	quad = 'quad',
	literal = 'literal',
}

Opponent.team = OpponentTypes.team
Opponent.solo = OpponentTypes.solo
Opponent.duo = OpponentTypes.duo
Opponent.trio = OpponentTypes.trio
Opponent.quad = OpponentTypes.quad
Opponent.literal = OpponentTypes.literal

Opponent.partyTypes = {Opponent.solo, Opponent.duo, Opponent.trio, Opponent.quad}
Opponent.types = Array.extend(Opponent.partyTypes, {Opponent.team, Opponent.literal}) --[[@as table]]

---@enum PartySize
Opponent.partySizes = {
	solo = 1,
	duo = 2,
	trio = 3,
	quad = 4,
}

Opponent.types.Player = TypeUtil.struct({
	displayName = 'string',
	flag = 'string?',
	pageName = 'string?',
	team = 'string?',
	faction = 'string?',
	apiId = 'string?',
})

Opponent.types.TeamOpponent = TypeUtil.struct({
	template = 'string',
	type = TypeUtil.literal(Opponent.team),
	players = TypeUtil.optional(TypeUtil.array(Opponent.types.Player)),
})

Opponent.types.PartyOpponent = TypeUtil.struct({
	players = TypeUtil.array(Opponent.types.Player),
	type = TypeUtil.literalUnion(unpack(Opponent.partyTypes)),
})

Opponent.types.LiteralOpponent = TypeUtil.struct({
	name = 'string',
	type = TypeUtil.literal(Opponent.literal),
})

Opponent.types.Opponent = TypeUtil.union(
	Opponent.types.TeamOpponent,
	Opponent.types.PartyOpponent,
	Opponent.types.LiteralOpponent
)

---Checks if the provided opponent type is a party type
---@param type OpponentType?
---@return boolean
function Opponent.typeIsParty(type)
	return Opponent.partySizes[type] ~= nil
end

---Returns the player count for a party type, or nil otherwise.
---
---example: Opponent.partySize(Opponent.duo) == 2
---@param type OpponentType?
---@return PartySize?
function Opponent.partySize(type)
	return Opponent.partySizes[type]
end

---Creates a blank literal opponent, or a blank opponent of the specified type
---@param type OpponentType?
---@return standardOpponent
function Opponent.blank(type)
	if type == Opponent.team then
		return {type = type, template = 'tbd', extradata = {}}
	elseif Opponent.typeIsParty(type) then
		local partySize = Opponent.partySize(type) --[[@as integer]]
		return {
			type = type,
			players = Array.map(
				Array.range(1, partySize),
				function(_) return {displayName = ''} end
			),
			extradata = {},
		}
	else
		return {type = Opponent.literal, name = '', extradata = {}}
	end
end

---Creates a blank TBD opponent, or a TBD opponent of the specified type
---@param type OpponentType?
---@return standardOpponent
function Opponent.tbd(type)
	if type == Opponent.team then
		return {type = type, template = 'tbd', extradata = {}}
	elseif Opponent.typeIsParty(type) then
		local partySize = Opponent.partySize(type) --[[@as integer]]
		return {
			type = type,
			players = Array.map(
				Array.range(1, partySize),
				function(_) return {displayName = 'TBD'} end
			),
			extradata = {},
		}
	else
		return {type = Opponent.literal, name = 'TBD', extradata = {}}
	end
end

---Checks whether an opponent is TBD
---@param opponent standardOpponent
---@return boolean
function Opponent.isTbd(opponent)
	if opponent.type == Opponent.team then
		return opponent.template == 'tbd'

			-- The following can't occur in valid opponents, but we check for them anyway
			or opponent.name == 'TBD'
			or String.isEmpty(opponent.template)

	elseif opponent.type == Opponent.literal then
		return true

	else
		return Array.any(opponent.players, Opponent.playerIsTbd)
	end
end

---Checks if an opponent is empty
---@param opponent standardOpponent?
---@return boolean
function Opponent.isEmpty(opponent)
	-- if no type is set consider opponent as empty
	return not opponent or not opponent.type
		-- if neither name nor template nor players are set consider the opponent as empty
		or (String.isEmpty(opponent.name) and String.isEmpty(opponent.template) and Logic.isDeepEmpty(opponent.players))
end

---Checks whether an opponent is a BYE Opponent
---@param opponent standardOpponent
---@return boolean
function Opponent.isBye(opponent)
	return string.lower(opponent.name or '') == BYE
		or string.lower(opponent.template or '') == BYE
end

---Checks if a player is a TBD player
---@param player standardPlayer
---@return boolean
function Opponent.playerIsTbd(player)
	return String.isEmpty(player.displayName) or player.displayName:upper() == 'TBD'
end

---Checks if a provided string is an opponent type
---@param type string
---@return boolean
function Opponent.isType(type)
	return Table.includes(Opponent.types, type)
end

---Reads an opponent type.
---If an invalid entry is given returns nil.
---@param type string
---@return OpponentType?
function Opponent.readType(type)
	return Table.includes(Opponent.types, type) and type or nil
end

---Asserts that an arbitrary value is a valid representation of an opponent
---@param opponent any
function Opponent.assertOpponent(opponent)
	assert(Opponent.isOpponent(opponent), 'Invalid opponent')
end

---Validates that an arbitrary value is a valid representation of an opponent
---@param opponent any
---@return boolean
function Opponent.isOpponent(opponent)
	return #TypeUtil.checkValue(opponent, Opponent.types.Opponent) == 0
end

---Check if two opponents are the same opponent
---@param opponent1 standardOpponent
---@param opponent2 standardOpponent
---@return boolean
function Opponent.same(opponent1, opponent2)
	if opponent1 == opponent2 then
		return true
	elseif opponent1.type ~= opponent2.type then
		return false
	elseif opponent1.type == Opponent.literal then
		return opponent1.name == opponent2.name
	elseif opponent1.type == Opponent.team then
		if opponent1.template == opponent2.template then
			return true
		end
		local opponent1Name = Opponent.toName(opponent1)
		local opponent2Name = Opponent.toName(opponent2)
		if opponent1Name == opponent2Name then
			return true
		end
		local opponent1Historical = TeamTemplate.getRaw(opponent1Name).historicaltemplate
		local opponent2Historical = TeamTemplate.getRaw(opponent2Name).historicaltemplate
		if Logic.isEmpty(opponent1Historical) or Logic.isEmpty(opponent2Historical) then
			return false
		end
		return opponent1Historical == opponent2Historical
	end
	-- opponent.type is a party type

	---@param player standardPlayer
	---@return string?
	local function getPageName(player)
		if Opponent.playerIsTbd(player) then
			return
		end
		-- Remove gsub once underscore storage is sorted out
		return (player.pageName:gsub(' ', '_'))
	end

	return Array.equals(
		Array.sortBy(
			Array.map(opponent1.players, getPageName), FnUtil.identity
		),
		Array.sortBy(
			Array.map(opponent2.players, getPageName), FnUtil.identity
		)
	)
end

---Coerces an arbitrary table into an opponent
---@param opponent table
function Opponent.coerce(opponent)
	assert(type(opponent) == 'table')

	opponent.extradata = opponent.extradata or {}

	opponent.type = Opponent.isType(opponent.type) and opponent.type or Opponent.literal
	if opponent.type == Opponent.literal then
		opponent.name = type(opponent.name) == 'string' and opponent.name or ''
	elseif opponent.type == Opponent.team then
		if String.isEmpty(opponent.template) or type(opponent.template) ~= 'string' then
			opponent.template = 'tbd'
		end
	else
		if type(opponent.players) ~= 'table' then
			opponent.players = {}
		end
		local partySize = Opponent.partySize(opponent.type)
		opponent.players = Array.sub(opponent.players, 1, partySize)
		for _, player in ipairs(opponent.players) do
			if type(player.displayName) ~= 'string' then
				player.displayName = ''
			end
		end
		for i = #opponent.players + 1, partySize do
			opponent.players[i] = {displayName = ''}
		end
	end
end

--[[
Returns the match mode for two or more opponent types.

Example:

Opponent.toMode(Opponent.duo, Opponent.duo) == '2_2'
]]
---@param ... OpponentType
---@return string
function Opponent.toMode(...)
	local modeParts = Array.map(arg, function(opponentType)
		return Opponent.partySize(opponentType) or opponentType
	end)
	return table.concat(modeParts, '_')
end

--[[
Returns the legacy match mode for two or more opponent types.

Used by LPDB placement and tournament records, and smw records.

Example:

Opponent.toLegacyMode(Opponent.duo, Opponent.duo) == '2v2'
]]
---@param ... OpponentType
---@return string
function Opponent.toLegacyMode(...)
	local modeParts = Array.map(arg, function(opponentType)
		return Opponent.partySize(opponentType) or opponentType
	end)
	local mode = table.concat(modeParts, 'v')
	if mode == 'teamvteam' then
		return Opponent.team
	else
		return mode
	end
end

--[[
Resolves the identifiers of an opponent.

For team opponents, this resolves the team template to a particular date. For
party opponents, this fills in players' pageNames using their displayNames,
using data stored in page variables if present.

options.syncPlayer: Whether to fetch player information from variables or LPDB. Disabled by default.
]]
---@param opponent standardOpponent
---@param date string|number|nil
---@param options {syncPlayer: boolean?, overwritePageVars: boolean?}?
---@return standardOpponent
function Opponent.resolve(opponent, date, options)
	options = options or {}
	if opponent.type == Opponent.team then
		opponent.template = TeamTemplate.resolve(opponent.template, date) or opponent.template or 'tbd'
		opponent.icon, opponent.icondark = TeamTemplate.getIcon(opponent.template)
	end

	if not opponent.players then
		return opponent
	end

	Array.forEach(opponent.players, function(player)
		if options.syncPlayer then
			local hasFaction = String.isNotEmpty(player.faction)
			local savePageVar = not Opponent.playerIsTbd(player)
			PlayerExt.syncPlayer(player, {
				date = date,
				savePageVar = savePageVar,
				overwritePageVars = options.overwritePageVars,
			})
			player.team = PlayerExt.syncTeam(
				player.pageName:gsub(' ', '_'),
				player.team,
				{date = date, savePageVar = savePageVar}
			)
			player.faction = (hasFaction or player.faction ~= Faction.defaultFaction) and player.faction or nil
		else
			PlayerExt.populatePageName(player)
		end
		if player.team then
			player.team = TeamTemplate.resolve(player.team, date)
		end
	end)

	return opponent
end

--[[
Converts a opponent to a name. The name is the same as the one used in the
match2opponent.name field.

Returns nil if the team template does not exist.
]]
---@param opponent standardOpponent
---@return string
function Opponent.toName(opponent)
	if opponent.type == Opponent.team then
		local name = TeamTemplate.getPageName(opponent.template)
		-- annos expect a string return, so let it error if we get a nil return
		assert(name, 'Invalid team template: ' .. (opponent.template or ''))
		return Page.applyUnderScoresIfEnforced(name)
	elseif Opponent.typeIsParty(opponent.type) then
		local pageNames = Array.map(opponent.players, function(player)
			return Page.applyUnderScoresIfEnforced(player.pageName or player.displayName)
		end)
		table.sort(pageNames)
		return table.concat(pageNames, ' / ')
	else -- opponent.type == Opponent.literal
		return opponent.name
	end
end

--[[
Parses an argument table of an Opponent input template into an opponent struct.
Returns nil if the input is invalid.

Opponent input templates include Template:TeamOpponent, Template:SoloOpponent,
Template:LiteralOpponent, and etc.

Wikis sometimes provide variants of this function that include wiki specific
transformations.
]]
---@param args table
---@return standardOpponent
function Opponent.readOpponentArgs(args)
	local partySize = Opponent.partySize(args.type)

	if args.type == Opponent.team then
		local template = args.template or args[1]
		return template and {
			type = Opponent.team,
			template = template,
			extradata = {}
		} or Opponent.tbd(Opponent.team)

	elseif partySize == 1 then
		local player = Opponent.readSinglePlayerArgs(args)
		return {type = Opponent.solo, players = {player}, extradata = {}}

	elseif partySize then
		local players = Array.map(Array.range(1, partySize), function(playerIndex)
			return Opponent.readPlayerArgs(args, playerIndex)
		end)
		return {type = args.type, players = players, extradata = {}}

	elseif args.type == Opponent.literal then
		return {type = Opponent.literal, name = args.name or args[1] or '', extradata = {}}

	end
	error("Unknown opponent type: " .. args.type)
end

---Parses an argument table of a single player input into a player struct.
---@param args table
---@return standardPlayer
function Opponent.readSinglePlayerArgs(args)
	return Opponent.readPlayerArgs({
		[1] = args[1] or args.p1 or args.name,
		p1flag = args.flag or args.p1flag,
		p1link = args.link or args.p1link,
		p1team = args.team or args.p1team,
		p1faction = args.faction or args.race or args.p1race,
		p1id = args.id or args.p1id,
	}, 1)
end

---Parses an argument table of an opponent input into a player struct.
---@param args table
---@param playerIndex integer
---@return standardPlayer
function Opponent.readPlayerArgs(args, playerIndex)
	local playerTeam = args['p' .. playerIndex .. 'team']
	local player = {
		displayName = args[playerIndex] or args['p' .. playerIndex] or '',
		flag = String.nilIfEmpty(Flags.CountryName{flag = args['p' .. playerIndex .. 'flag']}),
		pageName = Page.applyUnderScoresIfEnforced(args['p' .. playerIndex .. 'link']),
		team = playerTeam,
		faction = Logic.nilIfEmpty(Faction.read(args['p' .. playerIndex .. 'faction']
			or args['p' .. playerIndex .. 'race'])),
		apiId = args['p' .. playerIndex .. 'id'],
	}
	assert(not player.displayName:find('|'), 'Invalid character "|" in player name')
	assert(not player.pageName or not player.pageName:find('|'), 'Invalid character "|" in player pagename')
	return player
end

--[[
Creates an opponent struct from a match2opponent record. Returns nil if
unsuccessful.

Wikis sometimes provide variants of this function that include wiki specific
transformations.
]]
---@param record match2opponent
---@return standardOpponent
function Opponent.fromMatch2Record(record)
	return Opponent._fromMatchRecord(record)
end

---@param record MGIParsedOpponent
---@return standardOpponent
function Opponent.fromMatchParsedOpponent(record)
	return Opponent._fromMatchRecord(record)
end

---@private
---@param record {type: OpponentType, template: string?, match2players: match2player[]|MGIParsedPlayer[], name: string?}
---@return standardOpponent
function Opponent._fromMatchRecord(record)
	if record.type == Opponent.team then
		return {type = Opponent.team, template = record.template, extradata = {}}

	elseif Opponent.typeIsParty(record.type) then
		return {
			type = record.type,
			players = Array.map(record.match2players, function(playerRecord)
				return {
					displayName = playerRecord.displayname,
					flag = String.nilIfEmpty(Flags.CountryName{flag = playerRecord.flag}),
					pageName = String.nilIfEmpty(playerRecord.name),
					faction = Logic.nilIfEmpty(Faction.read((playerRecord.extradata or {}).faction) or Faction.defaultFaction),
				}
			end),
			extradata = {},
		}
	elseif record.type == Opponent.literal then
		return {type = Opponent.literal, name = record.name or '', extradata = {}}

	end
	error("Unknown opponent type: " .. record.type)
end

---Reads an opponent struct and builds a standings/placement lpdb struct from it
---@param opponent standardOpponent
---@param options {setPlayersInTeam: boolean?}?
---@return {opponentname: string, opponenttemplate: string?, opponenttype: OpponentType, opponentplayers: table?}
function Opponent.toLpdbStruct(opponent, options)
	options = options or {}
	local storageStruct = {
		opponentname = Opponent.toName(opponent),
		opponenttemplate = opponent.template,
		opponenttype = opponent.type,
	}

	-- Add players for Party Type opponents, or if config is set to force it.
	if Opponent.typeIsParty(opponent.type) or options.setPlayersInTeam then
		local players = {}
		local playerCount, staffCount = 0, 0

		for _, player in ipairs(opponent.players) do
			local prefix
			local playerType = (player.extradata or {}).type
			if playerType == 'staff' then
				staffCount = staffCount + 1
				prefix = 'c' .. staffCount
			else
				playerCount = playerCount + 1
				prefix = 'p' .. playerCount
			end

			players[prefix] = Page.applyUnderScoresIfEnforced(player.pageName)
			players[prefix .. 'dn'] = player.displayName
			players[prefix .. 'flag'] = player.flag
			players[prefix .. 'team'] = player.team and
				Opponent.toName({type = Opponent.team, template = player.team, players = {}, extradata = {}}) or
				nil
			players[prefix .. 'template'] = player.team
			players[prefix .. 'faction'] = Logic.nilIfEmpty(player.faction)
			players[prefix .. 'id'] = Logic.nilIfEmpty(player.apiId)
		end
		storageStruct.opponentplayers = players
	end

	return storageStruct
end

---Reads a standings or placement lpdb structure and builds an opponent struct from it
---@param storageStruct placement|standingsentry
---@return standardOpponent
function Opponent.fromLpdbStruct(storageStruct)
	local partySize = Opponent.partySize(storageStruct.opponenttype)
	if partySize then
		local players = storageStruct.opponentplayers
		return {
			players = Array.map(Array.range(1, partySize), FnUtil.curry(Opponent.playerFromLpdbStruct, players)),
			type = storageStruct.opponenttype,
			extradata = {},
		}
	elseif storageStruct.opponenttype == Opponent.team then
		return {
			name = storageStruct.opponentname,
			template = storageStruct.opponenttemplate,
			type = Opponent.team,
			players = Logic.isNotEmpty(storageStruct.opponentplayers) and Array.mapIndexes(function (index)
				return Logic.nilIfEmpty(Opponent.playerFromLpdbStruct(storageStruct.opponentplayers, index))
			end) or {},
			extradata = {},
		}
	elseif storageStruct.opponenttype == Opponent.literal then
		return {
			name = storageStruct.opponentname,
			type = Opponent.literal,
			extradata = {},
		}
	end
	error("Unknown opponent type: " .. storageStruct.type)
end

---Reads a standings or placement lpdb structure and builds an opponent struct from it
---@param players table
---@param playerIndex integer
---@return standardPlayer
function Opponent.playerFromLpdbStruct(players, playerIndex)
	return Opponent._personFromLpdbStruct('p', players, playerIndex)
end

---@param players table
---@param staffIndex integer
---@return standardPlayer
function Opponent.staffFromLpdbStruct(players, staffIndex)
	local parsed = Opponent._personFromLpdbStruct('c', players, staffIndex)
	if Logic.isNotEmpty(parsed) then
		parsed.extradata = {type = 'staff'}
	end
	return parsed
end

---@private
---@param roleIndicator 'p'|'c'
---@param players table
---@param playerIndex integer
---@return standardPlayer
function Opponent._personFromLpdbStruct(roleIndicator, players, playerIndex)
	local prefix = roleIndicator .. playerIndex
	return {
		displayName = players[prefix .. 'dn'],
		flag = String.nilIfEmpty(Flags.CountryName{flag = players[prefix .. 'flag']}),
		pageName = players[prefix],
		team = players[prefix .. 'template'] or players[prefix .. 'team'],
		faction = Logic.nilIfEmpty(players[prefix .. 'faction']),
		apiId = Logic.nilIfEmpty(players[prefix .. 'id']),
	}
end

---@param opponent standardOpponent
---@param options {resolveRedirect: boolean?}?
---@return {participant: string, participantlink: string, participanttemplate: string?}
function Opponent.toLegacyParticipantData(opponent, options)
	local participant

	if opponent.type == Opponent.team then
		local teamTemplate = TeamTemplate.getRawOrNil(opponent.template) or {}

		participant = teamTemplate.page or ''
		if options and options.resolveRedirect then
			participant = mw.ext.TeamLiquidIntegration.resolve_redirect(participant)
		end
	else
		participant = Opponent.toName(opponent)
	end

	return {
		participant = participant,
		participantlink = Opponent.toName(opponent),
		participanttemplate = opponent.template,
	}
end

return Opponent
