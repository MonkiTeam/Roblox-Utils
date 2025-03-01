return function (tbl, visited)
    local result = ""
    visited = visited or {}

    if visited[tbl] then
        return "{<circular reference detected>}"
    end
    visited[tbl] = true

    for key, value in pairs(tbl) do
        local valueStr
        local keyStr = '["' .. tostring(key) .. '"]'

        if type(value) == "table" then
            valueStr = "{" .. tableToString(value, visited) .. "}"
        elseif type(value) == 'CFrame' then
            valueStr = "CFrame.new(" .. tostring(value) .. ")"
        elseif type(value) == 'boolean' then
            valueStr = tostring(value)
        elseif type(value) == 'function' then
            valueStr = "<function>"
        elseif type(value) == 'userdata' then
            valueStr = "CFrame.new(" .. tostring(value) .. ")"
        elseif type(value) == 'thread' then
            valueStr = "<thread>"
        elseif type(value) == 'nil' then
            valueStr = "nil"
        elseif type(value) == 'number' then
            valueStr = tostring(value)
        else
            valueStr = '"' .. tostring(value) .. '"'
        end

        result = result .. keyStr .. " = " .. valueStr .. ",\n"
    end

    return result
end
