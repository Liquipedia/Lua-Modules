---
-- @Liquipedia
-- page=Module:TeamCard/Legacy
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Arguments = Lua.import('Module:Arguments')
local Array = Lua.import('Module:Array')
local Json = Lua.import('Module:Json')
local Logic = Lua.import('Module:Logic')
local Namespace = Lua.import('Module:Namespace')
local PageVariableNamespace = Lua.import('Module:PageVariableNamespace')
local String = Lua.import('Module:StringUtils')
local RoleUtil = Lua.import('Module:Role/Util')
local Table = Lua.import('Module:Table')
local Template = Lua.import('Module:Template')
local Tournament = Lua.import('Module:Tournament')

local TeamParticipantsController = Lua.import('Module:TeamParticipants/Controller')

local Html = Lua.import('Module:Widget/Html')
local WidgetUtil = Lua.import('Module:Widget/Util')

local teamParticipantsVars = PageVariableNamespace('TeamParticipants')
local legacyVars = PageVariableNamespace('LegacyTeamCard')

local PositionConvert = Lua.requireIfExists('Module:PositionName/data', {loadData = true}) or {}

local LegacyTeamCard = {}

---@param value string?
---@return string?
local function normalizePosition(value)
	if Logic.isEmpty(value) then return value end
	---@cast value -nil
	return PositionConvert[value:lower()] or value
end

---@param entries table[]
---@return table[], table?, table[]
local function partitionStash(entries)
	local toggles, header, cards = {}, nil, {}
	local sawHeader = false
	Array.forEach(entries, function(entry)
		local source = entry.__source or 'card'
		if source == 'toggle' then
			table.insert(toggles, entry)
		elseif source == 'header' then
			if sawHeader then
				table.insert(cards, entry)
			else
				header = entry
				sawHeader = true
			end
		else
			table.insert(cards, entry)
		end
	end)
	return toggles, header, cards
end

-- Invoked by Template:TeamCard columns start. Opens the wrapper and stashes the header entry.
---@param frame Frame
---@return string
function LegacyTeamCard.stashHeader(frame)
	legacyVars:set('wrapperOpen', 'true')
	local args = Arguments.getArgs(frame)
	args.__source = 'header'
	return Template.stashReturnValue(args, 'LegacyTeamCard')
end

-- Invoked by Template:TeamCard. Flags the page if no wrapper is open, then stashes the card entry.
---@param frame Frame
---@return string
function LegacyTeamCard.stashCard(frame)
	if not Logic.readBool(legacyVars:get('wrapperOpen')) then
		mw.ext.TeamLiquidIntegration.add_category('Pages with unwrapped Legacy TeamCard')
	end
	local args = Arguments.getArgs(frame)
	args.__source = 'card'
	return Template.stashReturnValue(args, 'LegacyTeamCard')
end

---@param dependency table<string, function>?
---@return Widget
function LegacyTeamCard.run(dependency)
	dependency = dependency or {}

	local entries = Template.retrieveReturnValues('LegacyTeamCard')
	local toggles, header, cardEntries = partitionStash(entries)

	if not header and #cardEntries > 0 then
		mw.ext.TeamLiquidIntegration.add_category('Pages with malformed Legacy TeamCard structure')
	end

	local toggleFolded = LegacyTeamCard._foldToggles(toggles)

	local processedCards = Array.map(cardEntries, function(card)
		if dependency.preprocessCard then
			return dependency.preprocessCard(card)
		end
		return card
	end)

	local tpArgs = {
		minimumplayers = 0,
		showplayerinfo = toggleFolded.showPlayerInfo and 'true' or nil,
	}
	Array.forEach(processedCards, function(card)
		table.insert(tpArgs, LegacyTeamCard.mapCard(card))
	end)

	if not Namespace.isMain() then
		tpArgs.store = 'false'
	end

	local display = TeamParticipantsController.fromTemplate(tpArgs)
	teamParticipantsVars:set('externalControlsRendered', 'true')

	local notesWidget
	if #toggleFolded.notes > 0 then
		mw.ext.TeamLiquidIntegration.add_category('Pages with Legacy TeamCard toggle note')
		notesWidget = Html.Div{
			classes = {'team-participant__notes'},
			children = Array.interleave(toggleFolded.notes, Html.Br{}),
		}
	end

	legacyVars:delete('wrapperOpen')
	return Html.Fragment{children = WidgetUtil.collect(notesWidget, display)}
