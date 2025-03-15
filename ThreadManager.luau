local ThreadManager = {}
ThreadManager.threads = {}
ThreadManager.pausedThreads = {}

function ThreadManager:Spawn(name, func, ...)
	local thread
	thread = task.spawn(function(...)
		while true do
			if ThreadManager.pausedThreads[name] then
				repeat task.wait() until not ThreadManager.pausedThreads[name]
			end
			func(...)
			ThreadManager.threads[name] = nil
			break
		end
	end, ...)

	ThreadManager.threads[name] = thread
	return thread
end

function ThreadManager:CancelAll()
	for name, thread in pairs(ThreadManager.threads) do
		task.cancel(thread)
	end
	ThreadManager.threads = {}
	ThreadManager.pausedThreads = {}
end

function ThreadManager:Cancel(name)
	if ThreadManager.threads[name] then
		task.cancel(ThreadManager.threads[name])
		ThreadManager.threads[name] = nil
		ThreadManager.pausedThreads[name] = nil
	end
end

function ThreadManager:IsRunning(name)
	return ThreadManager.threads[name] ~= nil
end

function ThreadManager:Pause(name)
	if ThreadManager.threads[name] then
		ThreadManager.pausedThreads[name] = true
	end
end

function ThreadManager:Resume(name)
	if ThreadManager.threads[name] and ThreadManager.pausedThreads[name] then
		ThreadManager.pausedThreads[name] = nil
	end
end
