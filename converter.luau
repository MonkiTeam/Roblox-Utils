local Converter = {}

--------------------------
-- Vector3 Conversions --
--------------------------

-- Convert Vector3 to string
function Converter.Vector3ToString(vector)
    if typeof(vector) ~= "Vector3" then
        error("Expected Vector3, got " .. typeof(vector))
    end
    
    -- Format: "X,Y,Z"
    return string.format("%.4f,%.4f,%.4f", vector.X, vector.Y, vector.Z)
end

-- Convert string back to Vector3
function Converter.StringToVector3(str)
    if type(str) ~= "string" then
        error("Expected string, got " .. type(str))
    end
    
    -- Split by comma and convert to numbers
    local parts = string.split(str, ",")
    if #parts ~= 3 then
        error("Invalid Vector3 string format. Expected 'X,Y,Z', got: " .. str)
    end
    
    return Vector3.new(
        tonumber(parts[1]),
        tonumber(parts[2]),
        tonumber(parts[3])
    )
end

--------------------------
-- CFrame Conversions --
--------------------------

-- Convert CFrame to string (compact form)
function Converter.CFrameToString(cf)
    if typeof(cf) ~= "CFrame" then
        error("Expected CFrame, got " .. typeof(cf))
    end
    
    -- Get position and orientation components
    local x, y, z = cf.X, cf.Y, cf.Z
    local m11, m12, m13, m21, m22, m23, m31, m32, m33 = cf:GetComponents()
    
    -- Format: "X,Y,Z,R11,R12,R13,R21,R22,R23,R31,R32,R33"
    return string.format("%.4f,%.4f,%.4f,%.4f,%.4f,%.4f,%.4f,%.4f,%.4f,%.4f,%.4f,%.4f",
        x, y, z, m11, m12, m13, m21, m22, m23, m31, m32, m33)
end

-- Convert CFrame to a more readable string
function Converter.CFrameToReadableString(cf)
    if typeof(cf) ~= "CFrame" then
        error("Expected CFrame, got " .. typeof(cf))
    end
    
    -- Get position component
    local pos = cf.Position
    
    -- Get orientation as angles (in degrees for readability)
    local x, y, z = cf:ToOrientation()
    x, y, z = math.deg(x), math.deg(y), math.deg(z)
    
    -- Format: "Pos: X,Y,Z | Rot: X°,Y°,Z°"
    return string.format("Pos: %.2f,%.2f,%.2f | Rot: %.2f°,%.2f°,%.2f°",
        pos.X, pos.Y, pos.Z, x, y, z)
end

-- Convert string back to CFrame
function Converter.StringToCFrame(str)
    if type(str) ~= "string" then
        error("Expected string, got " .. type(str))
    end
    
    -- Split by comma
    local parts = string.split(str, ",")
    if #parts ~= 12 then
        error("Invalid CFrame string format. Expected 12 values, got: " .. #parts)
    end
    
    -- Convert all parts to numbers
    local values = {}
    for i, part in ipairs(parts) do
        values[i] = tonumber(part)
    end
    
    -- Create CFrame from components
    return CFrame.new(
        values[1], values[2], values[3],  -- Position
        values[4], values[5], values[6],  -- Right vector
        values[7], values[8], values[9],  -- Up vector
        values[10], values[11], values[12] -- Look vector
    )
end

--------------------------------
-- Alternative CFrame Format --
--------------------------------

-- Convert CFrame to more compact form using position and rotation
function Converter.CFrameToCompactString(cf)
    if typeof(cf) ~= "CFrame" then
        error("Expected CFrame, got " .. typeof(cf))
    end
    
    -- Get position
    local posStr = Converter.Vector3ToString(cf.Position)
    
    -- Get orientation angles (in radians)
    local x, y, z = cf:ToOrientation()
    
    -- Format: "X,Y,Z|RX,RY,RZ"
    return string.format("%s|%.6f,%.6f,%.6f", posStr, x, y, z)
end

-- Convert compact string back to CFrame
function Converter.CompactStringToCFrame(str)
    if type(str) ~= "string" then
        error("Expected string, got " .. type(str))
    end
    
    -- Split position and rotation parts
    local parts = string.split(str, "|")
    if #parts ~= 2 then
        error("Invalid compact CFrame string format. Expected 'pos|rot', got: " .. str)
    end
    
    -- Convert position string to Vector3
    local pos = Converter.StringToVector3(parts[1])
    
    -- Convert rotation string to angles
    local rotParts = string.split(parts[2], ",")
    if #rotParts ~= 3 then
        error("Invalid rotation format. Expected 'RX,RY,RZ', got: " .. parts[2])
    end
    
    local rx = tonumber(rotParts[1])
    local ry = tonumber(rotParts[2])
    local rz = tonumber(rotParts[3])
    
    -- Create CFrame from position and orientation
    return CFrame.new(pos) * CFrame.fromOrientation(rx, ry, rz)
end

--------------------------
-- JSON Conversions --
--------------------------

-- Convert Vector3 to JSON-compatible table
function Converter.Vector3ToTable(vector)
    return {
        X = vector.X,
        Y = vector.Y,
        Z = vector.Z
    }
end

-- Convert CFrame to JSON-compatible table
function Converter.CFrameToTable(cf)
    local x, y, z, m11, m12, m13, m21, m22, m23, m31, m32, m33 = cf:GetComponents()
    
    return {
        Position = {X = x, Y = y, Z = z},
        Orientation = {
            R11 = m11, R12 = m12, R13 = m13,
            R21 = m21, R22 = m22, R23 = m23,
            R31 = m31, R32 = m32, R33 = m33
        }
    }
end

-- Convert table back to Vector3
function Converter.TableToVector3(tbl)
    return Vector3.new(tbl.X, tbl.Y, tbl.Z)
end

-- Convert table back to CFrame
function Converter.TableToCFrame(tbl)
    local pos = tbl.Position
    local orient = tbl.Orientation
    
    return CFrame.new(
        pos.X, pos.Y, pos.Z,
        orient.R11, orient.R12, orient.R13,
        orient.R21, orient.R22, orient.R23,
        orient.R31, orient.R32, orient.R33
    )
end

return Converter
