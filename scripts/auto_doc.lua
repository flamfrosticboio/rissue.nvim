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

-- RIssue - Plugin for getting issues and merge requests from git providers
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

local file_cache = {}

local FOLDER = "lua/rissue-nvim"

---@param path string
---@return string? contents
---@return string? err_msg
local function read_file(path)
  if file_cache[path] then
    return file_cache[path]
  end

  local ok, res = pcall(function()
    local fd, err = io.open(path, "r")
    if not fd then
      error(err, 0)
    end
    local contents, read_err = fd:read("*a")
    local close_ok, err_msg, code = fd:close()
    if not contents and read_err then
      error(tostring(read_err), 0)
    end
    if not close_ok then
      error(tostring(err_msg) .. " [code: " .. tostring(code) .. "]", 0)
    end
    return contents
  end)

  if ok and res then
    file_cache[path] = res
    return res
  end
  return nil, res or "no content was given (bug)"
end

---@param path string
---@param contents string
---@return string? err_msg
local function write_file(path, contents)
  local ok, res = pcall(function()
    local fd, err = io.open(path, "w")
    if not fd then
      error(err, 0)
    end

    local _, w_err = fd:write(contents)
    local close_ok, err_msg, code = fd:close()

    if w_err then
      error(w_err, 0)
    end
    if not close_ok then
      error(tostring(err_msg) .. " [code: " .. tostring(code) .. "]", 0)
    end
    return contents
  end)

  if not ok then
    return res or "unknown error"
  end
end

---@param str string
local function escape_pattern(str)
  return str:gsub("[%(%)%.%%%+%-%*%?%[%]%^%$]", "%%%1")
end

---@return string?
local function getCallerSourceLine(level)
  level = level or 0
  local info = debug.getinfo(2 + level, "Sl")
  local f = io.open(info.short_src, "r")
  if not f then
    return nil
  end

  local n, result = 0, nil
  for line in f:lines() do
    n = n + 1
    if n == info.currentline then
      result = line
      break
    end
  end
  f:close()

  return result
end

---@generic T: type
---@param obj table
---@param cls `T`
---@return T
local function get(obj, cls)
  local item = obj
  if type(item) ~= cls then
    local ok, field_expr = xpcall(function()
      local line = getCallerSourceLine(3)
      ---@cast line string
      line = line:match("^%s*(.-)%s*$")
      local name = line:match("get(%b())")
      ---@cast name string
      name = name:match("%(([%w.]+),")
      return name
    end, function()
      return "Object type is not a " .. cls
    end)

    if not ok then
      error(field_expr, 2)
    else
      error(("'%s' is not a %s"):format(field_expr, cls), 2)
    end
  end
  return item
end

---@param desc string
local function format_desc(desc)
  return desc:match("^%s*(.-)%s*$"):gsub("\n ", "\n")
end

---@class __rissue.auto_doc.Spec
---@field description string?
---@field fields string[]?
---@field docs string?

