local M = {}

local function jsonEncode(data, level)
    local indent = string.rep("  ", level)
    local nextIndent = string.rep("  ", level + 1)
    
    -- Handle arrays
    if #data > 0 then
      if #data == 0 then return "[]" end
      
      local result = "[\n"
      for i, v in ipairs(data) do
        result = result .. nextIndent .. jsonEncode(v, level + 1)
        if i < #data then
          result = result .. ",\n"
        else
          result = result .. "\n"
        end
      end
      return result .. indent .. "]"
    end
    
    -- Handle objects
    local empty = true
    for _ in pairs(data) do empty = false; break end
    if empty then return "{}" end
    
    local result = "{\n"
    local isFirst = true
    
    -- Add all fields
    for key, value in pairs(data) do
      if not isFirst then result = result .. ",\n" end
      isFirst = false
      result = result .. nextIndent .. '"' .. key .. '": ' .. jsonEncode(value, level + 1)
    end
    
    return result .. "\n" .. indent .. "}"
  end

local function jsonDecoder(jsonString)
    local pos = 1
    local len = #jsonString
    
    -- Skip whitespace
    local function skipWhitespace()
        while pos <= len and jsonString:sub(pos, pos):match("%s") do
            pos = pos + 1
        end
    end
    
    -- Parse string value
    local function parseString()
        if jsonString:sub(pos, pos) ~= '"' then
            error("Expected string at position " .. pos)
        end
        pos = pos + 1 -- skip opening quote
        local start = pos
        
        while pos <= len do
            local char = jsonString:sub(pos, pos)
            if char == '"' then
                local result = jsonString:sub(start, pos - 1)
                pos = pos + 1 -- skip closing quote
                -- Handle basic escape sequences
                result = result:gsub("\\\"", '"')
                result = result:gsub("\\\\", "\\")
                result = result:gsub("\\/", "/")
                result = result:gsub("\\n", "\n")
                result = result:gsub("\\r", "\r")
                result = result:gsub("\\t", "\t")
                return result
            elseif char == "\\" then
                pos = pos + 2 -- skip escape sequence
            else
                pos = pos + 1
            end
        end
        error("Unterminated string")
    end
    
    -- Parse number value
    local function parseNumber()
        local start = pos
        if jsonString:sub(pos, pos) == "-" then
            pos = pos + 1
        end
        
        while pos <= len and jsonString:sub(pos, pos):match("%d") do
            pos = pos + 1
        end
        
        if pos <= len and jsonString:sub(pos, pos) == "." then
            pos = pos + 1
            while pos <= len and jsonString:sub(pos, pos):match("%d") do
                pos = pos + 1
            end
        end
        
        if pos <= len and jsonString:sub(pos, pos):lower() == "e" then
            pos = pos + 1
            if pos <= len and (jsonString:sub(pos, pos) == "+" or jsonString:sub(pos, pos) == "-") then
                pos = pos + 1
            end
            while pos <= len and jsonString:sub(pos, pos):match("%d") do
                pos = pos + 1
            end
        end
        
        return tonumber(jsonString:sub(start, pos - 1))
    end
    
    -- Forward declaration
    local parseValue
    
    -- Parse array
    local function parseArray()
        local result = {}
        pos = pos + 1 -- skip opening bracket
        skipWhitespace()
        
        if pos <= len and jsonString:sub(pos, pos) == "]" then
            pos = pos + 1
            return result
        end
        
        local index = 1
        while true do
            result[index] = parseValue()
            index = index + 1
            skipWhitespace()
            
            if pos <= len and jsonString:sub(pos, pos) == "]" then
                pos = pos + 1
                break
            elseif pos <= len and jsonString:sub(pos, pos) == "," then
                pos = pos + 1
                skipWhitespace()
            else
                error("Expected ',' or ']' in array at position " .. pos)
            end
        end
        
        return result
    end
    
    -- Parse object
    local function parseObject()
        local result = {}
        pos = pos + 1 -- skip opening brace
        skipWhitespace()
        
        if pos <= len and jsonString:sub(pos, pos) == "}" then
            pos = pos + 1
            return result
        end
        
        while true do
            skipWhitespace()
            if jsonString:sub(pos, pos) ~= '"' then
                error("Expected string key at position " .. pos)
            end
            
            local key = parseString()
            skipWhitespace()
            
            if pos > len or jsonString:sub(pos, pos) ~= ":" then
                error("Expected ':' after key at position " .. pos)
            end
            pos = pos + 1
            skipWhitespace()
            
            result[key] = parseValue()
            skipWhitespace()
            
            if pos <= len and jsonString:sub(pos, pos) == "}" then
                pos = pos + 1
                break
            elseif pos <= len and jsonString:sub(pos, pos) == "," then
                pos = pos + 1
                skipWhitespace()
            else
                error("Expected ',' or '}' in object at position " .. pos)
            end
        end
        
        return result
    end
    
    -- Parse any value
    parseValue = function()
        skipWhitespace()
        if pos > len then
            error("Unexpected end of input")
        end
        
        local char = jsonString:sub(pos, pos)
        
        if char == '"' then
            return parseString()
        elseif char == "[" then
            return parseArray()
        elseif char == "{" then
            return parseObject()
        elseif char:match("[%-0-9]") then
            return parseNumber()
        elseif jsonString:sub(pos, pos + 3) == "true" then
            pos = pos + 4
            return true
        elseif jsonString:sub(pos, pos + 4) == "false" then
            pos = pos + 5
            return false
        elseif jsonString:sub(pos, pos + 3) == "null" then
            pos = pos + 4
            return nil
        else
            error("Unexpected character '" .. char .. "' at position " .. pos)
        end
    end
    
    return parseValue()
end

local function readJson(filename)
    local file = io.open(filename, "r")
    if not file then
        error("Could not open file for reading: " .. filename)
    end
    
    local content = file:read("*all")
    file:close()
    
    if not content or content == "" then
        error("File is empty or could not read content: " .. filename)
    end
    
    return jsonDecoder(content)
end

local function writeJson(filename, data, level)
    local file = io.open(filename, "w+")
    if not file then
        error("Could not open file for writing: " .. filename)
    end
    
    local jsonString = jsonEncode(data, level or 0)
    file:write(jsonString)
    file:close()
    
    return true
end

M.readJson = readJson
M.writeJson = writeJson
M.jsonEncode = jsonEncode
M.jsonDecoder = jsonDecoder

return M