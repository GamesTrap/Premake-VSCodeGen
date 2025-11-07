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
-- Updated:     2025/11/04
-- Copyright:   (c) 2008-2020 Jason Perkins and the Premake project
--              (c) 2022-2025 Jan "GamesTrap" Schürkamp
--

local p = premake
local vscode = {}
p.modules.vscode = vscode

local function GetCProjects(wks)
    local list = {}
    local idx = 1

    for prj in p.workspace.eachproject(wks) do
        if p.project.isc(prj) or p.project.iscpp(prj) then
            list[idx] = prj
            idx = idx + 1
        end
    end

    return list
end

-- Create .code-workspace file if it doesnt already exist
local function GenerateVSCodeWorkspaceFile(wks)
    local workspaceFilename = string.format("%s.code-workspace", wks.name)
    local workspacePath = p.filename(wks, workspaceFilename)

    if os.isfile(workspacePath) then
        return
    end

    p.generate(wks, workspaceFilename, function(wks)
        p.push('{')
        p.w('"folders":')
        p.push('[')
        p.push('{')
        p.w('"path": "."')
        p.pop('}')
        p.pop(']')
        p.pop('}')
        p.outln('')
    end)
end

-- Create tasks.json file
local function GenerateTasksFile(wks, cProjects)
    local tasksPath = string.format("%s/.vscode/tasks.json", wks.location)

    p.generate(wks, tasksPath, function(wks)
        p.push('{')
        p.w('"version": "2.0.0",')
        p.w('"tasks":')
        p.push('[')

        for _, prj in ipairs(cProjects) do
            vscode.project.vscode_tasks(prj)
        end

        if #cProjects > 0 then
            vscode.project.vscode_tasks_build_all(wks)
        end

        p.pop(']')
        p.pop('}')
        p.outln('')
    end)
end

-- Create launch.json file
local function GenerateLaunchFile(wks, cProjects)
    local launchPath = string.format("%s/.vscode/launch.json", wks.location)

    p.generate(wks, launchPath, function(wks)
        p.push('{')
        p.w('"version": "2.0.0",')
        p.w('"configurations":')
        p.push('[')

        for idx, prj in ipairs(cProjects) do
            vscode.project.vscode_launch(prj, idx == #cProjects)
        end

        p.pop(']')
        p.pop('}')
        p.outln('')
    end)
end

-- Create c_cpp_properties.json file
local function GenerateCCppPropertiesFile(wks, cProjects)
    if #cProjects == 0 then
        return
    end

    local ccppPropertiesPath = string.format("%s/.vscode/c_cpp_properties.json", wks.location)

    p.generate(wks, ccppPropertiesPath, function(wks)
        p.push('{')
        p.w('"version": 4,')
        p.w('"configurations":')
        p.push('[')

        for idx, prj in ipairs(cProjects) do
            vscode.project.vscode_c_cpp_properties(prj, idx == #cProjects)
        end

        p.pop(']')
        p.pop('}')
        p.outln('')
    end)
end

function vscode.generateWorkspace(wks)
    local cProjects = GetCProjects(wks)

    GenerateVSCodeWorkspaceFile(wks)
    GenerateTasksFile(wks, cProjects)
    GenerateLaunchFile(wks, cProjects)
    GenerateCCppPropertiesFile(wks, cProjects)
end

include("vscode_project.lua")
include("_preload.lua")

return vscode
