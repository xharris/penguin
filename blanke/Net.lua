Net = {
    obj_update_rate = 0, -- m/s
    
    is_init = false,
    client = nil,
    
    onReceive = nil,    
    onConnect = nil,    
    onDisconnect = nil, 
    
    address = "localhost",
    port = 12345,
    room = 1,

    _objects = {},          -- objects sync from other clients _objects = {'client12' = {object1, object2, ...}}
    _local_objects = {},    -- objects added by this client

    id = nil,
    _timer = 0,

    init = function(address, port)
        Net.address = ifndef(address, "localhost") 
        Net.port = ifndef(port, Net.port)     
        Net.is_init = true

        Net._timer = Timer():every(Net.updateObjects, 1):start()

        Debug.log("networking initialized")
        return Net
    end,
    
    update = function(dt,override)
        override = ifndef(override, true)

        if Net.is_init then
            if Net.server then Net.server:update(dt) end
            if Net.client then 
                Net.client:update(dt)
                local data = Net.client:receive()
                if data then
                    Net._onReceive(data)
                end
            end
        end
        return Net
    end,
    
    -- returns "Client" object
    join = function(address, port) 
        if Net.client then return end
        if not Net.is_init then
            Net.init(address, port)
        end
        Net.client = grease.udpClient()
        
        Net.client.callbacks.recv = Net._onReceive

        Net.client.handshake = "blanke_net"
        
        Net.client:setPing()
        local success, err = Net.client:connect(Net.address, Net.port)
        
        if success then
            Net.is_connected = true
            Debug.log("joining "..Net.address..':'..Net.port)
        end

        return Net
    end,

    disconnect = function()
        if Net.client then Net.client:disconnect() end
        Net.is_init = false
        Net.is_connected = false
        Net.client = nil

        for clientid, objects in pairs(Net._objects) do
            for o, object in ipairs(objects) do
                if not object.keep_on_disconnect then
                    obj:destroy()
                end
            end
        end

        return Net
    end,

    _onReady = function()
        if Net.onReady then Net.onReady() end
        Net.setRoom(Net.room)
        Net.send({
            type="netevent",
            event="object.sync",
            info={
                new_client=clientid
            }
        })
    end,
    
    _onConnect = function(clientid) 
        Debug.log('+ '..clientid)
    end,
    
    _onDisconnect = function(clientid) 
        Debug.log('- '..clientid)
        if Net.onDisconnect then Net.onDisconnect(clientid) end
        Net.removeClientObjects() 
    end,
    
    _onReceive = function(data, id)
        local raw_data = data
        if data:starts('{') then
            data = json.decode(data)

        elseif data:starts('"') then
            data = data:sub(2,-2)
        end
        if type(data) == "string" and data:ends('\n') then
            data = data:gsub('\n','')
        end

        if type(data) == "string" and data:ends('-') then
            Net._onDisconnect(data:sub(1,-2))
            return
        end

        if type(data) == "string" and data:ends('+') then
            Net._onConnect(data:sub(1,-2))
            return
        end

        if data.type and data.type == 'netevent' and data.room == Net.room then
            --Debug.log(data.event)

            -- get assigned client id
            if data.event == 'getID' then
                Net.id = data.info
                Net._onReady()
            end

            if data.event == 'client.connect' then
                Net._onConnect(data.info)
            end

            if data.event == 'client.disconnect' then
                Net._onDisconnect(data.info)
            end
            
            -- new object added from diff client
            if data.event == 'object.add' and data.clientid ~= Net.id then
                local obj = data.info.object
                local clientid = data.clientid

                Debug.log("added "..obj.classname)
                Net._objects[clientid] = ifndef(Net._objects[clientid], {})
                if not Net._objects[clientid][obj.net_uuid] then
                    Net._objects[clientid][obj.net_uuid] = _G[obj.classname]()
                    Net._objects[clientid][obj.net_uuid].net_object = true
                    
                    if obj.values then
                        for var, val in pairs(obj.values) do
                            Net._objects[clientid][obj.net_uuid][var] = val
                        end
                    end
                end
            end

            -- update net entity
            if data.event == 'object.update' and data.clientid ~= Net.id then
                if Net._objects[data.clientid] then
                    local obj = Net._objects[data.clientid][data.info.net_uuid]
                    if obj then
                        for var, val in pairs(data.info.values) do
                            obj[var] = val
                        end
                    end
                end
            end

            -- send net object data to other clients
            if data.event == 'object.sync' and data.info.new_client ~= Net.id then
                Net.sendSyncObjects()
            end

            -- another entity changed their room
            if data.event == 'room.change' and data.clientid ~= Net.id and data.room ~= Net.room then
                Net.removeClientObjects(data.clientid) 
            end

            -- send to all clients
            if data.event == 'broadcast' then
                print('ALL:',data.info)
            end
        end

        if Net.onReceive then Net.onReceive(data) end
    end,

    send = function(in_data) 
        if in_data.type == 'netevent' then
            in_data.clientid = Net.id
            in_data.room = Net.room
        end

        data = json.encode(in_data)
        if Net.client then Net.client:send(data) end
        return Net
    end,

    setRoom = function(num)
        Net.room = num
        Net.send({
            type='netevent',
            event='room.change'
        })
        Net.removableClientObjects()
    end,

    removeClientObjects = function(clientid) 
        local removable = {}
        if not clientid then
            for id, stuff in pairs(client) do
                removable[id] = Net._objects[id]
            end
        else
            removable[clientid] = Net._objects[clientid]
        end

        if Net._objects[clientid] then
            for o, object in ipairs(Net._objects[clientid]) do
                if not object.keep_on_disconnect then
                    obj:destroy()
                end
            end
            Net._objects[clientid] = nil
        end
    end,

    addObject = function(obj)
        if obj.net_object then return end

        obj.net_uuid = uuid()
        obj.net_var_old = {}
        
        --notify the other server clients
        Net.send({
            type='netevent',
            event='object.add',
            info={
                object = {net_uuid=obj.net_uuid, classname=obj.classname}
            }
        })
        table.insert(Net._local_objects, obj)

        obj.netSync = function(self, ...)
            vars = {...}

            update_values = {}
            if not self.net_object then
                function hasVarChanged(var_name)
                    if self.net_var_old[var_name] and
                       self.net_var_old[var_name] == self[var_name]
                    then
                        return false
                    end
                    self.net_var_old[var_name] = self[var_name]
                    return true
                end

                -- update specific vars
                for v, var in ipairs(vars) do
                    if var and self[var] then
                        if Net.is_connected then
                            if hasVarChanged(var) then
                                update_values[var] = self[var]
                            end
                        end
                    end
                end
                -- update all
                if #vars == 0 then
                    for v, var in ipairs(self.net_sync_vars) do
                        if hasVarChanged(var) then 
                            update_values[var] = self[var]
                        end
                    end
                end
                -- send collected vars
                if Net.is_connected and table.len(update_values) > 0 then
                    Net.send{
                        type="netevent",
                        event="object.update",
                        info={
                            net_uuid=self.net_uuid,
                            values=update_values
                        }
                    }
                end
            end
        end

        obj:netSync()

        return Net
    end,

    sendSyncObjects = function()
        for o, obj in ipairs(Net._local_objects) do
            Net.send({
                type='netevent',
                event='object.add',
                info={
                    object = {net_uuid=obj.net_uuid, classname=obj.classname, values=obj.net_var_old}
                }
            })
            obj:netSync()
        end
    end,

    updateObjects = function()
        for o, obj in ipairs(Net._local_objects) do
            obj:netSync()
        end
    end,

    draw = function(classname)
        for clientid, objects in pairs(Net._objects) do
            for o, obj in pairs(objects) do
                if classname then
                    if obj.classname == classname then
                        obj:draw()
                    end
                else
                    obj:draw()
                end
            end
        end
        return Net
    end
}

return Net