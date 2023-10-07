local UPGRADE = {}
UPGRADE.id = "heavy_bat"
UPGRADE.class = "weapon_ttt_homebat"
UPGRADE.name = "Heavy Bat"
UPGRADE.desc = "x2 damage, increases gravity for the victim"
UPGRADE.damageMult = 2
local zoeyModel = "models/luria/night_in_the_woods/playermodels/mae.mdl"
local modelInstalled = util.IsValidModel(zoeyModel)

if modelInstalled then
    UPGRADE.desc = UPGRADE.desc .. "\nTurns you into a cat!"
    UPGRADE.name = "Cat Bat"
end

function UPGRADE:Apply(SWEP)
    if modelInstalled then
        local owner = SWEP:GetOwner()
        self:SetModel(owner, zoeyModel)
        owner:SetViewOffset(Vector(0, 0, 40))
        owner:SetViewOffsetDucked(Vector(0, 0, 28))
    end

    self:AddHook("EntityTakeDamage", function(ply, dmg)
        if not self:IsPlayer(ply) then return end
        local inflictor = dmg:GetInflictor()
        if not IsValid(inflictor) or WEPS.GetClass(inflictor) ~= self.class then return end

        if inflictor.PAPUpgrade and inflictor.PAPUpgrade.id == "heavy_bat" then
            local owner = inflictor:GetOwner()

            if IsValid(owner) then
                owner:EmitSound("ttt_pack_a_punch/heavy_bat/hit.mp3")
                owner:EmitSound("ttt_pack_a_punch/heavy_bat/hit.mp3")
            end

            -- Doubles gravity for them after a second so they still fly off
            timer.Simple(0.75, function()
                if IsValid(ply) then
                    ply.PAPOldGravity = ply:GetGravity()
                    ply:SetGravity(3)
                end
            end)
        end
    end)

    self:AddHook("OnPlayerHitGround", function(ply)
        if ply.PAPOldGravity then
            ply:SetGravity(ply.PAPOldGravity)
            ply.PAPOldGravity = nil
        end
    end)

    self:AddHook("PostPlayerDeath", function(ply)
        if ply.PAPOldGravity then
            ply:SetGravity(ply.PAPOldGravity)
            ply.PAPOldGravity = nil
        end
    end)
end

function UPGRADE:Reset()
    for _, ply in ipairs(player.GetAll()) do
        if ply.PAPOldGravity then
            ply:SetGravity(1)
            ply.PAPOldGravity = nil
        end
    end
end

TTTPAP:Register(UPGRADE)