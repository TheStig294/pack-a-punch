local UPGRADE = {}
UPGRADE.id = "beepulon"
UPGRADE.class = "weapon_controllable_manhack"
UPGRADE.name = "Beepulon"
UPGRADE.desc = "Deals way more damage, makes beepulon sounds"

function UPGRADE:Apply(SWEP)
    local owner = SWEP:GetOwner()
    owner.TTTPAPBeepulonOwner = true

    if not ControllableManhack.PAPOldSpawnManhack then
        ControllableManhack.PAPOldSpawnManhack = ControllableManhack.SpawnManhack

        function ControllableManhack.SpawnManhack(ply, position, angle)
            local manhack = ents.Create(ControllableManhack.manhackEntityClassName)
            manhack:SetPos(position)
            manhack:SetAngles(angle)
            manhack:SetPlayerController(ply)
            manhack:Spawn()
            manhack.TTTPAPBeepulon = true

            if ply.TTTPAPBeepulonOwner then
                manhack:SetPAPCamo()
                local timername = "TTTPAPBeepulonSound" .. ply:SteamID64()

                timer.Create(timername, 20, 0, function()
                    if IsValid(manhack) then
                        local randomNum = math.random(4)
                        manhack:EmitSound("ttt_pack_a_punch/beepulon/beepulon" .. randomNum .. ".mp3")
                        manhack:EmitSound("ttt_pack_a_punch/beepulon/beepulon" .. randomNum .. ".mp3")
                    else
                        timer.Remove(timername)
                    end
                end)
            end

            return manhack
        end
    end

    local beepulonDeathCooldown = false

    self:AddHook("EntityTakeDamage", function(ent, dmg)
        if ent.TTTPAPBeepulon and not beepulonDeathCooldown then
            ent:EmitSound("ttt_pack_a_punch/beepulon/beepulondeath.mp3")
            ent:EmitSound("ttt_pack_a_punch/beepulon/beepulondeath.mp3")
            beepulonDeathCooldown = true

            timer.Simple(3, function()
                beepulonDeathCooldown = false
            end)

            return
        end

        local inflictor = dmg:GetInflictor()
        if not IsValid(inflictor) then return end

        if inflictor.TTTPAPBeepulon then
            dmg:ScaleDamage(10)
        end
    end)
end

function UPGRADE:Reset()
    for _, ply in ipairs(player.GetAll()) do
        ply.TTTPAPBeepulonOwner = nil
    end
end

TTTPAP:Register(UPGRADE)