return function( Module )
    function Module.Enable()
        express.Receive( "AdvDupe2.ReceiveFile", function( data )
            -- KP: serwer wysyła true/false (wcześniej sprawdzane "== 1", więc autozapis nigdy nie działał)
            local autoSave = data.autoSave == true or data.autoSave == 1
            AdvDupe2.ReceiveFile( data.data, autoSave )
        end )

        Module.originalSendFile = Module.originalSendFile or AdvDupe2.SendFile
        AdvDupe2.SendFile = function( name, data )
            if net.Stream.SendSize > #data then
                Module.originalSendFile( name, data )
                return
            end

            -- jak w net.Stream: obiekt z Remove() (UploadFile woła go przy "wymuś ponownie")
            AdvDupe2.Uploading = { Remove = function() end }
            express.Send( "AdvDupe2.SendFile", { name = name, data = data }, function()
                AdvDupe2.File = nil
                if AdvDupe2.ClearFileUpload then
                    AdvDupe2.ClearFileUpload()
                else
                    AdvDupe2.Uploading = nil
                    AdvDupe2.RemoveProgressBar()
                end
            end )
        end
    end

    function Module.Disable()
        AdvDupe2.SendFile = Module.originalSendFile
        express.ClearReceiver( "AdvDupe2.ReceiveFile" )
    end
end
