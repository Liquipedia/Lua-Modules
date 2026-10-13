local p = {}

local getArgs = require('Module:Arguments').getArgs
local Crosshair = require('Module:Crosshair')
local CrosshairCommons = require('Module:CrosshairCommons')

local args
local categories = {}
local crosshair

local stylesExplanation = CrosshairCommons.stylesExplanation
local colorsExplanation = CrosshairCommons.colorsExplanation
local crosshairColors = CrosshairCommons.crosshairColors

local function abbr(title, value)
	return "<abbr title='".. title .."'>".. value .."</abbr>"
end

local function setSmwAndLpdbData()
	crosshair["share_code"] = args["share_code"] or nil
	mw.ext.LiquipediaDB.lpdb_settings(mw.title.getCurrentTitle().text .. '_crosshair', {
		name = mw.title.getCurrentTitle().text,
		reference = (args.ref == 'player' and 'player' or args.ref or ''),
		lastupdated = (args.date ~= nil and args.date or ''),
		gamesettings = mw.ext.LiquipediaDB.lpdb_create_json(crosshair),
		type = 'crosshair'
	})
end

local function roundOneDecimal(x)
	return x>=0 and math.floor(x+0.5) or math.ceil(x-0.5)
end

local function dateDiffInDays(date)
	local y, m, d =  string.match(date, "(%d+)-(%d+)-(%d+)")
	local daysfrom = os.difftime(os.time(),os.time{year=y, month=m, day=d}) / (24 * 60 * 60) -- seconds in a day
	local daysDiff = roundOneDecimal(daysfrom)
	if daysDiff == 0 then
		return "today"
	elseif daysDiff == 1 then
		return "yesterday"
	else
		if daysDiff > 10000 then table.insert(categories, 'Pages with malformed date inputs') end
		return daysDiff .. " days ago"
	end
end

