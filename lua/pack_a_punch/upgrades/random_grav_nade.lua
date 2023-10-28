local UPGRADE = {}
UPGRADE.id = "random_grav_nade"
UPGRADE.class = "weapon_ttt_gimnade"
UPGRADE.name = "Random Grav Nade"
UPGRADE.desc = "When the floating ends, changes the victim's gravity!"

function UPGRADE:Apply(SWEP)
    if CLIENT then return end
    SWEP:GetOwner().TTTPAPRandomGravNade = true

    self:AddHook("OnEntityCreated", function(ent)
        timer.Simple(0, function()
            if not IsValid(ent) then return end
            local owner = ent.Owner

            if ent:GetClass() == "ttt_gimnade_proj" and IsValid(owner) and owner.TTTPAPRandomGravNade then
                ent:SetMaterial(TTTPAP.camo)
            end
        end)
    end)

    local randomGravityValues = {-4, -2, -1, -0.5, 0.1, 0.4, 0.6, 0.9, 1.5, 2, 3, 4, 5, 6}

    local function RandomiseGravity(ply)
        local gravityValue = randomGravityValues[math.random(1, #randomGravityValues)]
        ply:SetGravity(gravityValue)
        ply:ChatPrint("Gravity multiplier: " .. gravityValue)
    end

    self:AddHook("EntityRemoved", function(ent)
        local owner = ent.Owner

        if ent:GetClass() == "ttt_gimnade_proj" and IsValid(owner) and owner.TTTPAPRandomGravNade then
            owner.TTTPAPRandomGravNade = nil

            for _, ply in ipairs(ents.FindInSphere(ent:GetPos(), 200)) do
                if self:IsAlivePlayer(ply) then
                    RandomiseGravity(ply)
                    ply:ChatPrint("An upgraded grav nade changed your gravity\nWatch out once the floating ends!")
                    local timername = "TTTPAPRandomGravNade" .. ply:SteamID64()

                    timer.Create(timername, 20, 0, function()
                        if IsValid(ply) then
                            if self:IsAlive(ply) then
                                RandomiseGravity(ply)
                            else
                                ply:SetGravity(1)
                                timer.Remove(timername)
                            end
                        else
                            timer.Remove(timername)
                        end
                    end)
                end
            end
        end
    end)
end

function UPGRADE:Reset()
    for _, ply in ipairs(player.GetAll()) do
        timer.Remove("TTTPAPRandomGravNade" .. ply:SteamID64())
    end
end

TTTPAP:Register(UPGRADE)