---@param parent_name string
---@param fields table[]
---@param buffer table<string, __rissue.auto_doc.Spec>
---@param parent_spec __rissue.auto_doc.Spec
local function parse_fields(parent_name, fields, buffer, parent_spec)
  for _, field in ipairs(fields) do
    ---@type __rissue.auto_doc.Spec
    local spec = {}
    local suffix = ""

    if field.view == "function" then
      suffix = "()"
    end

    if field.rawdesc then
      spec.description = format_desc(get(field.rawdesc, "string"))
    end

    local name = parent_name .. "." .. field.name .. suffix

    local function parse_docs()
      ---@type string[]
      local lines = {}

      lines[#lines + 1] = ("### %s"):format(name)
      if spec.description then
        lines[#lines + 1] = ""
        lines[#lines + 1] = spec.description
      end

      if field.view == "function" then
        if type(field.extends.args) == "table" then
          lines[#lines + 1] = "\n**Parameters:**\n"
          for _, arg in ipairs(field.extends.args) do
            local line = string.format("- `%s`: `%s`", arg.name, arg.view)

            if arg.rawdesc then
              line = line .. string.format(" -- %s", arg.rawdesc)
            end

            lines[#lines + 1] = line
          end
        end

        if type(field.extends.returns) == "table" then
          lines[#lines + 1] = "\n**Returns:**\n"
          for i, ret in ipairs(field.extends.returns) do
            local line = string.format("- (%d) `%s`", i, ret.view)
            if ret.rawdesc then
              line = line .. " -- " .. ret.rawdesc
            end

            lines[#lines + 1] = line
          end
        end
      end

      spec.docs = table.concat(lines, "\n")
    end

    parse_docs()

    buffer[name] = spec
    if not parent_spec.fields then
      parent_spec.fields = {}
    end

    parent_spec.fields[#parent_spec.fields + 1] = name
  end
end

---@param entry table
---@param buffer table<string, __rissue.auto_doc.Spec>
local function parse_entry(entry, buffer)
  local name = get(entry.name, "string")
  local defines = get(entry.defines, "table")
  local first_define_entry = defines[1]
  assert(first_define_entry, "Define field is empty")
  local filename = get(first_define_entry.file, "string")
  assert(filename, "Filename not found")

  ---@type __rissue.auto_doc.Spec
  local spec = {}

  if entry.desc then
    spec.description = format_desc(get(entry.rawdesc, "string"))
  end

  local function parse_docs()
    local lines = {}

    lines[#lines + 1] = "### `" .. entry.name .. "`"
    lines[#lines + 1] = ""

    if spec.description then
      lines[#lines + 1] = spec.description
    end

    if entry.type == "type" then
      if #entry.fields > 0 then
        lines[#lines + 1] = ""
        for _, field in ipairs(entry.fields) do
          if field.visible == "public" then
            if field.type == "doc.field" then
              local line = ("- %s: `%s`"):format(field.name, field.view)
              if field.rawdesc then
                ---@type string
                local header = " -- " .. field.rawdesc
                header = header:gsub("\n", "\n  ")
                if #line + #header > 80 then
                  line = line .. "\n" .. header
                else
                  line = line .. header
                end
              end

              lines[#lines + 1] = line
            end
          end
        end
      end
    end
    if #lines > 0 then
      spec.docs = table.concat(lines, "\n")
    end
  end

  parse_docs()

  if #entry.fields > 0 then
    parse_fields(name, entry.fields, buffer, spec)
  end

  buffer[name] = spec
end

local constants_pattern_lua = "%-%-%-%s*###%s*([%w.]+)%s*###%s*---"
---@param raw string
local function parse_seen_constants(raw, buffer)
  for constant_name in raw:gmatch(constants_pattern_lua) do
    local headers = "\n%-%-%-%s*###%s*" .. constant_name .. "%s*###%s*---%s*\n"
    local pattern = headers .. "(.-)" .. headers
    local result = raw:match(pattern) ---@type string?
    if result then
      result = result:match("^%s*(.-)%s*$")
      buffer[constant_name] = result
    end
  end
end

local function list_files_deep(dir, callback)
  local handle = vim.uv.fs_scandir(dir)
  if not handle then
    return
  end

  while true do
    ---@type string?, string?
    local name, type = vim.uv.fs_scandir_next(handle)
    if not name then
      break
    end

    if name ~= "." and name ~= ".." then
      local path = dir .. "/" .. name

      -- uv.fs_scandir_next returns type directly ('file', 'directory', etc.)
      -- If type is nil (rare on some OS/filesystems), fallback to uv.fs_stat
      if not type then
        local stat = vim.uv.fs_stat(path)
        type = stat and stat.type
      end

      if type == "file" then
        callback(path)
      elseif type == "directory" then
        list_files_deep(path, callback)
      end
    end
  end
end

---@return table<string, __rissue.auto_doc.Spec>
local function get_types()
  vim.uv.fs_mkdir(".tmp", 493)

  os.execute("lua-language-server --doc=" .. FOLDER .. " --doc_out_path=.tmp")

  local raw, read_err = read_file(".tmp/doc.json")
  assert(raw, read_err)
  local spec = vim.json.decode(raw)
  assert(type(spec) == "table", "Not a table")

  local buffer = {}
  for _, item in ipairs(spec) do
    assert(type(item) == "table", "An entry is not a table")
    local name = get(item.name, "string")

    if name:match("^rissue") then
      parse_entry(item, buffer)
    end
  end

  return buffer
end

local function get_constants()
  local constants = {}
  list_files_deep(FOLDER, function(filename)
    local contents, err = read_file(filename)
    if not contents then
      print(err)
    else
      parse_seen_constants(contents, constants)
    end
  end)

  return constants
end

---@param raw string
---@param types table<string, __rissue.auto_doc.Spec>
---@return string
local function write_types(raw, types)
  local saw = {}
  for name, field in raw:gmatch("<!%-%-%s*&([%w_%.%(%)]+)@(%w+)%s*%-%->") do
    assert(type(name) == "string", "Not a string")
    assert(type(field) == "string", "Not a string")

    if not (saw[name] and saw[name][field]) then
      if not types[name] or not types[name][field] then
        error("unknown entry: " .. name .. "@" .. field)
      end

      if not saw[name] then
        saw[name] = {}
      end
      saw[name][field] = true

      local name_escaped = escape_pattern(name)
      local field_escaped = escape_pattern(field)

      local ends = "<!%-%-%s*&"
        .. name_escaped
        .. "@"
        .. field_escaped
        .. "%s*%-%->"
      local find_pattern = ends .. ".-" .. ends

      local headers = "<!-- &" .. name_escaped .. "@" .. field_escaped .. " -->"
      local replacement = headers
        .. "\n\n"
        .. types[name][field]
        .. "\n\n"
        .. headers

      raw = raw:gsub(find_pattern, replacement)
    end
  end

  return raw
end

---@param raw string
---@param constants table<string, string>
---@return string
local function write_constants(raw, constants)
  local saw = {}
  for const in raw:gmatch("<!%-%-%s*%*([%w.]+)%s*%-%->") do
    if not saw[const] then
      if not constants[const] then
        error("unknown constant: " .. const, 0)
      end
      saw[const] = true

      local ends = "<!%-%-%s*%*" .. const .. "%s*%-%->"
      local find_pattern = ends .. ".-" .. ends

      local headers = "<!-- *" .. const .. " -->"
      local replacement = headers
        .. "\n\n```lua\n"
        .. constants[const]
        .. "\n```\n\n"
        .. headers

      raw = raw:gsub(find_pattern, replacement)
    end
  end

  return raw
end

---@param raw string
---@param infos __rissue.auto_doc.infos
---@return string
local function write_blocks(raw, infos)
  raw = write_types(raw, infos.types)
  raw = write_constants(raw, infos.constants)

  return raw
end

---@class __rissue.auto_doc.infos
---@field types table<string, __rissue.auto_doc.Spec>
---@field constants table<string, string>

local function main()
  ---@type __rissue.auto_doc.infos
  local info = {
    types = get_types(),
    constants = get_constants(),
  }

  list_files_deep("docs/", function(filepath)
    print(filepath)
    local contents, err = read_file(filepath)
    if contents then
      local result = write_blocks(contents, info)
      write_file(filepath, result)

      os.execute("prettier --write " .. filepath)

      local fres, rerr = read_file(filepath)
      if not fres then
        print(rerr)
      elseif contents ~= fres then
        print("Changes made on " .. filepath)
      end
    else
      print(err)
    end
  end)
end

main()
print("Done")
