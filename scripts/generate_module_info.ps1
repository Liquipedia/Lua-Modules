<#
	Tiny PowerShell Script used to generate the Module:Info for all the wikis

	Data is entered by contributors at
	https://docs.google.com/spreadsheets/d/17JNpjwRuskfI9l0aR_09ALO1ULRZ9koqOagKB-unSZk/edit#gid=0

	This Google SpreadSheet then uses Formula to generate an array of hastables that (as text in proper
  format for the PS Script) then can get copied from the 2n Sheet to the PS Script
#>

$data = #copy paste from the google sheet (sheet 2)

$fixedPath = #path to the base standards folder on my pc
D:
cd $fixedPath

foreach ($subData in $data) {
	#set the text to be written to the file
	$text = @(
		"---";
		"-- @Liquipedia";
		"-- wiki=" + $subData["identifier"];
		"-- page=Module:Info";
		"--";
		"-- Please see https://github.com/Liquipedia/Lua-Modules to contribute";
		"--";
		"";
		"return {";
		"`t" + "startYear = " + $subData["startYear"] + ",";
		"`t" + "wikiName = '" + $subData["identifier"] + "',";
		"`t" + "name = '" + $subData["name"] + "',";
		"`t" + "defaultTeamLogo = '" + $subData["logo"] + "',";
		"`t" + "defaultTeamLogoDark = '" + $subData["logoDark"] + "',";
		"}";
	)
	#set file path and file name
	$filePath = $fixedPath + $subData["identifier"] + "\"
	$fileName = "info.lua"
	$filePathAndName = $filePath + $fileName
	#create the folder
	New-Item -Path $fixedPath -Name $subData["identifier"] -ItemType "directory" -force
	#create the file with the above set text
	New-Item -Path $filePath -Name $fileName -ItemType "file" -force
	Set-Content $filePathAndName $text
}
