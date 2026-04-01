local Lua = require('Module:Lua')

local AnOrA = Lua.import('Module:A or an')
local Arguments = Lua.import('Module:Arguments')
local DateExt = Lua.import('Module:Date/Ext')
local Faction = Lua.import('Module:Faction')
local Flags = Lua.import('Module:Flags')
local Logic = Lua.import('Module:Logic')
local String = Lua.import('Module:StringUtils')
local Team = Lua.import('Module:Team')

local Disambiguation = {}

function Disambiguation.player(frame)
	local args = Arguments.getArgs(frame)
	local player = mw.ext.TeamLiquidIntegration.resolve_redirect(args.player or args[1]):gsub(' ', '_')
	local nameInput = args.name or args.id or mw.title.getCurrentTitle().text

	local data = mw.ext.LiquipediaDB.lpdb('player', {
		conditions = '[[pagename::' .. player .. ']]',
		limit = 1,
	})[1]

	if not data then
		return ''
	end

	local id = args.name or args.id or mw.title.getCurrentTitle().text

	local extraData = data.extradata

	local nameArray = mw.text.split(data.name, ' ', true)
	local firstName = Logic.emptyOr(args.firstname, extraData.firstname, table.remove(nameArray, 1))
	local lastName = Logic.emptyOr(args.lastname, extraData.lastname, table.concat(nameArray, ' '))
	local nameDisplay = firstName .. ' "[[' .. player .. '|' .. id .. ']]" ' .. lastName

	local localisation = Flags.getLocalisation(data.nationality)
	localisation = String.isNotEmpty(localisation) and (localisation .. ' ') or ''

	local isDeceased = data.deathdate ~= DateExt.defaultDate or (data.status or ''):lower() == 'deceased'

	local statusDisplay = (data.status or ''):lower() ~= 'active' and (not isDeceased) and (data.status .. ' ') or ''

	local factionDisplay = Faction.toName(extraData.faction) or ''

	local typeDisplay = Logic.emptyOr(data.type, 'player'):lower()

	local display = '* ' .. nameDisplay .. ', ' .. AnOrA._main{
		statusDisplay .. localisation .. factionDisplay .. typeDisplay,
	}

	if String.isNotEmpty(data.teamtemplate) then
		display = display .. ' currently '
		if typeDisplay == 'player' then
			display = display .. 'playing'
		else
			display = display .. 'working'
		end
		display = display .. ' for ' .. Team.team(nil, data.teamtemplate)
	end

	display = display .. '.'

	if nameInput ~= data.id then
		display = display .. ' Their current ID is ' .. data.id .. '.'
	end

	return display
end

return Disambiguation
