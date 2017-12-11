local lve
local folderOfThisFile = (...):match("(.-)[^%/%.]+$")

return function(lib)
    -- Get reference to the library
    lve = lib

    local Entity = require(folderOfThisFile .. "entity")(lve)

    local Engine = {}

    -- Called by the library upon requesting a new engine.
    -- Can be called to reset the engine.
    function Engine:init()
        -- Used to give an enetity an id upon creation.
        self.entityCreationId = 1

        -- List of all entities belonging to this engine.
        -- Key = entityId
        -- Value = EntityLayer
        self.entities = {}

        -- List of all entities stored in layers. 
        -- Key = layer level. 
        -- Value = List of entities within this layer.
        --      Key = entity id
        --      Value = entity reference
        self.entityLayers = {}

        -- List of named entities. 
        -- Key = Entity name
        -- Value = entity Id.
        self.namedEntities = {}

        -- List of all systems belonging to this engine.
        -- Key = system name
        -- Value = system reference.
        self.systems = {}

        -- List of all systems sorted by required components
        -- Key = component name
        -- Value = List of systems
        --      Key = System name
        --      Value = system reference
        self.systemsByComponents = {}
    end

    -- Create a new entity within the engine.
    -- layer:
    --      (default = 1) The layer this entity belongs to.
    -- name:
    --      (optional) The name of this entity for convenience access.
    function Engine:newEntity(layer, name)
        layer = layer or 1
        local newEntity = setmetatable({}, Entity)
        newEntity:init(self, self.entityCreationId, layer, name)

        self.entities[self.entityCreationId] = newEntity
        self.entityCreationId = self.entityCreationId + 1

        if not self.entityLayers[layer] then
            for i = #self.entityLayers + 1, layer do
                self.entityLayers[i] = {}
            end
        end

        self.entities[newEntity.id] = layer
        self.entityLayers[layer][newEntity.id] = newEntity

        if name then
            self.namedEntities[name] = newEntity.id
        end

        return newEntity
    end

    -- Adds a system to the engine and updates all entities (potentially slow. Don't add systems on a per frame basis!)
    -- newSystem:
    --      The system to be added.
    -- layer:
    --      (default = 1) The drawing layer this system belongs to. If the system doesn't draw. This will be used as update layer instead.
    -- updateLayer:
    --      (default = 1) The update layer this system belongs to.
    function Engine:addSystem(newSystem, layer, updateLayer)       
        if not newSystem then
            lve.debug("error", "Engine:addSystem", "No newSystem provided!")
            return
        end

        if not newSystem.type == "System" then
            lve.debug("error", "Engine:addSystem", "newSystem not of type 'System'")
            return
        end

        if not newSystem.name then
            lve.debug("error", "Engine:addSystem", "newSystem has no name!")
            return
        end

        if self.systems[newSystem.name] then
            lve.debug("warning", "Engine:addSystem", "System with the same name has already been added and will be overwritten!")
        end

        self.systems[newSystem.name] = newSystem

        for _, componentName in pairs(newSystem:requires()) do
            if not self.systemsByComponents[componentName] then
                self.systemsByComponents[componentName] = {}
            end

            self.systemsByComponents[componentName][newSystem.name] = newSystem
        end

        local requiredComponents = newSystem:requires()
        
        -- If the system doesn't draw, use the layer as update layer instead.
        local drawLayer
        if newSystem.draw then
            drawLayer = layer or 1
            updateLayer = updateLayer or 1
        else
            updateLayer = layer or 1
        end

        for _, layer in pairs(self.entities) do
            for _, entity in pairs(layer) do
                if entity:meetsRequirements(requiredComponents) then
                    entity:addSystem(newSystem, drawLayer, updateLayer)
                end
            end
        end
    end

    -- Removes a system from the engine. (Not nearly as bad as add system. But you shouldn't do this per frame either.)
    -- systemName:
    --      The name of the system to be removed.
    function Engine:removeSystem(systemName)
        self.systems[systemName] = nil

        for _, componentName in pairs(self.systems[systemName]) do
            self.systemsByComponents[componentName][systemName] = nil
        end

        -- Remove system from all entities.
        for _, layer in pairs(self.entities) do
            for _, entity in pairs(layer) do
                entity:removeSystem(systemName)
            end
        end
    end

    -- Adds all systems this entity belongs to, to the entity. If component name is provided, only check systems requiring that component.
    -- This function should only be called by entities or the engine!
    -- entity:
    --      Reference to the entity that should be checked.
    -- newComponentName:
    --      (optional) The name of the component that has been added.
    function Engine:addApplicableSystems(entity, newComponentName)
        if not entity then
            lve.debug("error", "Engine:getApplicableSystems", "No entity provided!")
            return
        end

        if newComponentName then
            for _, systemList in pairs(self.systemsByComponents) do
                for _, system in pairs(systemList) do
                    if entity:meetsRequirements(system:requires()) then
                        entity:addSystem(system)
                    end
                end
            end
        else
            for _, system in pairs(self.systems) do
                if entity:meetsRequirements(system:requires()) then
                    entity:addSystem(system)
                end
            end
        end
    end

    -- Updates all entities, starting with entities in the highest layer.
    -- dt:
    --      Delta time. The time since the last frame. Will be forwarded to the system.
    function Engine:update(dt)
        for i = #self.entityLayers, 1, -1 do
            for _, entity in pairs(self.entityLayers[i]) do
                entity:update(dt)
            end
        end
    end

    -- Draws all entities, starting with entities in the highest layer.
    function Engine:draw()
        for i = #self.entityLayers, 1, -1 do
            for _, entity in pairs(self.entityLayers[i]) do
                entity:draw()
            end
        end
    end

    -- Returns the engine metatable.
    -- No engine creation function is provided.
    -- The library init takes care of that!
    return {__index=Engine}
end