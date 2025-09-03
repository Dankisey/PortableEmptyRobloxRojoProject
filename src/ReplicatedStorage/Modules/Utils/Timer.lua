local Event = require(script.Parent.Event)

local Timer = {}

function Timer:GetLeftTime() : number
    if self.IsFinished then
        return 0
    else
        return self._leftTime or 0
    end
end

function Timer:Reset()
    self._leftTime = 0
    self.IsFinished = false

    if self._countTask then
        task.cancel(self._countTask)
        self._countTask = nil
    end
end

function Timer:Stop()
    if self._countTask then
        task.cancel(self._countTask)
        self._countTask = nil
    end

    if self._leftTime then
        self.Updated:Invoke(self._leftTime)
    end
end

function Timer:Start(countTime: number?)
    self:Reset()

    if countTime then
        self._leftTime = math.clamp(countTime, 0, math.huge)
    else
        self._leftTime = self._leftTime or 0
    end

    self.Updated:Invoke(self._leftTime)

    if self._leftTime > 0 then
        self._countTask = task.spawn(function()
            while task.wait(1) do
                self._leftTime -= 1
                self.Updated:Invoke(self._leftTime)

                if self._leftTime <= 0 then break end
            end

            self.IsFinished = true
            self.Finished:Invoke()
            self._countTask = nil
        end)
    else
        self:ForceFinish()
    end
end

function Timer:ForceFinish()
    self:Reset()
    self.IsFinished = true
    self.Finished:Invoke()
end

function Timer.new()
    local self = setmetatable({}, {__index = Timer})
    self.Updated = Event.new()
    self.Finished = Event.new()
    self.IsFinished = false

    return self
end

return Timer