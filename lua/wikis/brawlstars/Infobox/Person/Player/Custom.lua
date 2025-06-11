---
-- @Liquipedia
-- page=Module:Infobox/Person/Player/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Logic = require('Module:Logic')
local Lua = require('Module:Lua')
local Page = require('Module:Page')
local PlayerIntroduction = require('Module:PlayerIntroduction/Custom')
local String = require('Module:StringUtils')
local Team = require('Module:Team')
local Template = require('Module:Template')

local Injector = Lua.import('Module:Widget/Injector')
local Player = Lua.import('Module:Infobox/Person')

local Widgets = require('Module:Widget/All')
local Cell = Widgets.Cell

---@class BrawlstarsInfoboxPlayer: Person
local CustomPlayer = Class.new(Player)
local CustomInjector = Class.new(Injector)

---@param frame Frame
---@return Html
function CustomPlayer.run(frame)
	---@type BrawlstarsInfoboxPlayer
	local player = CustomPlayer(frame)
	player:setWidgetInjector(CustomInjector(player))

	local args = player.args

	local builtInfobox = player:createInfobox()

	local autoPlayerIntro = ''
	if Logic.readBool((args.autoPI or ''):lower()) then
		autoPlayerIntro = PlayerIntroduction.run{
			team = args.team,
			name = Logic.emptyOr(args.romanized_name, args.name),
			romanizedname = args.romanized_name,
			status = args.status,
			type = player:getPersonType(args).store,
			role = (player.roles[1] or {}).display,
			role2 = (player.roles[2] or {}).display,
			id = args.id,
			idIPA = args.idIPA,
			idAudio = args.idAudio,
			birthdate = player.age.birthDateIso,
			deathdate = player.age.deathDateIso,
			nationality = args.country,
			nationality2 = args.country2,
			nationality3 = args.country3,
			subtext = args.subtext,
			freetext = args.freetext,
		}
	elseif String.isNotEmpty(args.freetext) then
		autoPlayerIntro = args.freetext
	end

	return mw.html.create()
		:node(builtInfobox)
		:node(autoPlayerIntro)
end

---@param id string
---@param widgets Widget[]
---@return Widget[]
function CustomInjector:parse(id, widgets)
	local caller = self.caller
	local args = caller.args

	if id == 'custom' then
		if String.isEmpty(args.mmr) then return {} end

		local mmrDisplay = '[[Leaderboards|' .. args.mmr .. ']]'
		if String.isNotEmpty(args.mmrdate) then
			mmrDisplay = mmrDisplay .. '&nbsp;<small><i>(last update: ' .. args.mmrdate .. '</i></small>'
		end

		return {Cell{name = 'Solo MMR', content = {mmrDisplay}}}
	elseif id == 'status' then
		return {
			Cell{name = 'Status', content = {CustomPlayer._getStatus(args)}},
			Cell{name = 'Years Active (Player)', content = {args.years_active}},
			Cell{name = 'Years Active (Org)', content = {args.years_active_manage}},
			Cell{name = 'Years Active (Coach)', content = {args.years_active_coach}},
		}
	elseif id == 'history' then
		table.insert(widgets, Cell{name = 'Retired', content = {args.retired}})
	end
	return widgets
end

---@param lpdbData table
---@param args table
---@return table
function CustomPlayer:adjustLPDB(lpdbData, args)
	lpdbData.region = Template.safeExpand(mw.getCurrentFrame(), 'Player region', {args.country})

	return lpdbData
end

function CustomPlayer:createBottomContent()
	local components = {}
	if self:shouldStoreData(self.args) and String.isNotEmpty(self.args.team) then
		local teamPage = Team.page(mw.getCurrentFrame(), self.args.team)

		table.insert(components,
			Template.safeExpand(mw.getCurrentFrame(), 'Upcoming and ongoing matches of', {team = teamPage}))
		table.insert(components,
			Template.safeExpand(mw.getCurrentFrame(), 'Upcoming and ongoing tournaments of', {team = teamPage}))
	end

	return table.concat(components)
end

---@param args table
---@return string?
function CustomPlayer._getStatus(args)
	if String.isNotEmpty(args.status) then
		return Page.makeInternalLink({onlyIfExists = true}, args.status) or args.status
	end
end

return CustomPlayer
