---
-- @Liquipedia
-- wiki=commons
-- page=Module:TeamLogoGallery
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Class = require('Module:Class')
local DateExt = require('Module:Date/Ext')
local Gallery = require('Module:Gallery')
local Game = require('Module:Game')
local Logic = require('Module:Logic')
local Ordinal = require('Module:Ordinal')
local Table = require('Module:Table')
local Team = require('Module:Team')

local TeamLogoGallery = {}

---@param args table?
---@return Html?
function TeamLogoGallery.run(args)
	args = args or {}
	local name = (args.name or mw.title.getCurrentTitle().prefixedText):gsub('_', ' '):lower()

	assert(mw.ext.TeamTemplate.teamexists(name), 'Missing team template "' .. name .. '"')

	local imageData = TeamLogoGallery._getImageData(name)

	return Gallery.run(imageData)
end

---@param name string
---@return {imageLightMode: string, imageDarkMode: string?, caption: string}[]
function TeamLogoGallery._getImageData(name)
	local historicalTeamTemplates = Logic.emptyOr(Team.queryHistorical(name)) or {[DateExt.defaultDate] = name}

	local imageDatas = {}
	for startDate, teamTemplate in Table.iter.spairs(historicalTeamTemplates) do
		table.insert(imageDatas, {
			startDate = startDate,
			raw = mw.ext.TeamTemplate.raw(teamTemplate)
		})
	end

	local finalName = imageDatas[#imageDatas].raw.name

	return Array.map(imageDatas, function(imageData, index)
		local image = Logic.emptyOr(imageData.raw.image, imageData.raw.legacyimage)
		if not image or Game.isDefaultTeamLogo{logo = image} then
			return nil
		end

		local previous = imageDatas[index - 1] or {raw = {}}
		local previousImage = Logic.emptyOr(previous.raw.image, previous.raw.legacyimage)
		if previousImage == image then
			return nil
		end

		local nextStartDate = (imageDatas[index + 1] or {}).startDate

		local caption, below = TeamLogoGallery._makeCaptionAndBelow(imageData, nextStartDate, index, finalName)

		return {
			lightmode = image,
			darkmode = Logic.emptyOr(imageData.raw.imagedark, imageData.raw.legacyimagedark),
			caption = caption,
			below = below,
		}
	end)
end

---@param imageData {startDate: string, raw: table}
---@param endDate string?
---@param index integer
---@param finalName string
---@return string
---@return Html|string
function TeamLogoGallery._makeCaptionAndBelow(imageData, endDate, index, finalName)
	if not endDate then
		local caption = 'Current logo'
		return caption, caption
	end

	local number = index == 1 and 'Original' or Ordinal.written(index)

	local caption = number .. ' logo'
	local below = mw.html.create('p')
		:wikitext(caption)

	local teamName = imageData.raw.name
	if teamName ~= finalName then
		caption = caption .. ', as ' .. teamName
		below:wikitext(', as '):tag('b'):wikitext(teamName)
	end

	if not endDate then
		return caption, below
	end

	local month = DateExt.formatTimestamp('F', DateExt.readTimestamp(endDate)--[[@as integer]])
	local dateArray = mw.text.split(endDate, '-', true)
	local year = dateArray[1]
	local day = dateArray[3]
	local daySuffix = Ordinal.suffix(day)

	caption = caption .. ' (prior to ' .. month .. ' ' .. day .. daySuffix .. ', ' .. year .. ')'

	below
		:tag('br', {selfClosing = true}):done()
		:tag('small')
			:wikitext('(prior to ' .. month .. '&nbsp;' .. day)
			:tag('sup'):wikitext(daySuffix):done()
			:wikitext(',&nbsp;' .. year)

	return caption, below
end

return Class.export(TeamLogoGallery)
