---
-- @Liquipedia
-- page=Module:Infobox/Person/Player/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Class = Lua.import('Module:Class')
local Logic = Lua.import('Module:Logic')
local MatchTicker = Lua.import('Module:MatchTicker/Custom')
local Page = Lua.import('Module:Page')
local PlayerIntroduction = Lua.import('Module:PlayerIntroduction/Custom')
local String = Lua.import('Module:StringUtils')
local TeamTemplate = Lua.import('Module:TeamTemplate')
local Template = Lua.import('Module:Template')

local Injector = Lua.import('Module:Widget/Injector')
local Player = Lua.import('Module:Infobox/Person')

local Widgets = Lua.import('Module:Widget/All')
local HtmlWidgets = Lua.import('Module:Widget/Html/All')
local Cell = Widgets.Cell
local UpcomingTournaments = Lua.import('Module:Widget/Infobox/UpcomingTournaments')

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
			firstname = args.first_name,
			lastname = args.last_name,
			status = args.status,
			type = player:getPersonType(args).store,
			roles = player._getKeysOfRoles(player.roles),
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

		return {Cell{name = 'Solo MMR', children = {mmrDisplay}}}
	elseif id == 'status' then
		return {
			Cell{name = 'Status', children = {CustomPlayer._getStatus(args)}},
			Cell{name = 'Years Active (Player)', children = {args.years_active}},
			Cell{name = 'Years Active (Org)', children = {args.years_active_manage}},
			Cell{name = 'Years Active (Coach)', children = {args.years_active_coach}},
		}
	elseif id == 'history' then
		table.insert(widgets, Cell{name = 'Retired', children = {args.retired}})
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

---@return Widget?
function CustomPlayer:createBottomContent()
	if self:shouldStoreData(self.args) and String.isNotEmpty(self.args.team) then
		local teamPage = TeamTemplate.getPageName(self.args.team)

		return HtmlWidgets.Fragment{
			children = {
				MatchTicker.participant{team = teamPage},
				UpcomingTournaments{name = teamPage}
			}
		}
	end
end

---@param args table
---@return string?
function CustomPlayer._getStatus(args)
	if String.isNotEmpty(args.status) then
		return Page.makeInternalLink({onlyIfExists = true}, args.status) or args.status
	end
end

return CustomPlayer
