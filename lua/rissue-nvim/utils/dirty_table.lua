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

local dtable = {}

--- Prepares the table to be dirty
--- @param tbl table
function dtable.dirtify(tbl)
  local size = #tbl
  setmetatable(tbl, { dirty = true, isize = size })
end

--- Adds an item to the dirty table
--- Will break when other operation to append an item is used
---@generic V
---@param tbl V[]
---@param item V
---@param _cls? `V`
---@return integer index
---@diagnostic disable-next-line: unused-local
function dtable.list_append(tbl, item, _cls)
  local metadata = getmetatable(tbl)
  local offset = metadata.isize + 1
  tbl[offset] = item
  metadata.isize = offset
  return offset
end

return dtable
