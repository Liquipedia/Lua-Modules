---
-- @Liquipedia
-- wiki=commons
-- page=Module:Opponent
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Flags = require('Module:Flags')
local Logic = require('Module:Logic')
local Lua = require('Module:Lua')
local String = require('Module:StringUtils')
local Table = require('Module:Table')
local TeamTemplate = require('Module:TeamTemplate')
local TypeUtil = require('Module:TypeUtil')

local PlayerExt = Lua.import('Module:Player/Ext/Custom')

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
})

Opponent.types.TeamOpponent = TypeUtil.struct({
	template = 'string',
	type = TypeUtil.literal(Opponent.team),
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
		return {type = type, template = 'tbd'}
	elseif Opponent.typeIsParty(type) then
		local partySize = Opponent.partySize(type) --[[@as integer]]
		return {
			type = type,
			players = Array.map(
				Array.range(1, partySize),
				function(_) return {displayName = ''} end
			),
		}
	else
		return {type = Opponent.literal, name = ''}
	end
end

---Creates a blank TBD opponent, or a TBD opponent of the specified type
---@param type OpponentType?
---@return standardOpponent
function Opponent.tbd(type)
	if type == Opponent.team then
		return {type = type, template = 'tbd'}
	elseif Opponent.typeIsParty(type) then
		local partySize = Opponent.partySize(type) --[[@as integer]]
		return {
			type = type,
			players = Array.map(
				Array.range(1, partySize),
				function(_) return {displayName = 'TBD'} end
			),
		}
	else
		return {type = Opponent.literal, name = 'TBD'}
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

---Asserts that an arbitary value is a valid representation of an opponent
---@param opponent any
function Opponent.assertOpponent(opponent)
	assert(Opponent.isOpponent(opponent), 'Invalid opponent')
end

---Validates that an arbitary value is a valid representation of an opponent
---@param opponent any
---@return boolean
function Opponent.isOpponent(opponent)
	error('Opponent.isOpponent: Not Implemented')
end

---Coerces an arbitary table into an opponent
---@param opponent table
function Opponent.coerce(opponent)
	assert(type(opponent) == 'table')

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
	elseif Opponent.typeIsParty(opponent.type) then
		for _, player in ipairs(opponent.players) do
			if options.syncPlayer then
				local savePageVar = not Opponent.playerIsTbd(player)
				PlayerExt.syncPlayer(player, {
					savePageVar = savePageVar,
					overwritePageVars = options.overwritePageVars,
				})
				player.team = PlayerExt.syncTeam(
					player.pageName:gsub(' ', '_'),
					player.team,
					{date = date, savePageVar = savePageVar}
				)
			else
				PlayerExt.populatePageName(player)
			end
			if player.team then
				player.team = TeamTemplate.resolve(player.team, date)
			end
		end
	end
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
		return TeamTemplate.getPageName(opponent.template)
	elseif Opponent.typeIsParty(opponent.type) then
		local pageNames = Array.map(opponent.players, function(player)
			return player.pageName or player.displayName
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
		}

	elseif partySize == 1 then
		local player = {
			displayName = args[1] or args.p1 or args.name or '',
			flag = String.nilIfEmpty(Flags.CountryName(args.flag or args.p1flag)),
			pageName = args.link or args.p1link,
			team = args.team or args.p1team,
		}
		return {type = Opponent.solo, players = {player}}

	elseif partySize then
		local players = Array.map(Array.range(1, partySize), function(playerIndex)
			local playerTeam = args['p' .. playerIndex .. 'team']
			return {
				displayName = args[playerIndex] or args['p' .. playerIndex] or '',
				flag = String.nilIfEmpty(Flags.CountryName(args['p' .. playerIndex .. 'flag'])),
				pageName = args['p' .. playerIndex .. 'link'],
				team = playerTeam,
			}
		end)
		return {type = args.type, players = players}

	elseif args.type == Opponent.literal then
		return {type = Opponent.literal, name = args.name or args[1] or ''}

	end
	error("Unknown opponent type: " .. args.type)
end

--[[
Creates an opponent struct from a match2opponent record. Returns nil if
unsuccessful.

Wikis sometimes provide variants of this function that include wiki specific
transformations.
]]
---@param record table
---@return standardOpponent
function Opponent.fromMatch2Record(record)
	if record.type == Opponent.team then
		return {type = Opponent.team, template = record.template}

	elseif Opponent.typeIsParty(record.type) then
		return {
			type = record.type,
			players = Array.map(record.match2players, function(playerRecord)
				return {
					displayName = playerRecord.displayname,
					flag = String.nilIfEmpty(Flags.CountryName(playerRecord.flag)),
					pageName = String.nilIfEmpty(playerRecord.name),
				}
			end),
		}

	elseif record.type == Opponent.literal then
		return {type = Opponent.literal, name = record.name or ''}

	end
	error("Unknown opponent type: " .. record.type)
end

---Reads an opponent struct and builds a standings/placement lpdb struct from it
---@param opponent standardOpponent
---@return {opponentname: string, opponenttemplate: string?, opponenttype: OpponentType, opponentplayers: table?}
function Opponent.toLpdbStruct(opponent)
	local storageStruct = {
		opponentname = Opponent.toName(opponent),
		opponenttemplate = opponent.template,
		opponenttype = opponent.type,
	}

	-- Add players for Party Type opponents.
	-- Team's will have their players added via the TeamCard.
	if Opponent.typeIsParty(opponent.type) then
		local players = {}
		for playerIndex, player in ipairs(opponent.players) do
			local prefix = 'p' .. playerIndex

			players[prefix] = player.pageName
			players[prefix .. 'dn'] = player.displayName
			players[prefix .. 'flag'] = player.flag
			players[prefix .. 'team'] = player.team and
				Opponent.toName({type = Opponent.team, template = player.team, players = {}}) or
				nil
			players[prefix .. 'template'] = player.team
		end
		storageStruct.opponentplayers = players
	end

	return storageStruct
end

---Reads a standings or placement lpdb structure and builds an opponent struct from it
---@param storageStruct table
---@return standardOpponent
function Opponent.fromLpdbStruct(storageStruct)
	local partySize = Opponent.partySize(storageStruct.opponenttype)
	if partySize then
		local players = storageStruct.opponentplayers
		local function playerFromLpdbStruct(playerIndex)
			return {
				displayName = players['p' .. playerIndex .. 'dn'],
				flag = Flags.CountryName(players['p' .. playerIndex .. 'flag']),
				pageName = players['p' .. playerIndex],
				team = players['p' .. playerIndex .. 'team'],
			}
		end
		local opponent = {
			players = Array.map(Array.range(1, partySize), playerFromLpdbStruct),
			type = storageStruct.opponenttype,
		}
		return opponent
	elseif storageStruct.opponenttype == Opponent.team then
		return {
			name = storageStruct.opponentname,
			template = storageStruct.opponenttemplate,
			type = Opponent.team,
		}
	elseif storageStruct.opponenttype == Opponent.literal then
		return {
			name = storageStruct.opponentname,
			type = Opponent.literal,
		}
	end
	error("Unknown opponent type: " .. storageStruct.type)
end

return Opponent
