--!strict
local Cache=require(script.Parent.AudioLoadCache)
local contentProvider=game:GetService('ContentProvider')
return Cache.new(function(id,done)
    task.spawn(function()
        -- Supplying the Sound gives ContentProvider the asset type. Bare audio
        -- ID strings can report Failure even when the corresponding Sound loads.
        local holder=Instance.new('Sound')
        holder.Name='FarmAudioPreload';holder.Volume=0;holder.SoundId=id
        local cleanup=task.delay(12,function() holder:Destroy() end)
        local success=false
        local ok=pcall(function()
            contentProvider:PreloadAsync({holder},function(_,status)
                success=status==Enum.AssetFetchStatus.Success
            end)
        end)
        pcall(task.cancel,cleanup)
        holder:Destroy()
        done(ok and success)
    end)
end,function(seconds,callback) task.delay(seconds,callback) end)
