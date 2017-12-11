local lve

return function(lib)
    -- Get reference to the library
    lve = lib

    local Entity = {}

    -- Called upon requesting a new entity by the engine.
    -- Should only be called by the library.
    function Entity:init(engine, id, layer, name)
        self.engine = engine
        self.systems = {}
        self.systems.update = {}
        self.systems.draw = {}
        self.components = {}
        self.type = "Entity"
        self.id = id
        self.name = name
        self.layer = layer
    end

    -- Updates all systems belonging to this entity.
    -- Called by Engine.update or manually.
    -- dt: 
    --      The time since the last frame. Forwarded to the system.
    function Entity:update(dt)
        for i = #self.systems.update, 1, -1 do
            for _, system in pairs(self.systems.update[i]) do
                system:update(self, dt)
            end
        end
    end

    -- Draws with all systems belonging to this entity.
    -- Called by Engine.draw or manually
    function Entity:draw()
        for i = #self.systems.draw, 1, -1 do
            for _, system in pairs(self.systems.draw[i]) do
                system:draw(self)
            end
        end
    end

    -- Util function for more convenient access to components.
    -- componentName:
    --      The name of the component to get.
    function Entity:get(componentName)
        return self.components[componentName]
    end

    -- Adds a component to the entity
    -- newComponent:
    --      The component to be added to the Entity.
    function Entity:addComponent(newComponent)
        if not newComponent.type == "Component" then
            lve.debug("[!] Entity:addComponent error! newComponent is not of type 'Component'!")
            return
        end

        if not newComponent.name then
            lve.debug("[!] Entity:addComponent error! newComponent has no name!")
            return
        end

        self.components[newComponent.name] = newComponent

        self.engine:addApplicableSystems(self, newComponent.name)

        return self
    end

    -- Removes a component from the entity. 
    -- Also removes all systems which required that component.
    -- componentName:
    --      The name of the component which should be removed.
    --
    -- Returns true if a component was removed.
    function Entity:removeComponent(componentName)
        if not componentName then
            lve.debug("[!] Entity:removeComponent error! No componentName provided!")
            return
        end

        if self.components[componentName] then
            self.components[componentName] = nil

            for systemType, layers in pairs(self.systems) do
                for layer, systems in ipairs(layers) do
                    for systemName, system in pairs(systems) do
                        if not self:meetsRequirements(system:requires()) then
                            self.systems[systemType][layer][systemName] = nil
                            self.systems[systemName] = nil
                        end
                    end
                end
            end

            return true
        else
            return false
        end
    end

    -- Adds a system to the entity. 
    -- Called by the engine when the entity meets the requirements for a new system.
    -- newSystem:
    --      The system this entity should be added to.
    -- drawLayer:
    --      The layer this system should draw on. Systems on higher layers will draw first.
    function Entity:addSystem(newSystem, drawLayer, updateLayer)
        drawLayer = drawLayer or 1
        updateLayer = updateLayer or 1
        if not newSystem.type == "System" then
            lve.debug("error", "Entity:addSystem", "newSystem is not of type 'System'!")
            return
        end
        
        if not newSystem.name then
            lve.debug("error", "Entity:addSystem", "newSystem has no name!")
            return
        end

        if newSystem.draw then
            if self.systems[newSystem.name] then
                if self.systems[newSystem.name].draw then
                    lve.debug("warning", "Entity:addSystem", "A draw system with this name has already been added to this entity and will be removed!")
                    -- Jesus fucking christ. What a wreck of a line.
                    self.systems.draw[self.systems[newSystem.name].draw][newSystem.name] = nil
                end
            else
                self.systems[newSystem.name] = {}
            end

            self.systems[newSystem.name].draw = drawLayer

            if not self.systems.draw[drawLayer] then
                for layer = #self.systems.draw + 1, drawLayer do
                    self.systems.draw[layer] = {}
                end
            end

            self.systems.draw[drawLayer][newSystem.name] = newSystem
        end

        if newSystem.update then
            if self.systems[newSystem.name] then
                if self.systems[newSystem.name].update then
                    lve.debug("warning", "Entity:addSystem", "An update system with this name has already been added to this entity and will be removed!")
                    -- What idiot wrote this stupid unreadable shit twice? Me? Who is spreading these rumors? Where are you getting your information?
                    self.systems.update[self.systems[newSystem.name].update][newSystem.name] = nil
                end
            else
                self.systems[newSystem.name] = {}
            end

            self.systems[newSystem.name].update = updateLayer


            if not self.systems.update[updateLayer] then
                for layer = #self.systems.update + 1, updateLayer do
                    self.systems.update[layer] = {}
                end
            end

            self.systems.update[updateLayer][newSystem.name] = newSystem
        end

        return self
    end

    -- Removes a system from the entity.
    -- Called by the engine when the system doesn't meet the requirements anymore.
    -- systemName:
    --      The name of the system to be removed.
    --
    -- Returns true if a system was removed.
    function Entity:removeSystem(systemName)
        if not systemName then
            lve.debug("error", "Entity:removeSystem", "No systemName provided!")
            return
        end

        if self.systems[systemName] then
            if self.systems[systemName].draw then
                self.systems.draw[self.systems[systemName].draw][systemName] = nil
            end

            if self.systems[systemName].update then
                self.systems.update[self.systems[systemName].update][systemName] = nil
            end
        end
    end

    -- Checks if the entity contains all components within a list.
    -- Called by the engine when adding / removing a system.
    -- requiredComponents:
    --      A list of component names to be checked.
    --
    -- Returns true if the entity owns all components.
    function Entity:meetsRequirements(requiredComponents)
        for _, componentName in pairs(requiredComponents) do
            if not self.components[componentName] then
                return false
            end
        end

        return true
    end

    -- Returns the entity metatable.
    -- No entity creation function is provided!
    -- The engine takes care of that!
    return {__index=Entity}
end
