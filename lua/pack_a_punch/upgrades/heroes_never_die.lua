local UPGRADE = {}
UPGRADE.id = "heroes_never_die"
UPGRADE.class = "tfa_mercy_nope"
UPGRADE.name = "Heroes Never Die!"
UPGRADE.desc = "While held, grants flight and infinite ammo!"

UPGRADE.convars = {
    {
        name = "pap_heroes_never_die_duration",
        type = "int"
    }
}

local durationCvar = CreateConVar("pap_heroes_never_die_duration", "60", {FCVAR_NOTIFY, FCVAR_REPLICATED}, "Secs duration of flight & infinite ammo", 1, 180)

function UPGRADE:Apply(SWEP)
    local mercyModel = "models/player/tfa_ow_mercy.mdl"
    local mercyModelInstalled = util.IsValidModel(mercyModel)
    SWEP.TTTPAPHeroesNeverDieActive = true
    SWEP.TTTPAPOwner = SWEP:GetOwner()

    -- Sets model and flying move type, and plays ultimate voice line
    local function SetMercyMode(wep, active)
        if not IsValid(wep) then return end
        local owner = wep.TTTPAPOwner
        if not IsValid(owner) then return end
        active = active and wep.TTTPAPHeroesNeverDieActive
        owner.TTTPAPHeroesNeverDieModel = owner.TTTPAPHeroesNeverDieModel or owner:GetModel()
        local model = (active and mercyModel) or owner.TTTPAPHeroesNeverDieModel

        if mercyModelInstalled then
            self:SetModel(owner, model)
        end

        if active then
            owner:EmitSound("ttt_pack_a_punch/heroes_never_die/activate.mp3")
            owner.TTTPAPGeroesNeverDieGravity = owner:GetGravity()
            owner:SetGravity(0.1)
        else
            owner:SetGravity(owner.TTTPAPGeroesNeverDieGravity or 1)
        end
    end

    SetMercyMode(SWEP, true)

    -- Handling weapon being picked up or dropped
    function SWEP:OwnerChanged()
        SetMercyMode(self, false)
        self.TTTPAPOwner = self:GetOwner()
        SetMercyMode(self, true)
    end

    -- Main timer stopping flying, resetting model and removing flight timer on the HUD
    local timername = "TTTPAPHeroesNeverDie"
    SWEP.TTTPAPHeroesNeverDieTimeLeft = durationCvar:GetInt()

    timer.Create(timername, 1, durationCvar:GetInt(), function()
        local repsLeft = timer.RepsLeft(timername)

        if IsValid(SWEP) then
            SWEP.TTTPAPHeroesNeverDieTimeLeft = repsLeft
        end

        if repsLeft == 0 then
            if IsValid(SWEP) then
                SWEP.TTTPAPHeroesNeverDieActive = false
                SetMercyMode(SWEP, false)
            end

            self:RemoveHook("HUDPaint")
            self:RemoveHook("SetupMove")
        end
    end)

    local client

    if CLIENT then
        client = LocalPlayer()
    end

    -- HUD flight timer
    self:AddHook("HUDPaint", function()
        local wep = client:GetActiveWeapon()
        if not self:IsValidUpgrade(wep) then return end
        draw.WordBox(8, ScrW() / 2, ScrH() - 50, "Flight time left: " .. wep.TTTPAPHeroesNeverDieTimeLeft, "HealthAmmo", COLOR_YELLOW, COLOR_WHITE, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end)

    -- Infinite ammo
    self:AddToHook(SWEP, "Think", function()
        if not SWEP.TTTPAPHeroesNeverDieActive then return end
        SWEP:SetClip1(SWEP.Primary.ClipSize)
    end)

    -- Making it so pressing jump moves you up and pressing crouch moves you down
    self:AddHook("SetupMove", function(ply, mv)
        local wep = ply:GetActiveWeapon()

        if not self:IsValidUpgrade(wep) then
            if ply.TTTPAPGeroesNeverDieGravity then
                ply:SetGravity(ply.TTTPAPGeroesNeverDieGravity)
                ply.TTTPAPGeroesNeverDieGravity = nil
            end

            return
        elseif not ply.TTTPAPGeroesNeverDieGravity then
            ply.TTTPAPGeroesNeverDieGravity = ply:GetGravity()
            ply:SetGravity(0.1)
        end

        if mv:KeyDown(IN_JUMP) then
            ply:SetVelocity(Vector(0, 0, 500))
        end

        if mv:KeyDown(IN_DUCK) then
            ply:SetVelocity(Vector(0, 0, -500))
        end

        if mv:KeyDown(IN_FORWARD) then
            ply:SetVelocity(ply:GetForward() * 10)
        end

        if mv:KeyDown(IN_BACK) then
            ply:SetVelocity(ply:GetForward() * -10)
        end

        if mv:KeyDown(IN_MOVELEFT) then
            ply:SetVelocity(ply:GetRight() * -10)
        end

        if mv:KeyDown(IN_MOVERIGHT) then
            ply:SetVelocity(ply:GetRight() * 10)
        end
    end)
end

TTTPAP:Register(UPGRADE)