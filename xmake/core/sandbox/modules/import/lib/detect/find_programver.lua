--!A cross-platform build utility based on Lua
--
-- Licensed to the Apache Software Foundation (ASF) under one
-- or more contributor license agreements.  See the NOTICE file
-- distributed with this work for additional information
-- regarding copyright ownership.  The ASF licenses this file
-- to you under the Apache License, Version 2.0 (the
-- "License"); you may not use this file except in compliance
-- with the License.  You may obtain a copy of the License at
--
--     http://www.apache.org/licenses/LICENSE-2.0
--
-- Unless required by applicable law or agreed to in writing, software
-- distributed under the License is distributed on an "AS IS" BASIS,
-- WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
-- See the License for the specific language governing permissions and
-- limitations under the License.
-- 
-- Copyright (C) 2015 - 2018, TBOOX Open Source Group.
--
-- @author      ruki
-- @file        find_programver.lua
--

-- define module
local sandbox_lib_detect_find_programver = sandbox_lib_detect_find_programver or {}

-- load modules
local os        = require("base/os")
local path      = require("base/path")
local table     = require("base/table")
local utils     = require("base/utils")
local option    = require("base/option")
local project   = require("project/project")
local sandbox   = require("sandbox/sandbox")
local raise     = require("sandbox/modules/raise")
local cache     = require("sandbox/modules/import/lib/detect/cache")

-- find program version
--
-- @param program   the program
-- @param opt       the options, .e.g {command = "--version", parse = "(%d+%.?%d*%.?%d*.-)%s", verbose = true, force = true, cachekey = "xxx"}
--                    - opt.command   the version command string or script, default: --version
--                    - opt.parse     the version parse script or lua match pattern 
--
-- @return          the version string
--
-- @code
-- local version = find_programver("ccache")
-- local version = find_programver("ccache", {command = "-v"})
-- local version = find_programver("ccache", {command = "--version", parse = "(%d+%.?%d*%.?%d*.-)%s"})
-- local version = find_programver("ccache", {command = "--version", parse = function (output) return output:match("(%d+%.?%d*%.?%d*.-)%s") end})
-- local version = find_programver("ccache", {command = function () return os.iorun("ccache --version") end})
-- @endcode
--
function sandbox_lib_detect_find_programver.main(program, opt)

    -- init options
    opt = opt or {}

    -- init cachekey
    local cachekey = "find_programver"
    if opt.cachekey then
        cachekey = cachekey .. "_" .. opt.cachekey
    end

    -- attempt to get result from cache first
    local cacheinfo = cache.load(cachekey) 
    local result = cacheinfo[program]
    if result ~= nil and not opt.force then
        return utils.ifelse(result, result, nil)
    end

    -- attempt to get version output info
    local ok = false
    local outdata = nil
    local command = opt.command
    if type(command) == "function" then
        ok, outdata = sandbox.load(command)
        if not ok then
            utils.verror(outdata)
        end
    else
        ok, outdata = os.iorunv(program, {command or "--version"})
    end

    -- find version info
    if ok and outdata and #outdata > 0 then
        local parse = opt.parse
        if type(parse) == "function" then
            ok, result = sandbox.load(parse, outdata) 
            if not ok then
                utils.verror(result)
                result = nil
            end
        elseif parse == nil or type(parse) == "string" then
            result = outdata:match(parse or "(%d+%.?%d*%.?%d*.-)%s")
            if not result then
                result = outdata:match(parse or "(%d+%.?%d*%.?%d*.-)")
            end
        end
    end

    -- cache result
    cacheinfo[program] = utils.ifelse(result, result, false)

    -- save cache info
    cache.save("find_programver", cacheinfo)

    -- ok?
    return result
end

-- return module
return sandbox_lib_detect_find_programver
