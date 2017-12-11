local lve

return function(lib)
    -- Get reference to the library
    lve = lib

    local System = {}

    -- Called by the library upon requesting a new system.
    -- Should only be called by the library.
    function System:init(name)
        self.type = "System"
        self.name = name
    end

    -- Fallback function to prevent crashes and allow for systems whos entity lists are handled manually.
    function System:requires()
        return {}
    end 

    -- Returns the system metatable.
    -- No system creation function is provided!
    -- The library init takes care of that!
    return {__index=System}
end