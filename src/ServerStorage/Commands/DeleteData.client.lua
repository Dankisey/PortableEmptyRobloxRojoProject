local DataStoreService = game:GetService("DataStoreService")

local dataStores = {
    DataStoreService:GetDataStore("PlayersSavesData");
}

local idsToDelete = {
	7333499935
}

for _, dataStore in pairs(dataStores) do
    for _, id in pairs(idsToDelete) do
        local success, value = pcall(dataStore.RemoveAsync, dataStore, id)

        if not success then
            warn(value)
        end
    end
end

print("done")