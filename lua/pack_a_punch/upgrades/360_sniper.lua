local UPGRADE = {}
UPGRADE.id = "360_sniper"
UPGRADE.class = "ttt_combine_sniper_summoner"
UPGRADE.name = "360 Sniper"
UPGRADE.desc = "Spins around on the spot, watch out!"

function UPGRADE:Apply(SWEP)
    function SWEP:place_sniper(tracedata)
        if CLIENT then return end
        local ent = ents.Create("npc_sniper")

        for k, v in pairs(player.GetAll()) do
            v:ChatPrint("Look out for an upgraded combine sniper! They like to 360...")
        end

        if not IsValid(ent) then return end
        local spawnereasd = self:FindRespawnLocationCustom(tracedata.pos)

        if spawnereasd ~= false then
            local pitch, yaw, roll = self:GetOwner():EyeAngles():Unpack()
            pitch = 0
            ent:SetPos(spawnereasd)
            ent:SetAngles(Angle(pitch, yaw, roll))
            ent:Spawn()

            if util.IsValidModel("models/player/Jenssons/kermit.mdl") then
                ent:SetModel("models/player/Jenssons/kermit.mdl")
                local randomNum = math.random(2)
                ent:EmitSound("ttt_pack_a_punch/360_sniper/zylus" .. randomNum .. ".mp3", 0)
                ent:EmitSound("ttt_pack_a_punch/360_sniper/zylus" .. randomNum .. ".mp3", 0)
            else
                ent:SetMaterial(TTTPAP.camo)
            end

            timer.Create("CombineSniperRotate" .. ent:EntIndex(), 0.1, 0, function()
                if IsValid(ent) then
                    local angles = ent:GetAngles()
                    angles:Add(Angle(0, 5, 0))
                    ent:SetAngles(angles)
                else
                    -- Remove the timer as soon as the entity is no longer valid,
                    -- Such as at the end of the round when TTT removes all non-map entities
                    timer.Remove("CombineSniperRotate" .. ent:EntIndex())
                end
            end)

            if ConVarExists("ttt_combine_sniper_remove") and GetConVar("ttt_combine_sniper_remove"):GetBool() then
                -- If for whatever reason the remove time cannot be read, set the remove timer to 15 seconds
                local removeTime = GetConVar("ttt_combine_sniper_time"):GetInt() or 15

                timer.Create("CombineSniperRemove" .. ent:EntIndex(), removeTime, 1, function()
                    timer.Remove("CombineSniperRotate" .. ent:EntIndex())

                    if IsValid(ent) then
                        ent:Remove()
                    end
                end)
            end
        end

        local phys = ent:GetPhysicsObject()

        if not IsValid(phys) then
            ent:Remove()

            return
        end
    end
end

TTTPAP:Register(UPGRADE)