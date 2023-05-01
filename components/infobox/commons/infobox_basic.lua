---
-- @Liquipedia
-- wiki=commons
-- page=Module:Infobox/Basic
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Arguments = require('Module:Arguments')
local Class = require('Module:Class')
local Lua = require('Module:Lua')
local Logic = require('Module:Logic')
local Table = require('Module:Table')

local Info = Lua.import('Module:Info', {requireDevIfEnabled = true})
local Infobox = Lua.import('Module:Infobox', {requireDevIfEnabled = true})

local BasicInfobox = Class.new(
	function(self, frame)
		self.args = Arguments.getArgs(frame)
		self.pagename = mw.title.getCurrentTitle().text
		self.name = self.args.name or self.pagename
		self.wiki = self.args.wiki or Info.wikiName

		self.infobox = Infobox:create(frame, self.wiki, Logic.readBool(self.args.darkmodeforced))
	end
)

function BasicInfobox:createWidgetInjector()
	return nil
end

--- Allows for overriding this functionality
function BasicInfobox:addCustomCells(infobox, args)
	return infobox
end

--- Allows for overriding this functionality
function BasicInfobox:createBottomContent()
	return nil
end

--- Allows for overriding this functionality
function BasicInfobox:getWikiCategories(args)
	return {}
end

--- Allows for using this for customCells
function BasicInfobox:getAllArgsForBase(args, base, options)
	options = options or {}

	local makeLink = Logic.readBool(options.makeLink)
	local foundArgs = {}

	for key, value in Table.iter.pairsByPrefix(args, base, {requireIndex = false}) do
		if makeLink then
			local link = args[key .. 'link'] or value
			value = '[[' .. link .. '|' .. value .. ']]'
		end
		table.insert(foundArgs, value)
	end

	return foundArgs
end

return BasicInfobox
