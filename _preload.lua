--
-- Name:        _preload.lua
-- Purpose:     Define the premake action.
-- Author:      Ryan Pusztai
-- Modified by: Andrea Zanellato
--              Andrew Gough
--              Manu Evans
--              Yehonatan Ballas
--              Jan "GamesTrap" Schürkamp
-- Created:     2013/05/06
-- Updated:     2025/11/04
-- Copyright:   (c) 2008-2020 Jason Perkins and the Premake project
--              (c) 2022-2025 Jan "GamesTrap" Schürkamp
--

local p = premake

local defaultAction = ""
if os.target() == "windows" then
	defaultAction = "vs"
else
	defaultAction = "make"
end

newoption
{
	trigger = "action",
	description = "Specify for which action to generate a Visual Studio Code workspace for. Currently make (default on Linux), Visual Studio Solution (default on Windows) and ninja are supported",
	allowed =
	{
		{ "make", "Make"},
		{ "ninja", "Ninja"},
		{ "vs", "Visual Studio Solution"}
	},
	default = defaultAction
}

newaction
{
	trigger         = "vscode",
	shortname       = "VSCode",
	description     = "Generate Visual Studio Code workspace",

	onWorkspace = function(wks)
		p.modules.vscode.generateWorkspace(wks)
	end,
}

return function(cfg)
	return (_ACTION == "vscode")
end
