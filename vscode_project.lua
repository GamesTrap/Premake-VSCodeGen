--
-- Name:        vscode_project.lua
-- Purpose:     Generate a vscode C/C++ project file.
-- Author:      Ryan Pusztai
-- Modified by: Andrea Zanellato
--              Manu Evans
--              Tom van Dijck
--              Yehonatan Ballas
--              Jan "GamesTrap" Schürkamp
-- Created:     2013/05/06
-- Updated:     2022/12/29
-- Copyright:   (c) 2008-2020 Yehonatan Ballas, Jason Perkins and the Premake project
--              (c) 2022 Jan "GamesTrap" Schürkamp
--

local p = premake
local tree = p.tree
local project = p.project
local config = p.config
local vscode = p.modules.vscode

vscode.project = {}
local m = vscode.project

function m.getcompiler(cfg)
	local toolset = p.tools[_OPTIONS.cc or cfg.toolset or p.CLANG]
	if not toolset then
		error("Invalid toolset '" + (_OPTIONS.cc or cfg.toolset) + "'")
	end
	return toolset
end

function m.getcorecount()
	local cores = 0

	if os.host() == "windows" then
		local result, errorcode = os.outputof("wmic cpu get NumberOfCores")
		for core in result:gmatch("%d+") do
			cores = cores + core
		end
	elseif os.host() == "linux" then
		local result, errorcode = os.outputof("nproc")
		cores = result
	end

	cores = math.ceil(cores * 0.75)

	if cores <= 0 then
		cores = 1
	end

	return cores
end

function m.vscode_tasks(prj, tasksFile)
	for cfg in project.eachconfig(prj) do
		local buildName = "Build " .. prj.name .. " (" .. cfg.name .. ")"
		local target = path.getrelative(prj.workspace.location, prj.location)
		target = target:gsub("/", "\\\\")

		tasksFile:write('\t\t{\n')
		tasksFile:write(string.format('\t\t\t"label": "%s",\n', buildName))
		tasksFile:write('\t\t\t"type": "shell",\n')
		tasksFile:write('\t\t\t"linux":\n')
		tasksFile:write('\t\t\t{\n')
		tasksFile:write(string.format('\t\t\t\t"command": "clear && time make config=%s %s -j%s",\n', string.lower(cfg.name), prj.name, m.getcorecount()))
		tasksFile:write('\t\t\t\t"problemMatcher": "$gcc",\n')
		tasksFile:write('\t\t\t},\n')
		tasksFile:write('\t\t\t"windows":\n')
		tasksFile:write('\t\t\t{\n')
		tasksFile:write('\t\t\t\t"command": "cls && msbuild",\n')
		tasksFile:write('\t\t\t\t"args":\n')
		tasksFile:write('\t\t\t\t[\n')
		tasksFile:write(string.format('\t\t\t\t\t"/m:%s",\n', m.getcorecount()))
		tasksFile:write(string.format('\t\t\t\t\t"${workspaceRoot}/%s.sln",\n', prj.workspace.name))
		tasksFile:write(string.format('\t\t\t\t\t"/p:Configuration=%s",\n', cfg.name))
		tasksFile:write(string.format('\t\t\t\t\t"/t:%s",\n', target))
		tasksFile:write('\t\t\t\t],\n')
		tasksFile:write('\t\t\t\t"problemMatcher": "$msCompile",\n')
		tasksFile:write('\t\t\t},\n')
		tasksFile:write('\t\t\t"group":\n')
		tasksFile:write('\t\t\t{\n')
		tasksFile:write('\t\t\t\t"kind": "build",\n')
		tasksFile:write('\t\t\t},\n')
		tasksFile:write('\t\t},\n')
	end
end