end

---@param rawQualifier string|table|nil
---@return {method: string, type: string, page: string?, url: string?, text: string?}?
function LegacyTeamCard.parseQualifier(rawQualifier)
	if type(rawQualifier) == 'table' then
		rawQualifier = rawQualifier[1]
	end
	if not rawQualifier or rawQualifier == '' then
		return nil
	end

	local trimmed = mw.text.trim(rawQualifier)
	local method = trimmed:lower():match('^invited?') and 'invite' or 'qual'

	local text, internalLink, externalLink = LegacyTeamCard._parseQualifierLink(rawQualifier)

	if internalLink then
		local tournament = Tournament.getTournament(internalLink)
		return {
			method = method,
			type = tournament and 'tournament' or 'internal',
			page = internalLink,
			text = text,
		}
	elseif externalLink then
		return {
			method = method,
			type = 'external',
			url = externalLink,
			text = text,
		}
	else
		return {method = method, type = 'other', text = text}
	end
end

-- Port of Module:TeamCard/Qualifier (and Module:TeamCard/Storage._parseQualifier).
---@private
---@param rawQualifier string
---@return string?, string?, string? # (linkText, internalLink, externalLink)
function LegacyTeamCard._parseQualifierLink(rawQualifier)
	-- Some qualifier templates (e.g. {{VRS}}) categorise the page as a side effect, emitting a
	-- [[Category:...]] link into the value. Strip it so it is not mistaken for the qualifier link.
	rawQualifier = mw.text.trim((rawQualifier:gsub('%[%[:?[Cc]ategory:.-%]%]', '')))

	-- A qualifier may be prefixed with an icon (e.g. {{LeagueIconSmall}}, which expands to
	-- a File link / span before reaching here). Take the first internal wikilink that is not
	-- such an embed; the new QualifierInfo widget renders its own tournament icon.
	for inner in rawQualifier:gmatch('%[%[(.-)%]%]') do
		local lowered = inner:lower()
		local isEmbed = inner:find('<', 1, true) or Array.any({'file:', 'image:', 'media:'}, function(prefix)
			return String.startsWith(lowered, prefix)
		end)
		if not isEmbed then
			local parts = Array.parseCommaSeparatedString(inner, '|')
			local link, displayName = parts[1], parts[2] or parts[1]
			if String.startsWith(link, '/') then
				link = mw.title.getCurrentTitle().fullText .. link
			end
			return displayName, link:gsub(' ', '_'), nil
		end
	end

	if String.startsWith(rawQualifier, '[') then
		local parts = mw.text.split(rawQualifier:gsub('[%[%]]', ''), ' ', true)
		local link = table.remove(parts, 1)
		return table.concat(parts, ' '), nil, link
	end

	return rawQualifier, nil, nil
end

---@private
---@param key string
---@return boolean
function LegacyTeamCard._isSubPrefix(key)
	return key:gsub('^t%d', ''):match('^s%d+') ~= nil
end

---@param tcArgs table
---@param prefix string
---@param sourceGroup nil|'s'|'f'  -- nil for main p*, 's' for substitute source, 'f' for former
---@return table
function LegacyTeamCard.mapPlayer(tcArgs, prefix, sourceGroup)
	local wins = tonumber(tcArgs[prefix .. 'wins'])
	local winsc = tonumber(tcArgs[prefix .. 'winsc'])
	local trophies
	if wins or winsc then
		trophies = (wins or 0) + (winsc or 0)
	end

	local explicitPlayResult = Logic.readBoolOrNil(tcArgs[prefix .. 'played']
		or tcArgs[prefix .. 'result'])
	local played = explicitPlayResult
	if Logic.readBool(tcArgs[prefix .. 'dnp']) then
		played = false
	end

	local status
	if Logic.readBool(tcArgs[prefix .. 'leave']) then
		status = 'former'
	elseif Logic.readBool(tcArgs[prefix .. 'sub']) then
		status = 'sub'
	elseif sourceGroup == 's' then
		status = 'sub'
	elseif sourceGroup == 'f' then
		status = 'former'
	end

	-- subdnpdefault: subs entered via the s* group with no explicit played/result are shown as DNP
	-- (visible label + excluded from results). Restricted to real s* input (not tXpY tabs).
	if (
		explicitPlayResult == nil and
		not Logic.readBool(tcArgs[prefix .. 'dnp']) and
		sourceGroup == 's' and
		Logic.readBool(tcArgs.subdnpdefault) and
		LegacyTeamCard._isSubPrefix(prefix)
	) then
		played = false
	end

	-- noVarDefault: players entered via a sub/former source (s*/f* groups, or t2/t3 sub/former
	-- tabs) without an explicit played/result are not counted for results, but keep their normal
	-- display (no DNP label). An explicit played/result=true overrides.
	local results
	if (sourceGroup == 's' or sourceGroup == 'f')
		and Logic.readBool(tcArgs.noVarDefault)
		and explicitPlayResult ~= true then
		results = false
	end

	return {
		[1] = tcArgs[prefix],
		link = tcArgs[prefix .. 'link'],
		flag = tcArgs[prefix .. 'flag_o'] or tcArgs[prefix .. 'flag'],
		team = tcArgs[prefix .. 'team'],
		id = tcArgs[prefix .. 'id'],
		number = tcArgs[prefix .. 'number'],
		faction = tcArgs[prefix .. 'faction'] or tcArgs[prefix .. 'race'],
		role = normalizePosition(tcArgs[prefix .. 'pos']),
		trophies = trophies,
		joindate = tcArgs[prefix .. 'joindate'],
		leavedate = tcArgs[prefix .. 'leavedate'],
		played = played,
		results = results,
		status = status,
	}
