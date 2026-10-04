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

local config = {}

config.loaded = false

---@type rissue-nvim.Settings
config.settings = {
  core = nil, -- will be handled on the main module
}

---@type rissue-nvim.Picker[]
local pickers = {
  snacks = require("rissue-nvim.pickers.snacks"),
}

---@param opts? rissue-nvim.Opts
function config.setup(opts)
  config.settings = vim.tbl_deep_extend("force", config.settings, opts or {})

  for _, picker in ipairs(pickers) do
    picker.load()
  end
end

return config
