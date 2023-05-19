--
-- Name:        vscode.lua
-- Purpose:     Define the vscode action(s).
-- Author:      Ryan Pusztai
-- Modified by: Andrea Zanellato
--              Andrew Gough
--              Manu Evans
--              Jason Perkins
--              Yehonatan Ballas
--              Jan "GamesTrap" Schürkamp
-- Created:     2013/05/06
-- Updated:     2022/12/29
-- Copyright:   (c) 2008-2020 Jason Perkins and the Premake project
--              (c) 2022-2023 Jan "GamesTrap" Schürkamp
--

local p = premake

p.modules.vscode = {}
p.modules.vscode._VERSION = p._VERSION

local vscode = p.modules.vscode
local project = p.project


function vscode.generateWorkspace(wks)
    -- Only create workspace file if it doesnt already exist
    if not os.isfile(wks.location .. "/" .. wks.name .. ".code-workspace") then
        local codeWorkspaceFile = io.open(wks.location .. "/" .. wks.name .. ".code-workspace", "w")
        codeWorkspaceFile:write('{\n\t"folders":\n\t[\n\t\t{\n\t\t\t"path": ".",\n\t\t},\n\t],\n}\n')
        codeWorkspaceFile:close()
    end

    local startString = '{\n\t"version": "%s",\n\t"%s":\n\t[\n'

    -- Create tasks.json file
    local tasksFile = io.open(wks.location .. "/.vscode/tasks.json", "w")
    tasksFile:write('{\n\t"version": "2.0.0",\n\t"tasks":\n\t[\n')

    -- Create launch.json file
    local launchFile = io.open(wks.location .. "/.vscode/launch.json", "w")
    launchFile:write('{\n\t"version": "2.0.0",\n\t"configurations":\n\t[\n')

    -- Create launch.json file
    local propsFile = io.open(wks.location .. "/.vscode/c_cpp_properties.json", "w")
    propsFile:write('{\n\t"version": 4,\n\t"configurations":\n\t[\n')

    local containsSupportedProject = 0

    -- For each project
    for prj in p.workspace.eachproject(wks) do
        if project.isc(prj) or project.iscpp(prj) then
            containsSupportedProject = containsSupportedProject + 1

            vscode.project.vscode_tasks(prj, tasksFile)
            vscode.project.vscode_launch(prj, launchFile)
            vscode.project.vscode_c_cpp_properties(prj, propsFile)
        end
    end

    if containsSupportedProject > 0 then
        vscode.project.vscode_tasks_build_all(wks, tasksFile)
    end

    propsFile:write('\t]\n}\n')
    propsFile:close()

    launchFile:write('\t]\n}\n')
    launchFile:close()

    tasksFile:write('\t]\n}\n')
    tasksFile:close()
end

include("vscode_project.lua")

include("_preload.lua")

return vscode