end

---@param tcArgs table
---@param prefix string
---@param sourceGroup nil|'sc'|'fc'  -- nil for main c*, 'sc' for sub-coach source, 'fc' for former-coach source
---@return table
function LegacyTeamCard.mapCoach(tcArgs, prefix, sourceGroup)
	local wins = tonumber(tcArgs[prefix .. 'wins'])
	local winsc = tonumber(tcArgs[prefix .. 'winsc'])
	local trophies
	if wins or winsc then
		trophies = (wins or 0) + (winsc or 0)
	end

	local role = normalizePosition(tcArgs[prefix .. 'pos']) or 'coach'

	local status
	if Logic.readBool(tcArgs[prefix .. 'leave']) then
		status = 'former'
	elseif Logic.readBool(tcArgs[prefix .. 'sub']) then
		status = 'sub'
	elseif sourceGroup == 'sc' then
		status = 'sub'
	elseif sourceGroup == 'fc' then
		status = 'former'
	end

	-- noVarDefault: sub/former coaches without an explicit played/result are not counted for
	-- results (an explicit played/result=true, e.g. fcresult=true, overrides). Coaches are
	-- never shown as DNP, so only results (not played) is affected.
	local explicitPlayResult = Logic.readBoolOrNil(tcArgs[prefix .. 'played'] or tcArgs[prefix .. 'result'])
	local results
	if Logic.readBool(tcArgs[prefix .. 'dnp']) then
		results = false
	elseif (sourceGroup == 'sc' or sourceGroup == 'fc')
		and Logic.readBool(tcArgs.noVarDefault)
		and explicitPlayResult ~= true then
		results = false
	end

	return {
		[1] = tcArgs[prefix],
		link = tcArgs[prefix .. 'link'],
		flag = tcArgs[prefix .. 'flag_o'] or tcArgs[prefix .. 'flag'],
		team = tcArgs[prefix .. 'team'],
		role = role,
		type = 'staff',
		trophies = trophies,
		results = results,
		status = status,
	}
end

local DEFAULT_MAX_PLAYER_INDEX = 10
local MAX_COACH_INDEX = 10

local TN_TYPE_DEFAULTS = {t2 = 'sub', t3 = 'former'}

local TN_TITLE_TO_TYPE = {
	['substitutes'] = 'sub',
	['substitute'] = 'sub',
	['subs'] = 'sub',
	['former'] = 'former',
	['former players'] = 'former',
	['former roster'] = 'former',
	['staff'] = 'staff',
}

---@param tcArgs table
---@param tab string
---@return string
local function resolveTabType(tcArgs, tab)
	local title = tcArgs[tab .. 'title']
	if Logic.isNotEmpty(title) then
		local mapped = TN_TITLE_TO_TYPE[title:lower()]
		if mapped then return mapped end
	end
	return (tcArgs[tab .. 'type'] or TN_TYPE_DEFAULTS[tab]):lower()
end

---@param tcArgs table
---@param prefix string
---@param maxIndex integer
---@return integer[]
local function indicesPresent(tcArgs, prefix, maxIndex)
	return Array.filter(Array.range(1, maxIndex), function(i)
		return Logic.isNotEmpty(tcArgs[prefix .. i])
	end)
