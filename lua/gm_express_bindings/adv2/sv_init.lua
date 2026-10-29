return function( Module )
    local IsValid = IsValid

    -- KP: te same zabezpieczenia co zwykła ścieżka AdvDupe2 (net.Stream): limit rozmiaru i "zajęty".
    -- Znacznik czasu zamiast flagi: nieudane pobranie z API (brak callbacku błędu) nie blokuje gracza na stałe.
    local BUSY_TIMEOUT = 60
    local function maxSize() return AdvDupe2.MaxDupeSize end

    function Module.Enable()
        Module.ogSendToClient = Module.ogSendToClient or AdvDupe2.SendToClient
        function AdvDupe2.SendToClient( ply, data, autoSave )
            if net.Stream.SendSize > #data then
                Module.ogSendToClient( ply, data, autoSave )
                return
            end

            if not IsValid( ply ) then return end
            if #data > AdvDupe2.MaxDupeSize then
                AdvDupe2.Notify( ply, "Copied duplicator filesize is too big!", NOTIFY_ERROR )
                return
            end

            ply.AdvDupe2.Downloading = true
            AdvDupe2.InitProgressBar( ply, "Saving:" )

            local sendData = {
                autoSave = autoSave and true or false,
                data = data
            }

            express.Send( "AdvDupe2.ReceiveFile", sendData, ply, function( cbPly )
                if IsValid( cbPly ) and cbPly.AdvDupe2 then cbPly.AdvDupe2.Downloading = false end
            end )
        end

        -- przed pobraniem z API: odrzuć za duże pliki i wysyłkę, gdy poprzednia jeszcze trwa
        express.ReceivePreDl( "AdvDupe2.SendFile", function( _, ply, _, size )
            if not IsValid( ply ) then return false end
            if not ply.AdvDupe2 then ply.AdvDupe2 = {} end
            local since = ply.AdvDupe2.kpExpressUpload
            if ply.AdvDupe2.Uploading or ( since and CurTime() - since < BUSY_TIMEOUT ) then
                AdvDupe2.Notify( ply, "Duplicator is Busy!", NOTIFY_ERROR, 5 )
                return false
            end
            if size and size > maxSize() then
                AdvDupe2.Notify( ply, "Duplicator file is too big!", NOTIFY_ERROR, 5 )
                return false
            end
            ply.AdvDupe2.kpExpressUpload = CurTime()
            AdvDupe2.InitProgressBar( ply, "Uploading: " )
        end )

        express.Receive( "AdvDupe2.SendFile", function( ply, data )
            if not IsValid( ply ) then return end
            if not ply.AdvDupe2 then ply.AdvDupe2 = {} end
            ply.AdvDupe2.kpExpressUpload = nil

            if not istable( data ) or not isstring( data.data ) or #data.data > maxSize() then
                AdvDupe2.Notify( ply, "Duplicator Upload Failed!", NOTIFY_ERROR, 5 )
                AdvDupe2.RemoveProgressBar( ply )
                return
            end

            ply.AdvDupe2.Name = string.match( tostring( data.name or "" ), "([%w_ ]+)" ) or "Advanced Duplication"
            AdvDupe2.LoadDupe( ply, AdvDupe2.Decode( data.data ) )
        end )
    end

    function Module.Disable()
        AdvDupe2.SendToClient = Module.ogSendToClient
        express.ClearReceiver( "AdvDupe2.SendFile" )
        express._preDlReceivers["advdupe2.sendfile"] = nil
    end
end
