---
-- @Liquipedia
-- page=Module:Disambiguation
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local AnOrA = Lua.import('Module:A or an')
local Arguments = Lua.import('Module:Arguments')
local DateExt = Lua.import('Module:Date/Ext')
local Faction = Lua.import('Module:Faction')
local Flags = Lua.import('Module:Flags')
local Logic = Lua.import('Module:Logic')
local Opponent = Lua.import('Module:Opponent/Custom')
local OpponentDisplay = Lua.import('Module:OpponentDisplay/Custom')
local String = Lua.import('Module:StringUtils')

local Condition = Lua.import('Module:Condition')
local ConditionNode = Condition.Node
local Comparator = Condition.Comparator
local ColumnName = Condition.ColumnName

local Link = Lua.import('Module:Widget/Basic/Link')

local Disambiguation = {}

---@param frame Frame
---@return string
function Disambiguation.player(frame)
	local args = Arguments.getArgs(frame)
	local player = mw.ext.TeamLiquidIntegration.resolve_redirect(args.player or args[1]):gsub(' ', '_')
	local nameInput = args.name or args.id or mw.title.getCurrentTitle().text

	local data = mw.ext.LiquipediaDB.lpdb('player', {
		conditions = tostring(ConditionNode(ColumnName('pagename'), Comparator.eq, player)),
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
	local nameDisplay = firstName .. ' ' .. tostring(Link{link = player, children = id}) .. ' ' .. lastName

	local localisation = Flags.getLocalisation(data.nationality)
	localisation = String.isNotEmpty(localisation) and (localisation .. ' ') or ''

	local isDeceased = data.deathdate ~= DateExt.defaultDate or (data.status or ''):lower() == 'deceased'

	local statusDisplay = (data.status or ''):lower() ~= 'active' and (not isDeceased) and (data.status .. ' ') or ''

	local factionDisplay = Faction.toName(extraData.faction) or ''

	local typeDisplay = Logic.emptyOr(data.type, 'player'):lower()

	---@return string
	local  getPlayingWorkingInfo = function()
		if Logic.isEmpty(data.teamtemplate) then return '' end
		return String.interpolate(
			' currently ${playOrWork} for ${opponent}',
			{
				playOrWork = typeDisplay == 'player' and 'playing' or 'working',
				opponent =tostring(OpponentDisplay.InlineOpponent{
					opponent = {
						type = Opponent.team,
						template = data.teamtemplate,
						extradata = {},
					}
				}),
			}
		)
	end

	return String.interpolate(
		'* ${name}, ${aOrAn}${status}${localisation}${faction}${typeInfo}${playingWorkingInfo}.${currentId}',
		{
			name = nameDisplay,
			aOrAn = AnOrA._main{statusDisplay .. localisation .. factionDisplay .. typeDisplay},
			status = statusDisplay,
			localisation = localisation,
			faction = factionDisplay,
			typeInfo = typeDisplay,
			playingWorkingInfo = getPlayingWorkingInfo(),
			currentId = nameInput ~= data.id and ' Their current ID is ' .. data.id .. '.' or ''
		}
	)
end

return Disambiguation
