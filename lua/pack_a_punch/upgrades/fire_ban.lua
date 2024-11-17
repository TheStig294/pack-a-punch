local UPGRADE = {}
UPGRADE.id = "fire_ban"
UPGRADE.class = "weapon_ttt_extinguisher"
UPGRADE.name = "Fire Ban"
UPGRADE.desc = "Globally bans fires from starting,\nand extinguishes all fires while held!"

function UPGRADE:Apply(SWEP)
    if CLIENT then return end

    local function SendCooldownMessage(ply, message)
        if not IsPlayer(ply) or ply.TTTPAPFireBanMessage then return end
        ply:ChatPrint(message)
        ply.TTTPAPFireBanMessage = true

        timer.Simple(30, function()
            if IsValid(ply) then
                ply.TTTPAPFireBanMessage = nil
            end
        end)
    end

    self:AddToHook(SWEP, "Think", function()
        local fireCount = 0

        for _, ent in ents.Iterator() do
            if not IsValid(ent) then continue end

            if ent:IsOnFire() then
                ent:Extinguish()
                fireCount = fireCount + 1
                SendCooldownMessage(ent, "Your fire was put out by an upgraded fire extinguisher!")

                if ent:IsPlayer() then
                    SendCooldownMessage(SWEP:GetOwner(), "You put out " .. ent:Nick() .. "!")
                end
            end

            if ent:GetClass() == "ttt_flame" then
                ent:Remove()
                fireCount = fireCount + 1
            end
        end

        SendCooldownMessage(SWEP:GetOwner(), "You put out " .. fireCount .. " fires!")
    end)
end

TTTPAP:Register(UPGRADE)