end

---@param value string?
---@return string
local function normalizeKey(value)
	if Logic.isEmpty(value) then return '' end
	---@cast value -nil
	return value:gsub(' ', '_'):lower()
end

-- Mirrors the staff classification in TeamParticipants/Parse/Wiki so a person listed as
-- both player and staff (e.g. coach subbing in as player) keeps both entries.
---@param person table
---@return boolean
local function isStaffCapacity(person)
	if person.type == 'staff' then
		return true
	end
	if Logic.isEmpty(person.role) then
		return false
	end
	return Array.any(RoleUtil.readRoleArgs(person.role), function(role)
		return role.type == RoleUtil.ROLE_TYPE.STAFF
	end)
end

---@param tcArgs table
---@return table[]
function LegacyTeamCard.mapPlayers(tcArgs)
	local players = {}
	local indexByKey = {}
	local maxPlayerIndex = tonumber(tcArgs.maxPlayers) or DEFAULT_MAX_PLAYER_INDEX

	-- Legacy commons TC alias: <group>posN was an accepted alternative for <prefix>Npos.
	Array.forEach({{'', 'p'}, {'t2', 't2p'}, {'t3', 't3p'}}, function(pair)
		local group, prefix = pair[1], pair[2]
		Array.forEach(Array.range(1, maxPlayerIndex), function(n)
			local newKey = prefix .. n .. 'pos'
			tcArgs[newKey] = Logic.emptyOr(tcArgs[newKey], Table.extract(tcArgs, group .. 'pos' .. n))
		end)
	end)

	local function add(person, allowOverwrite)
		local key = normalizeKey(person.link or person[1])
		-- Dedup only within the same capacity: a staff entry must not replace a player entry.
		if Logic.isNotEmpty(key) and isStaffCapacity(person) then
			key = key .. '::staff'
		end
		if Logic.isNotEmpty(key) and indexByKey[key] then
			if allowOverwrite then
				players[indexByKey[key]] = person
			end
			return
		end
		table.insert(players, person)
		if Logic.isNotEmpty(key) then
			indexByKey[key] = #players
		end
	end

	Array.forEach(indicesPresent(tcArgs, 'p', maxPlayerIndex), function(i)
		add(LegacyTeamCard.mapPlayer(tcArgs, 'p' .. i, nil), false)
	end)
	Array.forEach(indicesPresent(tcArgs, 's', maxPlayerIndex), function(i)
		add(LegacyTeamCard.mapPlayer(tcArgs, 's' .. i, 's'), false)
	end)
	Array.forEach(indicesPresent(tcArgs, 'f', maxPlayerIndex), function(i)
		add(LegacyTeamCard.mapPlayer(tcArgs, 'f' .. i, 'f'), false)
	end)

	Array.forEach({'t2', 't3'}, function(tab)
		local tabType = resolveTabType(tcArgs, tab)
		local sourceGroup
		if tabType == 'sub' then sourceGroup = 's'
		elseif tabType == 'former' then sourceGroup = 'f'
		else sourceGroup = nil end

		Array.forEach(indicesPresent(tcArgs, tab .. 'p', maxPlayerIndex), function(i)
			local person = LegacyTeamCard.mapPlayer(tcArgs, tab .. 'p' .. i, sourceGroup)
			if tabType == 'staff' then
				person.type = 'staff'
			end
			add(person, true)
		end)
	end)

	return players
end

