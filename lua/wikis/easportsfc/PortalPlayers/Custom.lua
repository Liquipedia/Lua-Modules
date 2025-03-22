---
-- @Liquipedia
-- wiki=easportsfc
-- page=Module:PortalPlayers/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Abbreviation = require('Module:Abbreviation')
local Arguments = require('Module:Arguments')
local Array = require('Module:Array')
local Date = require('Module:Date/Ext')
local Links = require('Module:Links')
local Lua = require('Module:Lua')
local String = require('Module:StringUtils')
local Table = require('Module:Table')
local TeamTemplate = require('Module:TeamTemplate')

local AgeCalculation = Lua.import('Module:AgeCalculation')
local PortalPlayers = Lua.import('Module:PortalPlayers')

local OpponentLibrary = require('Module:OpponentLibraries')
local OpponentDisplay = OpponentLibrary.OpponentDisplay

local TeamInline = Lua.import('Module:Widget/TeamDisplay/Inline/Standard')

local NON_PLAYER_HEADER = Abbreviation.make('Staff', 'Coaches, Managers, Analysts and more')
	.. ' & ' .. Abbreviation.make('Talents', 'Commentators, Observers, Hosts and more')
local BACKGROUND_CLASSES = {
	inactive = 'sapphire-bg',
	retired = 'bg-neutral',
	banned = 'cinnabar-bg',
	['passed away'] = 'gigas-bg',
}

local CustomPortalPlayers = {}

---@param frame Frame
---@return Html
function CustomPortalPlayers.run(frame)
	local args = Arguments.getArgs(frame)
	args.width = '1100px'

	local portalPlayers = PortalPlayers(args)

	portalPlayers.header = CustomPortalPlayers.header
	portalPlayers.row = CustomPortalPlayers.row

	return portalPlayers:create()
end

---Builds the header for the table
---@param args {flag: string, isPlayer: boolean?}
---@return Html
function CustomPortalPlayers:header(args)
	local teamText = args.isPlayer and ' Team' or ' Team and Role'

	local header = mw.html.create('tr')
		:tag('th')
			:attr('colspan', 5)
			:css('padding-left', '1em')
			:wikitext(args.flag .. ' ' .. (args.isPlayer and self.playerType or NON_PLAYER_HEADER))
			:done()

	local subHeader = mw.html.create('tr')
		:tag('th'):css('width', '175px'):wikitext(' ID'):done()
		:tag('th'):css('width', '175px'):wikitext(' Real Name'):done()
		:tag('th'):css('width', '175px'):wikitext(' Age'):done()
		:tag('th'):css('width', '250px'):wikitext(teamText):done()
		:tag('th'):css('width', '120px'):wikitext(' Links'):done()

	return mw.html.create()
		:node(header)
		:node(subHeader)
end

---Builds a table row
---@param player table
---@param isPlayer boolean
---@return Html
function CustomPortalPlayers:row(player, isPlayer)
	local row = mw.html.create('tr')
		:addClass(BACKGROUND_CLASSES[(player.status or ''):lower()])

	row:tag('td'):wikitext(' '):node(OpponentDisplay.BlockOpponent{opponent = PortalPlayers.toOpponent(player)})
	row:tag('td')
		:wikitext(' ' .. player.name)
		:wikitext(self.showLocalizedName and (' (' .. player.localizedname .. ')') or nil)

	row:tag('td'):node(CustomPortalPlayers._getAge(player))

	local role = not isPlayer and mw.language.getContentLanguage():ucfirst((player.extradata or {}).role or '') or ''
	local teamText = TeamTemplate.exists(player.team) and tostring(TeamInline{name = player.team}) or ''
	if String.isNotEmpty(role) and String.isEmpty(teamText) then
		teamText = role
	elseif String.isNotEmpty(role) then
		teamText = teamText .. ' (' .. role .. ')'
	end
	row:tag('td'):wikitext(' ' .. teamText)

	local links = Array.extractValues(Table.map(player.links or {}, function(key, link)
		return key, ' [' .. link .. ' ' .. Links.makeIcon(Links.removeAppendedNumber(key), 25) .. ']'
	end) or {}, Table.iter.spairs)

	row:tag('td')
		:addClass('plainlinks')
		:css('line-height', '25px')
		:css('padding', '1px 2px 1px 2px')
		:css('max-width', '112px')
		:wikitext(table.concat(links))

	return row
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
