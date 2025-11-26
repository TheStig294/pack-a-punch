local UPGRADE = {}
UPGRADE.id = "die_die_die"
UPGRADE.class = "c_reaper_nope"
UPGRADE.name = "Die! Die! Die!"
UPGRADE.desc = "Next time you shoot, you shoot everyone around you!"

function UPGRADE:Apply(SWEP)
    local reaperModel = "models/player/tfa_ow_reaper.mdl"
    local reaperModelInstalled = util.IsValidModel("models/player/tfa_ow_reaper.mdl")

    self:AddToHook(SWEP, "PrimaryAttack", function()
        if SWEP.TTTPAPDieDieDieActivated then return end
        SWEP.TTTPAPDieDieDieActivated = true
        local owner = SWEP:GetOwner()
        if not IsValid(owner) then return end
        SWEP.TTTPAPDieDieDieActive = true
        owner:SetNW2Bool("TTTPAPDieDieDieActive", true)
        owner:EmitSound("ttt_pack_a_punch/die_die_die/activate.mp3")

        if reaperModelInstalled then
            owner.TTTPAPDieDieDieOldModel = owner:GetModel()
            self:SetModel(owner, reaperModel)
        end

        timer.Create("TTTPAPDieDieDieActive", 0.25, 12, function()
            if not IsValid(SWEP) then return end
            SWEP:PrimaryAttack()
        end)

        timer.Simple(3, function()
            if IsValid(SWEP) then
                SWEP.TTTPAPDieDieDieActive = false
            end

            if IsValid(owner) then
                owner:SetNW2Bool("TTTPAPDieDieDieActive", false)

                if owner.TTTPAPDieDieDieOldModel then
                    self:SetModel(owner, owner.TTTPAPDieDieDieOldModel)
                end

                -- Deal an extra secret 75 damage in a radius to help how inaccrate this ability normally is...
                if SERVER then
                    local dmg = DamageInfo()
                    dmg:SetDamage(75)
                    dmg:SetDamageType(DMG_BULLET)
                    dmg:SetAttacker(owner)
                    dmg:SetInflictor(IsValid(SWEP) and SWEP or owner)

                    for _, ent in ipairs(ents.FindInSphere(owner:GetPos(), 400)) do
                        if IsValid(ent) and ent ~= owner then
                            ent:TakeDamageInfo(dmg)
                        end
                    end
                end
            end
        end)
    end)

    self:AddToHook(SWEP, "Think", function()
        if not SWEP.TTTPAPDieDieDieActive then return end
        local owner = SWEP:GetOwner()
        if not IsValid(owner) then return end
        SWEP:SetClip1(SWEP.Primary.ClipSize)
        owner:SetEyeAngles(owner:EyeAngles() + Angle(0, 10, 0))
    end)

    self:AddHook("CalcView", function(ply, pos, angles, fov, znear, zfar)
        if not ply:GetNW2Bool("TTTPAPDieDieDieActive") then return end

        local view = {
            origin = util.TraceLine({
                start = pos,
                endpos = pos - angles:Forward() * 100,
                filter = ply
            }).HitPos,
            angles = angles,
            fov = fov,
            drawviewer = true,
            znear = znear,
            zfar = zfar
        }

        return view
    end)
end

function UPGRADE:Reset()
    for _, ply in player.Iterator() do
        ply:SetNW2Bool("TTTPAPDieDieDieActive", nil)
    end
end

TTTPAP:Register(UPGRADE)