---@param tcArgs table
---@return table[]
function LegacyTeamCard.mapCoaches(tcArgs)
	local coaches = {}

	if Logic.isNotEmpty(tcArgs.c) then
		table.insert(coaches, LegacyTeamCard.mapCoach(tcArgs, 'c', nil))
	end
	Array.forEach(indicesPresent(tcArgs, 'c', MAX_COACH_INDEX), function(i)
		table.insert(coaches, LegacyTeamCard.mapCoach(tcArgs, 'c' .. i, nil))
	end)
	-- Bare `sc`/`fc` is the first sub/former coach in legacy syntax (numbered slots start at 2).
	if Logic.isNotEmpty(tcArgs.sc) then
		table.insert(coaches, LegacyTeamCard.mapCoach(tcArgs, 'sc', 'sc'))
	end
	Array.forEach(indicesPresent(tcArgs, 'sc', MAX_COACH_INDEX), function(i)
		table.insert(coaches, LegacyTeamCard.mapCoach(tcArgs, 'sc' .. i, 'sc'))
	end)
	if Logic.isNotEmpty(tcArgs.fc) then
		table.insert(coaches, LegacyTeamCard.mapCoach(tcArgs, 'fc', 'fc'))
	end
	Array.forEach(indicesPresent(tcArgs, 'fc', MAX_COACH_INDEX), function(i)
		table.insert(coaches, LegacyTeamCard.mapCoach(tcArgs, 'fc' .. i, 'fc'))
	end)

	Array.forEach({'t2', 't3'}, function(tab)
		local tabType = resolveTabType(tcArgs, tab)
		local sourceGroup
		if tabType == 'sub' then sourceGroup = 'sc'
		elseif tabType == 'former' then sourceGroup = 'fc'
		else sourceGroup = nil end

		if tcArgs[tab .. 'c'] then
			mw.ext.TeamLiquidIntegration.add_category('Pages with malformed Legacy TeamCard coach input')
			tcArgs[tab .. 'c1'] = tcArgs[tab .. 'c']
		end

		Array.forEach(indicesPresent(tcArgs, tab .. 'c', MAX_COACH_INDEX), function(i)
			table.insert(coaches, LegacyTeamCard.mapCoach(tcArgs, tab .. 'c' .. i, sourceGroup))
		end)
	end)

	return coaches
end

---@param parsedNotes table
---@return {[1]: string, highlighted: boolean}[]
local function parseNotes(parsedNotes)
	return Array.mapIndexes(function (index)
		local note = parsedNotes['n' .. index]
		if Logic.isEmpty(note) then
			return
		end
		return {[1] = note, highlighted = false}
	end)
end

---@param tcArgs table
---@return table  -- TP opponent arg
function LegacyTeamCard.mapCard(tcArgs)
	local card = {}

	local hasContenders = Logic.isNotEmpty(tcArgs.team2) or Logic.isNotEmpty(tcArgs.team3)
	if hasContenders then
		card.contenders = {}
		Array.forEach({{'team', 'link'}, {'team2', 'link2'}, {'team3', 'link3'}}, function(pair)
			local teamArg, linkArg = pair[1], pair[2]
			local value = tcArgs[linkArg] or tcArgs[teamArg]
			if Logic.isNotEmpty(value) then
				table.insert(card.contenders, value)
			end
		end)
	else
		card[1] = tcArgs.link or tcArgs.team
	end

	if Logic.isNotEmpty(tcArgs.qualifier) then
		card.qualification = LegacyTeamCard.parseQualifier(tcArgs.qualifier)
	end

	local notes = {}
	if Logic.isNotEmpty(tcArgs.notes) then
		local parsedNotes = Json.parseIfTable(tcArgs.notes)
		if parsedNotes then
			Array.extendWith(notes, parseNotes(parsedNotes))
		else
			table.insert(notes, {[1] = tcArgs.notes, highlighted = false})
		end
	end
	if Logic.isNotEmpty(tcArgs.inotes) then
		local parsedNotes = Json.parseIfTable(tcArgs.inotes)
		if parsedNotes then
			Array.extendWith(notes, parseNotes(parsedNotes))
		else
			table.insert(notes, {[1] = tcArgs.inotes, highlighted = false})
		end
	end
	if #notes > 0 then card.notes = notes end

	card.date = tcArgs.date
	card.aliases = tcArgs.alsoknownas or tcArgs.aliases
	card.import = false

	local players = LegacyTeamCard.mapPlayers(tcArgs)
	Array.extendWith(players, LegacyTeamCard.mapCoaches(tcArgs))
	card.players = players

	return card
end

---@private
---@param toggleEntries table[]
---@return {showPlayerInfo: boolean, extraPlayers: integer, notes: string[]}
function LegacyTeamCard._foldToggles(toggleEntries)
	local result = {showPlayerInfo = false, extraPlayers = 0, notes = {}}
	Array.forEach(toggleEntries, function(entry)
		if Logic.readBool(entry.playerinfo) then
			result.showPlayerInfo = true
		end
		local extra = tonumber(entry.p_extra)
		if extra then result.extraPlayers = result.extraPlayers + extra end
		if Logic.isNotEmpty(entry.note) then
			table.insert(result.notes, entry.note)
		end
	end)
	return result
end

return LegacyTeamCard
