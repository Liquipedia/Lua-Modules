---
-- @Liquipedia
-- wiki=commons
-- page=Module:Infobox/Patch
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Json = require('Module:Json')
local Logic = require('Module:Logic')
local Lua = require('Module:Lua')
local Namespace = require('Module:Namespace')
local Table = require('Module:Table')
local Variables = require('Module:Variables')

local BasicInfobox = Lua.import('Module:Infobox/Basic')

local Widgets = require('Module:Infobox/Widget/All')
local Cell = Widgets.Cell
local Header = Widgets.Header
local Title = Widgets.Title
local Center = Widgets.Center
local Chronology = Widgets.Chronology
local Builder = Widgets.Builder
local Customizable = Widgets.Customizable
local Highlights = Widgets.Highlights

---@class PatchInfobox: BasicInfobox
local Patch = Class.new(BasicInfobox)

---@param frame Frame
---@return Html
function Patch.run(frame)
	local patch = Patch(frame)
	return patch:createInfobox()
end

---@return Html
function Patch:createInfobox()
	local infobox = self.infobox
	local args = self.args

	local widgets = {
		Header{
			name = args.name,
			image = args.image,
			imageDark = args.imagedark or args.imagedarkmode,
			size = args.imagesize,
		},
		Center{content = {args.caption}},
		Title{name = (self:getInformationType(args)) .. ' Information'},
		Cell{name = 'Version', content = {args.version}},
		Customizable{id = 'release', children = {
				Cell{name = 'Release', content = {args.release}},
			}
		},
		Customizable{id = 'custom', children = {}},
		Builder{
			builder = function()
				local highlights = self:getAllArgsForBase(args, 'highlight')
				if not Table.isEmpty(highlights) then
					return {
						Title{name = 'Highlights'},
						Highlights{content = highlights}
					}
				end
			end
		},
		Builder{
			builder = function()
				local chronologyData = self:getChronologyData(args)
				if not Table.isEmpty(chronologyData) then
					return {
						Title{name = 'Chronology'},
						Chronology{
							content = chronologyData
						}
					}
				end
			end
		},
		Customizable{id = 'customcontent', children = {}},
		Center{content = {args.footnotes}},
	}

	if Namespace.isMain() and not Logic.readBool(Variables.varDefault('disable_LPDB_storage')) then
		infobox:categories(self:getInformationType(args))
		self:setLpdbData(args)
	end

	return infobox:build(widgets)
end

--- Allows for overriding this functionality
---Adjust Lpdb data
---@param lpdbData table
---@param args table
---@return table
function Patch:addToLpdb(lpdbData, args)
	return lpdbData
end

--- Allows for overriding this functionality
---@param args table
function Patch:setLpdbData(args)
	local lpdbData = {
		name = self.name,
		type = self:getInformationType(args):lower(),
		image = args.image,
		imagedark = args.imagedark,
		date = args.release,
		information = mw.getContentLanguage():formatDate('m-d', args.release),
		extradata = {
			highlights = self:getAllArgsForBase(args, 'highlight')
		},
	}

	lpdbData = self:addToLpdb(lpdbData, args)
	mw.ext.LiquipediaDB.lpdb_datapoint('patch_' .. self.name, Json.stringifySubTables(lpdbData))
end

--- Allows for overriding this functionality
---@param args table
---@return string
function Patch:getInformationType(args)
	return args.informationType or 'Patch'
end

--- Allows for overriding this functionality
---@param args table
---@return {previous: string?, next: string?}
function Patch:getChronologyData(args)
	return { previous = args.previous, next = args.next }
end

return Patch
