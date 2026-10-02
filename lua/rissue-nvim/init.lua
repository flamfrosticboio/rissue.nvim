-- RIssue.nvim - Nvim integration for flamfrosticboio/rissue.lua
-- Copyright (C) 2026  flamfrosticboio
--
-- This program is free software: you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation, either version 3 of the License, or
-- (at your option) any later version.
--
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with this program.  If not, see <https://www.gnu.org/licenses/>.

local config = require("rissue-nvim.config")

local rissue = {}

---@generic T
---@param _cls `T`
---@return T
---@diagnostic disable-next-line: unused-local
local function get_module(mod_name, _cls)
  local success, mod = pcall(require, mod_name)
  if not success then
    error(string.format("module '%s' is not installed", mod_name), 0)
  end
  return mod
end

--- Setup rissue.nvim
---@param opts? rissue-nvim.Opts
function rissue.setup(opts)
  config.setup(opts)

  local rissue_mod = get_module("rissue", "rissue")
  rissue_mod.setup(opts and opts.core)

  local rissue_config_mod = get_module("rissue.config", "rissue.mod.Config")
  config.settings.core = rissue_config_mod.options
end

--- Get the current configuration of rissue.nvim
---@return rissue-nvim.Settings
function rissue.get_config()
  return config.settings
end

return rissue
