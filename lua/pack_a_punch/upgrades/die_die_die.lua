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
        owner.TTTPAPDieDieDieCamAngle = owner:EyeAngles().y
        owner.TTTPAPDieDieDieCamAngleOrig = owner:EyeAngles().y

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
                self:SetThirdPerson(owner, false)

                if owner.TTTPAPDieDieDieOldModel then
                    self:SetModel(owner, owner.TTTPAPDieDieDieOldModel)
                end
            end
        end)
    end)

    local moveMult = 10

    self:AddToHook(SWEP, "Think", function()
        if not SWEP.TTTPAPDieDieDieActive then return end
        local owner = SWEP:GetOwner()
        if not IsValid(owner) then return end
        SWEP:SetClip1(SWEP.Primary.ClipSize)
        owner.TTTPAPDieDieDieCamAngle = owner.TTTPAPDieDieDieCamAngle + moveMult
        local eyeAngles = owner:EyeAngles()
        owner:SetEyeAngles(Angle(eyeAngles.x, owner.TTTPAPDieDieDieCamAngle, eyeAngles.z))
    end)

    self:AddHook("CalcView", function(ply, pos, angles, fov, znear, zfar)
        if not ply:GetNWBool("TTTPAPDieDieDieActive") then return end

        local view = {
            origin = pos - (angles:Forward() * 100),
            angles = owner.TTTPAPDieDieDieCamAngleOrig,
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
-- TTTPAP:Register(UPGRADE)