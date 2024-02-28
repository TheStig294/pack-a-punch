local UPGRADE = {}
UPGRADE.id = "shrink_ray"
UPGRADE.class = "weapon_ttt_minifier"
UPGRADE.name = "Shrink Ray"
UPGRADE.desc = "Stand next to something and left-click to shrink it!"

UPGRADE.convars = {
    {
        name = "pap_shrink_ray_scale",
        type = "float",
        decimal = 2
    }
}

local scaleCvar = CreateConVar("pap_shrink_ray_scale", "0.5", {FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_REPLICATED}, "Shrinking scale multiplier", 0.1, 1)

function UPGRADE:Apply(SWEP)
    SWEP.ShrinkScale = scaleCvar:GetFloat()
    SWEP:SendWeaponAnim(ACT_SLAM_DETONATOR_THROW_DRAW)

    function SWEP:Deploy()
        self:SendWeaponAnim(ACT_SLAM_DETONATOR_THROW_DRAW)

        return true
    end

    function SWEP:PrimaryAttack()
        self:SetNextPrimaryFire(CurTime() + self.Primary.Delay)
        local owner = self:GetOwner()
        if not IsValid(owner) then return end
        local TraceResult = owner:GetEyeTrace()
        local hitPos = TraceResult.HitPos
        local ent = TraceResult.Entity

        if not IsValid(ent) or not isnumber(ent:GetModelScale()) then
            if CLIENT then
                owner:PrintMessage(HUD_PRINTTALK, "Invalid object")
            end

            return
        elseif owner:GetPos():DistToSqr(hitPos) > 10000 then
            -- If the distance from the left-clicked entity is greater than 100 source units, don't allow the player to shrink it
            if CLIENT then
                owner:PrintMessage(HUD_PRINTTALK, "Object too far away")
            end

            return
        end

        if ent.PAPMinified then
            self:UnMinify(ent)
        else
            self:Minify(ent)
        end
    end

    function SWEP:Minify(ent)
        if CLIENT then return end
        self.ShrinkScale = scaleCvar:GetFloat()
        ent:EmitSound("ttt_pack_a_punch/microfier/shrink.ogg")
        ent:SetModelScale(ent:GetModelScale() * self.ShrinkScale, 1)
        ent:SetHealth(ent:Health() * self.ShrinkScale)
        ent:SetMaxHealth(ent:GetMaxHealth() * self.ShrinkScale)

        if ent:IsPlayer() then
            ent:SetStepSize(ent:GetStepSize() * self.ShrinkScale)

            -- Smoothly lowers a player's view when shrunk
            if not ent.PAPOGMinifierHeight then
                ent.PAPOGMinifierHeight = {ent:GetViewOffset().z, ent:GetViewOffsetDucked().z}
            end

            local ID = "TTTMinifierShrink" .. ent:EntIndex()

            timer.Create(ID, 0.01, 100, function()
                local counter = 100 - timer.RepsLeft(ID)

                if counter < 100 - self.ShrinkScale * 100 then
                    ent:SetViewOffset(Vector(0, 0, ent.PAPOGMinifierHeight[1] - counter * ent.PAPOGMinifierHeight[1] / 100))
                    ent:SetViewOffsetDucked(Vector(0, 0, ent.PAPOGMinifierHeight[2] - counter * ent.PAPOGMinifierHeight[2] / 100))
                end
            end)
        else
            -- Update the entity's physbox if it's not a player so it is not left floating in the air
            -- Apparently calling ent:Activate() on scaled vehicles can crash the server so lets not do that...
            timer.Simple(1, function()
                if IsValid(ent) and not ent:IsVehicle() then
                    ent:Activate()
                end
            end)
        end

        ent.PAPMinified = true
    end

    function SWEP:UnMinify(ent)
        if CLIENT then return end
        ent:EmitSound("ttt_pack_a_punch/microfier/unshrink.ogg")
        ent:SetModelScale(ent:GetModelScale() / self.ShrinkScale, 1)
        ent:SetHealth(ent:Health() / ent:GetMaxHealth() * ent:GetMaxHealth() / self.ShrinkScale)
        ent:SetMaxHealth(ent:GetMaxHealth() / self.ShrinkScale)

        if ent:IsPlayer() then
            ent:SetStepSize(ent:GetStepSize() / self.ShrinkScale)

            -- Smoothly raises a player's view when unshrunk
            if ent.PAPOGMinifierHeight then
                local ID = "TTTMinifierUnshrink" .. ent:SteamID64()

                timer.Create(ID, 0.01, 100, function()
                    local counter = 100 - timer.RepsLeft(ID)

                    if counter < 100 - self.ShrinkScale * 100 then
                        ent:SetViewOffset(Vector(0, 0, ent.PAPOGMinifierHeight[1] / (1 / self.ShrinkScale) + counter * ent.PAPOGMinifierHeight[1] / 100))
                        ent:SetViewOffsetDucked(Vector(0, 0, ent.PAPOGMinifierHeight[2] / (1 / self.ShrinkScale) + counter * ent.PAPOGMinifierHeight[2] / 100))
                    end
                end)
            end
        else
            -- Update the entity's physbox if it's not a player so it is not left floating in the air
            -- Apparently calling ent:Activate() on scaled vehicles can crash the server so lets not do that...
            timer.Simple(1, function()
                if IsValid(ent) and not ent:IsVehicle() then
                    ent:Activate()
                end
            end)
        end

        ent.PAPMinified = false
    end
end

function UPGRADE:Reset()
    if CLIENT then return end

    -- Just do a hard-coded reset because supporting the 1 million versions of the minifier is too hard
    for _, ply in pairs(player.GetAll()) do
        if ply.PAPMinified then
            ply:SetModelScale(1, 0.001)

            if ply.PAPOGMinifierHeight then
                ply:SetViewOffset(Vector(0, 0, ply.PAPOGMinifierHeight[1]))
                ply:SetViewOffsetDucked(Vector(0, 0, ply.PAPOGMinifierHeight[2]))
            end

            ply:SetStepSize(18)
            ply:SetHealth(100)
            ply:SetMaxHealth(100)
        end

        ply.PAPMinified = nil
        ply.PAPOGMinifierHeight = nil
    end
end

TTTPAP:Register(UPGRADE)