---
-- @Liquipedia
-- page=Module:TeamCard/Legacy
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local Logic = Lua.import('Module:Logic')
local Namespace = Lua.import('Module:Namespace')
local PageVariableNamespace = Lua.import('Module:PageVariableNamespace')
local Template = Lua.import('Module:Template')
local Tournament = Lua.import('Module:Tournament')

local TeamParticipantsController = Lua.import('Module:TeamParticipants/Controller')

local HtmlWidgets = Lua.import('Module:Widget/Html/All')
local WidgetUtil = Lua.import('Module:Widget/Util')

local teamParticipantsVars = PageVariableNamespace('TeamParticipants')

local LegacyTeamCard = {}

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

	local defaultRows, extraRows = 0, 0
	Array.forEach(cardEntries, function(card)
		defaultRows = tonumber(card.defaultRowNumber) or defaultRows
		extraRows = tonumber(card.extraRows) or extraRows
	end)

	local tpArgs = {
		minimumplayers = defaultRows + extraRows + toggleFolded.extraPlayers,
		showplayerinfo = toggleFolded.showPlayerInfo and 'true' or nil,
	}
	Array.forEach(cardEntries, function(card)
		if dependency.preprocessCard then
			card = dependency.preprocessCard(card)
		end
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
		notesWidget = HtmlWidgets.Div{
			classes = {'team-participant__notes'},
			children = Array.interleave(toggleFolded.notes, HtmlWidgets.Br{}),
		}
	end

	return HtmlWidgets.Fragment{children = WidgetUtil.collect(notesWidget, display)}
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
	local cleanQualifier = rawQualifier:gsub('%[', ''):gsub('%]', '')
	if cleanQualifier:find('|') then
		local parts = mw.text.split(cleanQualifier, '|', true)
		local link, displayName = parts[1], parts[2]
		if link:sub(1, 1) == '/' then
			link = mw.title.getCurrentTitle().fullText .. link
		end
		link = link:gsub(' ', '_')
		return displayName, link, nil
	elseif rawQualifier:sub(1, 1) == '[' then
		local parts = mw.text.split(cleanQualifier, ' ', true)
		local link = parts[1]
		table.remove(parts, 1)
		return table.concat(parts, ' '), nil, link
	else
		return rawQualifier, nil, nil
	end
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

	-- Default-DNP rules (only when no explicit played/result and no explicit dnp).
	if explicitPlayResult == nil and not Logic.readBool(tcArgs[prefix .. 'dnp']) then
		if sourceGroup == 's' and (Logic.readBool(tcArgs.subdnpdefault) or Logic.readBool(tcArgs.noVarDefault)) then
			played = false
		end
	end

	return {
		[1] = tcArgs[prefix],
		link = tcArgs[prefix .. 'link'],
		flag = tcArgs[prefix .. 'flag_o'] or tcArgs[prefix .. 'flag'],
		team = tcArgs[prefix .. 'team'],
		id = tcArgs[prefix .. 'id'],
		faction = tcArgs[prefix .. 'faction'] or tcArgs[prefix .. 'race'],
		role = tcArgs[prefix .. 'pos'],
		trophies = trophies,
		joindate = tcArgs[prefix .. 'joindate'],
		leavedate = tcArgs[prefix .. 'leavedate'],
		played = played,
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

	local role = tcArgs[prefix .. 'pos'] or 'coach'

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

	return {
		[1] = tcArgs[prefix],
		link = tcArgs[prefix .. 'link'],
		flag = tcArgs[prefix .. 'flag_o'] or tcArgs[prefix .. 'flag'],
		team = tcArgs[prefix .. 'team'],
		role = role,
		type = 'staff',
		trophies = trophies,
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
	return value:gsub(' ', '_'):lower()
end

---@param tcArgs table
---@return table[]
function LegacyTeamCard.mapPlayers(tcArgs)
	local players = {}
	local indexByKey = {}
	local maxPlayerIndex = tonumber(tcArgs.maxPlayers) or DEFAULT_MAX_PLAYER_INDEX

	local function add(person, allowOverwrite)
		local key = normalizeKey(person.link or person[1])
		if key ~= '' and indexByKey[key] then
			if allowOverwrite then
				players[indexByKey[key]] = person
			end
			return
		end
		table.insert(players, person)
		if key ~= '' then
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

	Array.forEach(indicesPresent(tcArgs, 'c', MAX_COACH_INDEX), function(i)
		table.insert(coaches, LegacyTeamCard.mapCoach(tcArgs, 'c' .. i, nil))
	end)
	Array.forEach(indicesPresent(tcArgs, 'sc', MAX_COACH_INDEX), function(i)
		table.insert(coaches, LegacyTeamCard.mapCoach(tcArgs, 'sc' .. i, 'sc'))
	end)
	Array.forEach(indicesPresent(tcArgs, 'fc', MAX_COACH_INDEX), function(i)
		table.insert(coaches, LegacyTeamCard.mapCoach(tcArgs, 'fc' .. i, 'fc'))
	end)

	Array.forEach({'t2', 't3'}, function(tab)
		local tabType = resolveTabType(tcArgs, tab)
		local sourceGroup
		if tabType == 'sub' then sourceGroup = 'sc'
		elseif tabType == 'former' then sourceGroup = 'fc'
		else sourceGroup = nil end

		Array.forEach(indicesPresent(tcArgs, tab .. 'c', MAX_COACH_INDEX), function(i)
			table.insert(coaches, LegacyTeamCard.mapCoach(tcArgs, tab .. 'c' .. i, sourceGroup))
		end)
	end)

	return coaches
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
		table.insert(notes, {[1] = tcArgs.notes, highlighted = false})
	end
	if Logic.isNotEmpty(tcArgs.inotes) then
		table.insert(notes, {[1] = tcArgs.inotes, highlighted = false})
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