local function drawTable(makePreview)
	local wrapper = mw.html.create('div')
		:addClass('table-responsive-xchair')
	local table = wrapper:tag('table')
		:addClass('wikitable')
		:css({["text-align"] = "center", ["margin-top"] = "1em", ["margin-bottom"] = "0px"})

	local firstRowHeader = table:tag('tr'):tag('th')
		:attr('colspan','12')
		:wikitext('Crosshair Settings ')

	if args.ref == "player" then
		firstRowHeader:wikitext("<sup><i><b><small><small><abbr title='"..mw.ext.VariablesLua.var("id").." has submitted their own crosshair to Liquipedia'>Player Submitted</abbr></small></small></b></i></sup>")
	else
		firstRowHeader:wikitext(args.ref)
	end
	firstRowHeader:wikitext("<small> ([[List of player crosshair settings|list of]])</small>")

	local secondRow = table:tag('tr')
	local thirdRow = table:tag('tr')
		:css("height","32px")

	local commands = {
		[1] = {"cl_crosshairstyle","style","Style","cl_crosshairstyle",crosshair["cl_crosshairstyle"] ~= nil and stylesExplanation[crosshair["cl_crosshairstyle"]]},
		[2] = {"cl_crosshairsize","size","Size","cl_crosshairsize","<code>"..(crosshair["cl_crosshairsize"] or "").."</code>"},
		[3] = {"cl_crosshairthickness","thickness","Thickness","cl_crosshairthickness","<code>"..(crosshair["cl_crosshairthickness"] or "").."</code>"},
		[4] = {"cl_crosshair_sniper_width","sniper","Sniper","cl_crosshair_sniper_width","<code>"..(crosshair["cl_crosshair_sniper_width"] or "").."</code>"},
		[5] = {"cl_crosshairgap","gap","Gap","cl_crosshairgap","<code>"..(crosshair["cl_crosshairgap"] or "").."</code>"},
		[6] = {"cl_crosshair_outlinethickness","outlinethickness","Outline","cl_crosshair_drawoutline, cl_crosshair_outlinethickness",crosshair["cl_crosshair_drawoutline"] == 1 and "Yes (thickness <code>"..crosshair["cl_crosshair_outlinethickness"].."</code>)" or "No"},
		[7] = {"cl_crosshairdot","dot","Dot","cl_crosshairdot",crosshair["cl_crosshairdot"] == nil and "" or (crosshair["cl_crosshairdot"] == 1 and "Yes (<code>1</code>)" or "No (<code>0</code>)")},
		[8] = {"cl_crosshaircolor","color","Color","cl_crosshaircolor",crosshair["cl_crosshaircolor"] ~= nil and colorsExplanation[crosshair["cl_crosshaircolor"]] .. " (<code>"..(crosshair["cl_crosshaircolor"] or "").."</code>)"},
		[9] = {"cl_crosshairalpha","alpha","Alpha","cl_crosshairusealpha, cl_crosshairalpha","<code>"..(crosshair["cl_crosshairalpha"] or "").."</code>"},
	}

	for _, command in ipairs(commands) do
		if crosshair[command[1]] ~= nil then
			secondRow:tag('th'):wikitext(abbr(command[4],command[3]))
			local current_third = thirdRow:tag('td'):wikitext(command[5])
			if command[1] == "cl_crosshaircolor" then
				current_third:css("background-color", crosshairColors[crosshair["cl_crosshaircolor"]])
				current_third:css("color", "black")
			end
		end
	end

	if makePreview then
		local preview = Crosshair.makePreview(crosshair, mw.ext.VariablesLua.var('res_height'))

		if preview ~= "" then
			local previewCol = secondRow:tag('td'):attr('rowspan','3'):css({['line-height'] = '1', ['padding'] = '0'})
			previewCol:tag('div')
				:css({["width"] = "82px", ["height"] = "82px", ["display"] = "inline-block", ["position"] = "relative"})
				:wikitext(preview)
				:wikitext('[[Category:Pages with crosshair previews]]')

			-- contrast background
			if crosshair["cl_crosshair_drawoutline"] == 0 or crosshair["cl_crosshair_outlinethickness"] ==0 then
				-- test if color is light
				if (CrosshairCommons.isBrightCrosshair(crosshair["cl_crosshaircolor"], crosshair["cl_crosshaircolor_r"], crosshair["cl_crosshaircolor_g"], crosshair["cl_crosshaircolor_b"])) then
					previewCol:css("background-color","#444")
				end
			end
		end
	end

	local dateRow = table:tag('tr'):tag('th')
		:attr('colspan','9')
		:css("font-size","85%")
		:css("padding","2px")

	if args.date == nil then
		dateRow:wikitext("<span style='color:#D11;'>''No date of last update specified!''</span>")
	else
		local hasDate, updated_in = pcall(dateDiffInDays, args.date)
		if hasDate then
			dateRow:wikitext("''Updated as of ".. args.date .. " (".. updated_in ..")")
		else
			dateRow:wikitext("<span style='color:#D11;'>''Specified update date format not recognized!''</span>")
		end
	end

	local tableCommands = wrapper:tag('table')
		:addClass('collapsible wikitable mobile-hide collapsed')
		:css({["width"] = "100%", ["margin-top"] = "-1px"})

	tableCommands:tag('tr'):tag('th')
		:css({["font-size"] = "85%" , ["padding"] = "5px"})
		:attr('align', 'center')
		:attr('colspan', '2')
		:wikitext("''Click &#034;Expand&#034; for "..(args["share_code"] ~= nil and "sharecode and " or "").."console commands to copy and paste.''")

	if args["share_code"] ~= nil then
		tableCommands:tag('tr')
			:tag('th'):wikitext("Sharecode")
			:tag('td')
			:css({["font-size"] = "85%", ["padding"] = "5px"})
			:wikitext("<code style='display:inline-block;'>" ..args["share_code"].. "</code>")
	end

	local commandsList ={"cl_crosshairalpha", "cl_crosshaircolor", "cl_crosshairdot", "cl_crosshairgap", "cl_crosshairsize", "cl_crosshairstyle", "cl_crosshairusealpha", "cl_crosshairthickness", "cl_crosshair_sniper_width", "cl_crosshair_outlinethickness", "cl_crosshair_drawoutline"}

	local commandText = "<code style='display:inline-block;'>"
	for _, command in ipairs(commandsList) do
			if crosshair[command] ~= nil then
				commandText = commandText ..command.." "..crosshair[command].."; " 
				if command == "cl_crosshaircolor" and crosshair["cl_crosshaircolor"] == 5 then
					if crosshair["cl_crosshaircolor_r"] ~= nil then commandText = commandText .."cl_crosshaircolor_r "..crosshair["cl_crosshaircolor_r"].."; " end
					if crosshair["cl_crosshaircolor_g"] ~= nil then commandText = commandText .."cl_crosshaircolor_g "..crosshair["cl_crosshaircolor_g"].."; " end
					if crosshair["cl_crosshaircolor_b"] ~= nil then commandText = commandText .."cl_crosshaircolor_b "..crosshair["cl_crosshaircolor_b"].."; " end
				end
			end
	end
	commandText = commandText .. "</code>"

	tableCommands:tag('tr'):tag('tr')
		:tag('th'):css("width", "20px"):wikitext("Commands")
		:tag('td')
		:css({["font-size"] = "85%", ["padding"] = "5px", ["max-width"] = "1px"})
		:wikitext(commandText)

	return tostring(wrapper)
end

local function create(frame)
	args = getArgs(frame)

	for k, v in pairs(args) do
		args[k] = v:gsub(",", ".")
	end
	--Only makes a preview of crosshair if share_code is available or style ,size, thickness, gap , outlinethickness , color , and alpha are set
	local makePreview = true

	if args.share_code ~=nil then
		crosshair = Crosshair.decode(args.share_code)	
		makePreview = true
	else
		local previewArgs = {"style","size","thickness","gap","color","dot"}
		for _, previewArg in ipairs(previewArgs) do
			if args[previewArg] == nil then
				makePreview = false
			end
		end
		if makePreview and args["color"] == "5" then
			makePreview = args["r"] ~=nil and args["g"] ~=nil and args["b"] ~=nil
		end

		crosshair = Crosshair.fromArgs(args)

		if makePreview then
			local passed, sharecode = pcall(Crosshair.encode, crosshair)
			args["share_code"] = passed and sharecode or nil
		end
	end

	if crosshair["cl_crosshaircolor"] == 5 then
		crosshairColors[5] = "rgb("..crosshair["cl_crosshaircolor_r"]..","..crosshair["cl_crosshaircolor_g"]..",".. crosshair["cl_crosshaircolor_b"]..")"
		colorsExplanation[5] = abbr(crosshairColors[5],"Custom")
	end

	if crosshair["cl_crosshaircolor"] > 5 then
		crosshair["cl_crosshaircolor"] = 1
	end

	setSmwAndLpdbData()
	return drawTable(makePreview)
end

function p.create(frame)
	local passed, output = pcall(create, frame)
	if passed then
		return output .. (#categories > 0 and ('[[Category:' .. table.concat(categories, ']][[Category:') .. ']]') or '')
	else
		return nil
	end
end

return p
