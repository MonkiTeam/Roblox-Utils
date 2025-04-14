-- ValueRemoteFinder.lua

local ValueRemoteFinder = {}
ValueRemoteFinder.__index = ValueRemoteFinder

-- Constructor for the ValueRemoteFinder class
function ValueRemoteFinder.new(config)
    local self = setmetatable({}, ValueRemoteFinder)
    
    self.config = {
        timeoutSeconds = config and config.timeoutSeconds or 2,
        debugMode = config and config.debugMode or false
    }
    
    self.results = {
        all = {},
        value = {},  -- Remotes that return actual values
        void = {},   -- Remotes that return nil
        error = {},  -- Remotes that throw errors
        timeout = {} -- Remotes that time out
    }
    
    self._searched = false
    
    return self
end

-- Helper method for logging based on debug mode
function ValueRemoteFinder:log(...)
    if self.config.debugMode then
        print("[ValueRemoteFinder]", ...)
    end
end

-- Test a remote function with timeout
function ValueRemoteFinder:testRemote(remote)
    local completed = false
    local success = false
    local result = nil
    local executionTime = 0
    
    local startTime = tick()
    
    task.spawn(function()
        local pcallSuccess, pcallResult = pcall(function()
            return remote:InvokeServer()
        end)
        
        executionTime = tick() - startTime
        success = pcallSuccess
        result = pcallResult
        completed = true
    end)
    
    while not completed do
        if tick() - startTime > self.config.timeoutSeconds then
            break
        end
        task.wait()
    end
    
    return {
        completed = completed,
        success = success,
        result = result,
        executionTime = executionTime,
        timedOut = not completed,
        remote = remote
    }
end

-- Scan an object for RemoteFunctions and test them
function ValueRemoteFinder:scanObject(object)
    self:log("Scanning for value-returning remotes in:", object:GetFullName())
    
    self.results = {
        all = {},
        value = {},
        void = {},
        error = {},
        timeout = {}
    }
    
    for _, child in pairs(object:GetDescendants()) do
        if child:IsA("RemoteFunction") then
            table.insert(self.results.all, child)
        end
    end
    
    self:log("Found", #self.results.all, "RemoteFunctions to test")
    
    for i, remote in ipairs(self.results.all) do
        self:log("Testing remote", i .. "/" .. #self.results.all .. ":", remote:GetFullName())
        
        local result = self:testRemote(remote)
        
        if result.timedOut then
            self:log("  TIMEOUT: Remote did not respond within", self.config.timeoutSeconds, "seconds")
            remote:SetAttribute("Failed", true)
            table.insert(self.results.timeout, remote)
        elseif not result.success then
            self:log("  ERROR: Remote threw an error")
            remote:SetAttribute("Failed", true)
            table.insert(self.results.error, remote)
        elseif result.result ~= nil then
            self:log("  VALUE: Remote returns:", tostring(result.result))
            remote:SetAttribute("Failed", false)
            table.insert(self.results.value, remote)
        else
            self:log("  VOID: Remote returns void/nil")
            remote:SetAttribute("Failed", true)
            table.insert(self.results.void, remote)
        end
        
        self:log("  Time:", string.format("%.3f", result.executionTime), "seconds")
    end
    
    if self.config.debugMode then
        self:printSummary()
    end
    
    self._searched = true
    return self.results
end

function ValueRemoteFinder:scanMerlin()
    local merlin = workspace.world.npcs:FindFirstChild("Merlin")
    if not merlin then
        self:log("Could not find Merlin NPC")
        return nil
    end
    
    local merlinModel = merlin:FindFirstChild("Merlin")
    if not merlinModel then
        self:log("Could not find Merlin model inside Merlin NPC, scanning parent")
        return self:scanObject(merlin)
    end
    
    return self:scanObject(merlinModel)
end

-- Print a summary of the results
function ValueRemoteFinder:printSummary()
    print("\n=== ValueRemoteFinder Summary ===")
    print("  Total remotes tested:", #self.results.all)
    print("  Value-returning remotes:", #self.results.value)
    print("  Void-returning remotes:", #self.results.void)
    print("  Error remotes:", #self.results.error)
    print("  Timeout remotes:", #self.results.timeout)
    print("===============================")
end

-- Get a specific remote by name from results
function ValueRemoteFinder:getRemoteByName(name, category)
    category = category or "value"
  
    if not self._searched then
        self:log("No search has been performed yet")
        return nil
    end
    
    if not self.results[category] then
        self:log("Invalid category:", category)
        return nil
    end
    
    for _, remote in ipairs(self.results[category]) do
        if remote.Name == name then
            return remote
        end
    end
    
    self:log("Could not find", category, "remote with name:", name)
    return nil
end

-- Get remote by name with fallback to similar names
function ValueRemoteFinder:findRemote(name, category)
    category = category or "value"
    
    local exactMatch = self:getRemoteByName(name, category)
    if exactMatch then
        self:log("Found exact", category, "remote match:", exactMatch:GetFullName())
        return exactMatch
    end
    
    self:log("Checking for similar", category, "remotes...")
    for _, remote in ipairs(self.results[category]) do
        if string.find(remote.Name, name) or string.find(name, remote.Name) then
            self:log("Found similar", category, "remote:", remote:GetFullName())
            return remote
        end
    end
    
    self:log("Could not find matching", category, "remote")
    if #self.results[category] > 0 then
        return self.results[category][1] -- Return the first remote as fallback
    end
    
    return nil
end

function ValueRemoteFinder:getResults()
    return self.results
end

function ValueRemoteFinder:getRemotes(category)
    category = category or "value"
    return self.results[category]
end

function ValueRemoteFinder:findRealRemote(name)
    if not self._searched then
        self:log("No search has been performed yet, scanning Merlin")
        self:scanMerlin()
    end
    
    local exactMatch = self:getRemoteByName(name, "value")
    if exactMatch then
        self:log("Found exact real remote match:", exactMatch:GetFullName())
        return exactMatch
    end
    
    local similarMatch = self:findRemote(name, "value")
    if similarMatch then
        return similarMatch
    end
    
    if #self.results.value > 0 then
        self:log("Returning first value-returning remote as fallback")
        return self.results.value[1]
    end
    
    self:log("No real remotes found")
    return nil
end

return ValueRemoteFinder
