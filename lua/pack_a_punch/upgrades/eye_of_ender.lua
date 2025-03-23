local UPGRADE = {}
UPGRADE.id = "eye_of_ender"
UPGRADE.class = "weapon_enderpearl"
UPGRADE.name = "Eye Of Ender"
UPGRADE.desc = "Teleport through thin walls,\nInfinite uses, turns you into an enderman!"

UPGRADE.convars = {
    {
        name = "pap_eye_of_ender_cooldown",
        type = "int"
    }
}

local cooldownCvar = CreateConVar("pap_eye_of_ender_cooldown", "5", {FCVAR_NOTIFY, FCVAR_REPLICATED}, "Seconds cooldown for teleporting", 0, 30)

function UPGRADE:Apply(SWEP)
    local endermanModel = "models/player/lingry/minecraft/enderman.mdl"
    local endermanModelInstalled = util.IsValidModel(endermanModel)

    local function SetPlayerAsEnderman(ply)
        if not IsValid(ply) then return end
        ply.TTTPAPEyeOfEnder = true
        local currentModel = ply:GetModel()

        if endermanModelInstalled then
            if currentModel ~= endermanModel then
                ply.TTTPAPEyeOfEnderOGModel = currentModel
            end

            self:SetModel(ply, endermanModel)
        end
    end

    local function UnsetPlayerAsEnderman(ply)
        if not IsValid(ply) then return end
        ply.TTTPAPEyeOfEnder = nil

        if ply.TTTPAPEyeOfEnderOGModel then
            self:SetModel(ply, ply.TTTPAPEyeOfEnderOGModel)
        end
    end

    local function CreateEnderParticles(pos)
        local effect = EffectData()
        effect:SetOrigin(pos)
        util.Effect("pearl_particle", effect)
    end

    timer.Simple(0, function()
        SWEP.Primary.ClipSize = cooldownCvar:GetInt()

        -- Setting the ammo count to -1 hides the ammo counter, no need for it if there's no cooldown on teleporting
        if SWEP.Primary.ClipSize < 1 then
            SWEP.Primary.ClipSize = -1
        end

        SWEP:SetClip1(SWEP.Primary.ClipSize)
        -- If the enderman model is installed, set the owner to it!
        local owner = SWEP:GetOwner()
        SetPlayerAsEnderman(owner)
        SWEP.PAPOwner = owner
    end)

    function SWEP:PrimaryAttack()
        -- Error sound if you try teleporting on cooldown
        if self.Primary.ClipSize > 0 and self:Clip1() < self:GetMaxClip1() then
            self:EmitSound("ttt_pack_a_punch/eye_of_ender/idle1.mp3")

            return
        end

        local owner = self:GetOwner()
        local originalPos = owner:GetPos()
        local hitPos = owner:GetEyeTrace().HitPos
        owner:SetPos(hitPos)
        UPGRADE:UnstuckPlayer(owner)
        owner:EmitSound("portal" .. math.random(1, 2) .. ".wav")

        -- Create a trail of teleport particles from the player to their original position
        for i = 1, 20 do
            local pos = LerpVector(i / 20, originalPos, hitPos)
            CreateEnderParticles(pos)
        end

        -- If the cooldown is set to 0 then don't worry about changing the ammo count
        if SWEP.Primary.ClipSize > 0 then
            self:SetClip1(0)
            local timerName = "TTTPAPEyeOfEnderCooldown" .. self:EntIndex()

            timer.Create(timerName, 1, self:GetMaxClip1(), function()
                if not IsValid(self) then
                    timer.Remove(timerName)

                    return
                end

                self:SetClip1(self:Clip1() + 1)
            end)
        end
    end

    function SWEP:SecondaryAttack()
        self:PrimaryAttack()
    end

    -- If the weapon changes hands, set the new owner as an enderman, and reset the old owner
    function SWEP:Equip()
        local owner = self:GetOwner()
        if not IsValid(owner) then return end
        self.PAPOwner = owner
        SetPlayerAsEnderman(owner)
    end

    function SWEP:OnRemove()
        UnsetPlayerAsEnderman(self.PAPOwner)
    end

    -- Add a timer here so the death sound can play properly
    function SWEP:PreDrop()
        local owner = self.PAPOwner

        timer.Simple(0.1, function()
            UnsetPlayerAsEnderman(owner)
        end)
    end

    -- Adds particle effects and idle sounds for any enderman player that play randomly
    if SERVER then
        timer.Create("TTTPAPEyeOfEnderIdleEffects", 3, 0, function()
            for _, ply in player.Iterator() do
                if ply.TTTPAPEyeOfEnder and math.random() < 0.5 then
                    CreateEnderParticles(ply:GetPos())
                end
            end
        end)

        timer.Create("TTTPAPEyeOfEnderIdleSounds", 5, 0, function()
            for _, ply in player.Iterator() do
                if ply.TTTPAPEyeOfEnder and math.random() < 0.5 then
                    -- Idle sound 1 is being used as the cooldown error sound in SWEP:PrimaryAttack(), so don't pick that one
                    ply:EmitSound("ttt_pack_a_punch/eye_of_ender/idle" .. math.random(2, 5) .. ".mp3")
                end
            end
        end)

        -- Players take damage while in water
        timer.Create("TTTPAPEyeOfEnderWaterDamage", 1, 0, function()
            for _, ply in player.Iterator() do
                if ply.TTTPAPEyeOfEnder and ply:WaterLevel() ~= 0 then
                    local dmg = DamageInfo()
                    dmg:SetDamageType(DMG_DROWN)
                    dmg:SetDamage(10)
                    dmg:SetAttacker(ply)
                    dmg:SetInflictor(ply:GetWeapon(self.class) or ply)
                    ply:TakeDamageInfo(dmg)
                end
            end
        end)
    end

    -- Players makes enderman sounds on hurt and death
    self:AddHook("PlayerHurt", function(ply)
        if ply.TTTPAPEyeOfEnder and self:IsAlive(ply) then
            ply:EmitSound("ttt_pack_a_punch/eye_of_ender/hurt" .. math.random(1, 4) .. ".mp3")
            local oldMat = ply:GetMaterial()

            if oldMat ~= "ttt_pack_a_punch/eye_of_ender/red" then
                ply.TTTPAPEyeOfEnderOldMaterial = oldMat
            end

            ply:SetMaterial("ttt_pack_a_punch/eye_of_ender/red")

            timer.Simple(0.5, function()
                ply:SetMaterial(ply.TTTPAPEyeOfEnderOldMaterial or "")
            end)
        end
    end)

    self:AddHook("PlayerDeathSound", function(ply)
        if ply.TTTPAPEyeOfEnder then
            ply:EmitSound("ttt_pack_a_punch/eye_of_ender/death.mp3")

            return true
        end
    end)
end

function UPGRADE:Reset()
    for _, ply in player.Iterator() do
        ply.TTTPAPEyeOfEnder = nil

        if ply.TTTPAPEyeOfEnderOGModel then
            self:SetModel(ply, ply.TTTPAPEyeOfEnderOGModel)
        end
    end

    if SERVER then
        timer.Remove("TTTPAPEyeOfEnderIdleEffects")
        timer.Remove("TTTPAPEyeOfEnderIdleSounds")
        timer.Remove("TTTPAPEyeOfEnderWaterDamage")
    end
end

TTTPAP:Register(UPGRADE)