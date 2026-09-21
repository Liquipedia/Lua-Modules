---
-- @Liquipedia
-- page=Module:PortalPlayers/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Abbreviation = Lua.import('Module:Abbreviation')
local Arguments = Lua.import('Module:Arguments')
local Array = Lua.import('Module:Array')
local Date = Lua.import('Module:Date/Ext')
local Links = Lua.import('Module:Links')
local String = Lua.import('Module:StringUtils')
local Table = Lua.import('Module:Table')
local TeamTemplate = Lua.import('Module:TeamTemplate')

local AgeCalculation = Lua.import('Module:AgeCalculation')
local PortalPlayers = Lua.import('Module:PortalPlayers')

local TableWidgets = Lua.import('Module:Widget/Table2/All')
local WidgetUtil = Lua.import('Module:Widget/Util')

local OpponentDisplay = Lua.import('Module:OpponentDisplay/Custom')

local NON_PLAYER_HEADER = Abbreviation.make{text = 'Staff', title = 'Coaches, Managers, Analysts and more'}
	.. ' & ' .. Abbreviation.make{text = 'Talents', title = 'Commentators, Observers, Hosts and more'}
local BACKGROUND_CLASSES = {
	inactive = 'sapphire-bg',
	retired = 'bg-neutral',
	banned = 'cinnabar-bg',
	['passed away'] = 'gigas-bg',
}

local CustomPortalPlayers = {}

---@param frame Frame
---@return VNode
function CustomPortalPlayers.run(frame)
	local args = Arguments.getArgs(frame)
	args.width = '1100px'

	local portalPlayers = PortalPlayers(args)

	portalPlayers.header = CustomPortalPlayers.header
	portalPlayers.row = CustomPortalPlayers.row
	portalPlayers.columns = CustomPortalPlayers.columns

	return portalPlayers:create()
end

---@return table[]
function CustomPortalPlayers:columns()
	return {
		{width = '175px'},
		{width = '175px'},
		{width = '175px'},
		{width = '250px'},
		{width = '120px'},
	}
end

---Builds the header for the table
---@param args {flag: string, isPlayer: boolean?}
---@return Widget
function CustomPortalPlayers:header(args)
	local teamText = args.isPlayer and ' Team' or ' Team and Role'

	return TableWidgets.TableHeader{
		children = {
			TableWidgets.Row{
				children = TableWidgets.CellHeader{
					colspan = 5,
					css = {['padding-left'] = '1em'},
					children = args.flag .. ' ' .. (args.isPlayer and self.playerType or NON_PLAYER_HEADER),
				},
			},
			TableWidgets.Row{
				children = {
					TableWidgets.CellHeader{children = 'ID'},
					TableWidgets.CellHeader{children = 'Real Name'},
					TableWidgets.CellHeader{children = 'Age'},
					TableWidgets.CellHeader{children = teamText},
					TableWidgets.CellHeader{children = 'Links'},
				},
			},
		},
	}
end

---Builds a table row
---@param player table
---@param isPlayer boolean
---@return VNode
function CustomPortalPlayers:row(player, isPlayer)
	local role = not isPlayer and mw.language.getContentLanguage():ucfirst((player.extradata or {}).role or '') or ''
	local teamText = TeamTemplate.exists(player.team) and tostring(OpponentDisplay.InlineTeamContainer{
		template = player.team, displayType = 'standard'
	}) or ''

	if String.isNotEmpty(role) and String.isEmpty(teamText) then
		teamText = role
	elseif String.isNotEmpty(role) then
		teamText = teamText .. ' (' .. role .. ')'
	end

	local links = Array.extractValues(Table.map(player.links or {}, function(key, link)
		return key, ' [' .. link .. ' ' .. Links.makeIcon(Links.removeAppendedNumber(key), 25) .. ']'
	end) or {}, Table.iter.spairs)

	return TableWidgets.Row{
		classes = WidgetUtil.collect(BACKGROUND_CLASSES[(player.status or ''):lower()]),
		children = {
			TableWidgets.Cell{
				children = OpponentDisplay.BlockOpponent{opponent = PortalPlayers.toOpponent(player)}
			},
			TableWidgets.Cell{
				nowrap = false,
				children = WidgetUtil.collect(
					' ' .. player.name,
					self.showLocalizedName and (' (' .. player.localizedname .. ')') or nil
				)
			},
			TableWidgets.Cell{children = CustomPortalPlayers._getAge(player)},
			TableWidgets.Cell{nowrap = false, children = ' ' .. teamText},
			TableWidgets.Cell{
				nowrap = false,
				classes = {'plainlinks'},
				css = {
					['line-height'] = '25px',
					['padding'] = '1px 2px 1px 2px'
				},
				children = table.concat(links)
			}
		}
	}
end

---Builds the age display
---@param player table
---@return string
function CustomPortalPlayers._getAge(player)
	local birthDate
	if Date.readTimestamp(player.birthdate) ~= Date.defaultTimestamp then
		birthDate = player.birthdate
	end

	local deathDate
	if Date.readTimestamp(player.deathdate) ~= Date.defaultTimestamp then
		deathDate = player.deathdate
	end

	local ageCalculationSuccess, age = pcall(AgeCalculation.run, {
		birthdate = birthDate,
		deathdate = deathDate,
	})

	if not ageCalculationSuccess then
		return age --[[@as string]]
	end

	if age.death then
		return age.birth .. '<br>' .. age.death
	end

	return age.birth
end

return CustomPortalPlayers