function m.vscode_launch(prj, launchFile)
	for cfg in project.eachconfig(prj) do
		if cfg.kind == "ConsoleApp" or cfg.kind == "WindowedApp" then --Ignore non executable configuration(s) in launch.json
			local buildName = "Build " .. prj.name .. " (" .. cfg.name .. ")"
			local target = path.getrelative(prj.workspace.location, prj.location)
			local gdbPath = ""
			if os.host() == "linux" then
				gdbPath = os.outputof("which gdb")
			end
			local programPath = path.getrelative(prj.workspace.location, cfg.buildtarget.abspath)

			launchFile:write('\t\t{\n')
			launchFile:write(string.format('\t\t\t"name": "Run %s (%s)",\n', prj.name, cfg.name))
			launchFile:write('\t\t\t"request": "launch",\n')
			launchFile:write('\t\t\t"type": "cppdbg",\n')
			launchFile:write(string.format('\t\t\t"program": "${workspaceRoot}/%s",\n', programPath))
			launchFile:write('\t\t\t"linux":\n')
			launchFile:write('\t\t\t{\n')
			launchFile:write('\t\t\t\t"externalConsole": true,\n')
			launchFile:write(string.format('\t\t\t\t"miDebuggerPath": "%s",\n', gdbPath))
			launchFile:write('\t\t\t\t"MIMode": "gdb",\n')
			launchFile:write('\t\t\t\t"setupCommands":\n')
			launchFile:write('\t\t\t\t[\n')
			launchFile:write('\t\t\t\t\t{\n')
			launchFile:write('\t\t\t\t\t\t"text": "-enable-pretty-printing",\n')
			launchFile:write('\t\t\t\t\t\t"description": "enable pretty printing",\n')
			launchFile:write('\t\t\t\t\t\t"ignoreFailures": true,\n')
			launchFile:write('\t\t\t\t\t},\n')
			launchFile:write('\t\t\t\t],\n')
			launchFile:write('\t\t\t},\n')
			launchFile:write('\t\t\t"windows":\n')
			launchFile:write('\t\t\t{\n')
			launchFile:write('\t\t\t\t"console": "externalTerminal",\n')
			launchFile:write('\t\t\t\t"type": "cppvsdbg",\n')
			launchFile:write(string.format('\t\t\t\t"program": "${workspaceRoot}/%s",\n', programPath))
			launchFile:write('\t\t\t},\n')
			launchFile:write('\t\t\t"args": [],\n')
			launchFile:write('\t\t\t"stopAtEntry": false,\n')
			launchFile:write(string.format('\t\t\t"cwd": "${workspaceFolder}/%s",\n', target))
			launchFile:write('\t\t\t"environment": [],\n')
			launchFile:write(string.format('\t\t\t"preLaunchTask": "Build %s (%s)",\n', prj.name, cfg.name))
			launchFile:write('\t\t},\n')
		end
	end
end

function m.vscode_c_cpp_properties(prj, propsFile)
	local cdialect = "${default}"
	if prj.cdialect then
		cdialect = string.lower(prj.cdialect)
	end

	local cppdialect = "${default}"
	if prj.cppdialect then
		cppdialect = string.lower(prj.cppdialect)
	end

	for cfg in project.eachconfig(prj) do
		propsFile:write('\t\t{\n')

		propsFile:write(string.format('\t\t\t"name": "%s (%s)",\n', prj.name, cfg.name))
		propsFile:write('\t\t\t"includePath":\n')
		propsFile:write('\t\t\t[\n')
		propsFile:write('\t\t\t\t"${workspaceFolder}/**",\n')
		for _, includedir in ipairs(cfg.includedirs) do
			propsFile:write(string.format('\t\t\t\t"%s",\n', includedir))
		end
		propsFile:write('\t\t\t],\n')
		propsFile:write('\t\t\t"defines":\n')
		propsFile:write('\t\t\t[\n')
		for i = 1, #cfg.defines do
			propsFile:write(string.format('\t\t\t\t"%s",\n', cfg.defines[i]:gsub('"','\\"')))
		end
		propsFile:write('\t\t\t],\n')
		propsFile:write(string.format('\t\t\t"cStandard": "%s",\n', cdialect))
		propsFile:write(string.format('\t\t\t"cppStandard": "%s",\n', cppdialect))
		propsFile:write('\t\t\t"intelliSenseMode": "${default}",\n')

		propsFile:write('\t\t},\n')
	end
end
