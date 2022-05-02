---
-- @Liquipedia
-- wiki=brawlhalla
-- page=Module:Infobox/Person/Player/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Player = require('Module:Infobox/Person')
local Class = require('Module:Class')
local Variables = require('Module:Variables')
local Math = require('Module:Math')
local ActiveYears = require('Module:YearsActive')
local PlayersSignatureLegends = require('Module:PlayersSignatureLegends')

local _PAGENAME = mw.title.getCurrentTitle().prefixedText

--role stuff tables
local _ROLES = {
	['admin'] = 'Admin', ['analyst'] = 'Analyst', ['coach'] = 'Coach',
	['commentator'] = 'Commentator', ['caster'] = 'Commentator',
	['expert'] = 'Analyst', ['host'] = 'Host', ['streamer'] = 'Streamer',
	['interviewer'] = 'Interviewer', ['journalist'] = 'Journalist',
	['manager'] = 'Manager', ['map maker'] = 'Map maker',
	['observer'] = 'Observer', ['photographer'] = 'Photographer',
	['tournament organizer'] = 'Organizer', ['organizer'] = 'Organizer',
}
local _CLEAN_OTHER_ROLES = {
	['coach'] = 'Coach', ['staff'] = 'false',
	['content producer'] = 'Content producer', ['streamer'] = 'false',
}

local _CURRENT_YEAR = tonumber(os.date('%Y'))
local _statusStore

local Injector = require('Module:Infobox/Widget/Injector')
local Cell = require('Module:Infobox/Widget/Cell')

local CustomPlayer = Class.new()

local CustomInjector = Class.new(Injector)

local _args
local _player

function CustomPlayer.run(frame)
	local player = Player(frame)
	_args = player.args
	_player = player

	player.getStatusToStore = CustomPlayer.getStatusToStore
	player.adjustLPDB = CustomPlayer.adjustLPDB
	player.getPersonType = CustomPlayer.getPersonType

	player.createWidgetInjector = CustomPlayer.createWidgetInjector

	return player:createInfobox(frame)
end

function CustomInjector:parse(id, widgets)
	if id == 'role' then return {}
	elseif
		id == 'history' and
		string.match(_args.retired or '', '%d%d%d%d')
	then
		table.insert(widgets, Cell{
				name = 'Retired',
				content = {_args.retired}
			})
	end
	return widgets
end

function CustomInjector:addCustomCells(widgets)
	local yearsActive = ActiveYears.display{
		player = _PAGENAME,
	}

	local currentYearEarnings = _player.earningsPerYear[_CURRENT_YEAR]
	if currentYearEarnings then
		currentYearEarnings = Math.round{currentYearEarnings}
		currentYearEarnings = '$' .. mw.language.new('en'):formatNum(currentYearEarnings)
	end

	return {
		Cell{
			name = 'Approx. Winnings ' .. _CURRENT_YEAR,
			content = {currentYearEarnings}
		},
		Cell{name = 'Years active', content = {yearsActive}},
		Cell{name = 'Main Legends', content = {PlayersSignatureLegends.get{
			player = _PAGENAME,
		}}},
	}
end

function CustomPlayer:createWidgetInjector()
	return CustomInjector()
end

function CustomPlayer:adjustLPDB(lpdbData, _, personType)
	lpdbData.extradata.lc_id = string.lower(self.pagename)
	lpdbData.extradata.teamname = _args.team
	lpdbData.extradata.role = _args.role
	lpdbData.extradata.role2 = _args.role2
	lpdbData.extradata.activeplayer = (not _statusStore) and Variables.varDefault('isActive') or ''

	return lpdbData
end

function CustomPlayer:getStatusToStore()
	if _args.death_date then
		_statusStore = 'Deceased'
	elseif _args.retired then
		_statusStore = 'Retired'
	elseif string.lower(_args.role or 'player') ~= 'player' then
		_statusStore = 'not player'
	end
	return _statusStore
end

function CustomPlayer:getPersonType()
	local role = _args.role or _args.occupation or 'player'
	role = string.lower(role)
	local category = _ROLES[role]
	local store = category or _CLEAN_OTHER_ROLES[role] or 'Player'

	return { store = store, category = category or 'Player' }
end

return CustomPlayer
