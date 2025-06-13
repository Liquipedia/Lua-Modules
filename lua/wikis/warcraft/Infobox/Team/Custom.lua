---
-- @Liquipedia
-- page=Module:Infobox/Team/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Class = require('Module:Class')
local Faction = require('Module:Faction')
local Flags = require('Module:Flags')
local Lua = require('Module:Lua')
local String = require('Module:StringUtils')
local Table = require('Module:Table')

local Achievements = Lua.import('Module:Infobox/Extension/Achievements')
local Injector = Lua.import('Module:Widget/Injector')
local Team = Lua.import('Module:Infobox/Team')

local Widgets = require('Module:Widget/All')
local Cell = Widgets.Cell
local Center = Widgets.Center
local Title = Widgets.Title

---@class WarcraftInfoboxTeam: InfoboxTeam
local CustomTeam = Class.new(Team)
local CustomInjector = Class.new(Injector)

-- These should be converted to proper links at some point
local PROFILE_DISPLAY =
	'<span class="league-icon-small-image" style="margin-left:2px">[[File:${icon}|32px|link=${link}|${text}]]</span>'
local PROFILES = {
	w3iprofile = {
		icon = 'War3.info icon.png',
		link = 'https://warcraft3.info/league/clans/',
		text = 'warcraft3.info ${name}\'s profile'
	},
	nwc3lprofile = {
		icon = 'NWC3L-icon.png',
		link = 'https://nwc3l.com/team/',
		text = 'NWC3L ${name}\'s profile'
	},
	eslprofile = {
		icon = 'ESL_2019_icon.png',
		link = 'https://play.eslgaming.com/team/',
		text = 'ESL ${name}\'s profile'
	},
}

---@param frame Frame
---@return Html
function CustomTeam.run(frame)
	local team = CustomTeam(frame)
	team:setWidgetInjector(CustomInjector(team))

	-- Automatic achievements
	team.args.achievements = Achievements.team{noTemplate = true}

	return team:createInfobox()
end

---@param id string
---@param widgets Widget[]
---@return Widget[]
function CustomInjector:parse(id, widgets)
	local args = self.caller.args

	if id == 'topcustomcontent' then
		table.insert(widgets, Cell{
			name = 'Clan tag',
			content = {self.caller.teamTemplate.shortname}
		})
	elseif id == 'customcontent' then
		local profiles = Array.extractValues(Table.map(PROFILES, function (param, profileData)
			return param, self.caller:_createProfile(profileData, args[param])
		end))
		if not Table.isEmpty(profiles) then
			table.insert(widgets, Title{children = 'Profiles'})
			table.insert(widgets, Center{children = profiles})
		end
	end
	return widgets
end

---@param profileData {icon: string, link: string, text: string}
---@param profileValue string?
---@return string?
function CustomTeam:_createProfile(profileData, profileValue)
	if not profileValue then
		return
	end

	return String.interpolate(PROFILE_DISPLAY, {
		text = String.interpolate(profileData.text, {name = self.name}),
		link = profileData.link .. profileValue,
		icon = profileData.icon,
	})
end

---@param lpdbData table
---@param args table
---@return table
function CustomTeam:addToLpdb(lpdbData, args)
	lpdbData.extradata.clantag = args.clantag
	lpdbData.extradata.isnationalteam = tostring(CustomTeam._isNationalTeam(self.name))
	lpdbData.extradata.isfactionteam = tostring(CustomTeam._isFactionTeam(self.name))

	return lpdbData
end

---@param args table
---@return string[]
function CustomTeam:getWikiCategories(args)
	local categories = {}

	if not args.image then
		table.insert(categories, 'Team without image')
	end

	if not args.clantag then
		table.insert(categories, 'Team without clan tag')
	end

	local typeCategory = 'Esport Teams'
	if CustomTeam._isFactionTeam(self.name) then
		typeCategory = 'Race Teams'
	elseif CustomTeam._isNationalTeam(self.name) then
		typeCategory = 'National Teams'
	end

	table.insert(categories, typeCategory)

	return categories
end

---@param name string
---@return boolean
function CustomTeam._isNationalTeam(name)
	return Flags.getLocalisation(name) ~= nil
end

---@param name string
---@return boolean
function CustomTeam._isFactionTeam(name)
	local strippedName = name:gsub('^Team ', '')
	return Faction.read(strippedName) ~= nil
end

return CustomTeam
