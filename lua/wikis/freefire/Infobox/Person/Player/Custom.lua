---
-- @Liquipedia
-- page=Module:Infobox/Person/Player/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Class = Lua.import('Module:Class')
local String = Lua.import('Module:StringUtils')
local Page = Lua.import('Module:Page')
local TeamHistoryAuto = Lua.import('Module:TeamHistoryAuto')
local Template = Lua.import('Module:Template')

local Injector = Lua.import('Module:Widget/Injector')
local Player = Lua.import('Module:Infobox/Person')

local Widgets = Lua.import('Module:Widget/All')
local Cell = Widgets.Cell
local Title = Widgets.Title
local Center = Widgets.Center

local CustomPlayer = Class.new(Player)
local CustomInjector = Class.new(Injector)

---@param frame Frame
---@return Html
function CustomPlayer.run(frame)
	local player = CustomPlayer(frame)
	player:setWidgetInjector(CustomInjector(player))

	player.args.autoTeam = true

	return player:createInfobox()
end

---@param id string
---@param widgets Widget[]
---@return Widget[]
function CustomInjector:parse(id, widgets)
	local caller = self.caller
	local args = caller.args

	if id == 'history' then
		local manualHistory = args.history
		local automatedHistory = TeamHistoryAuto.results{
			convertrole = true,
			player = caller.pagename
		}

		if String.isNotEmpty(manualHistory) or automatedHistory then
			return {
				Title{children = 'History'},
				Center{children = {manualHistory}},
				Center{children = {automatedHistory}},
			}
		end
	elseif id == 'status' then
		return {
			Cell{name = 'Status', children = CustomPlayer._getStatusContents(args)},
			Cell{name = 'Years Active (Player)', children = {args.years_active}},
			Cell{name = 'Years Active (Org)', children = {args.years_active_manage}},
			Cell{name = 'Years Active (Coach)', children = {args.years_active_coach}},
			Cell{name = 'Years Active (Analyst)', children = {args.years_active_analyst}},
			Cell{name = 'Years Active (Talent)', children = {args.years_active_talent}},
		}
	end
	return widgets
end

---@param lpdbData table
---@param args table
---@param personType string
---@return table
function CustomPlayer:adjustLPDB(lpdbData, args, personType)
	lpdbData.region = Template.safeExpand(mw.getCurrentFrame(), 'Player region', {args.country})

	local team2 = args.team2link or args.team2
	if String.isNotEmpty(team2) then
		lpdbData.extradata.team2 = (mw.ext.TeamTemplate.raw(team2) or {}).page or team2
	end
	return lpdbData
end

---@param args table
---@return string[]
function CustomPlayer._getStatusContents(args)
	if String.isEmpty(args.status) then
		return {}
	end
	return {Page.makeInternalLink({onlyIfExists = true}, args.status) or args.status}
end

return CustomPlayer
