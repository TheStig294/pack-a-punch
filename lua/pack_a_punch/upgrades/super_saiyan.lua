local UPGRADE = {}
UPGRADE.id = "super_saiyan"
UPGRADE.class = "ttt_kamehameha_swep"
UPGRADE.name = "Super Saiyan"
UPGRADE.desc = "YOUR POWER LEVEL IS OVER 9000!\nRight-click to teleport, you can fly while held!"

UPGRADE.convars = {
    {
        name = "pap_super_saiyan_move_speed",
        type = "int"
    },
    {
        name = "pap_super_saiyan_side_move_speed_cap",
        type = "int"
    },
    {
        name = "pap_super_saiyan_move_velocity",
        type = "int"
    },
    {
        name = "pap_super_saiyan_air_resistance",
        type = "float",
        decimals = 1
    }
}

local moveSpeedCvar = CreateConVar("pap_super_saiyan_move_speed", 224, {FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_REPLICATED}, "Move speed", 0, 1000)

local sideMoveSpeedCapCvar = CreateConVar("pap_super_saiyan_side_move_speed_cap", 1200, {FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_REPLICATED}, "Side move speed cap", 0, 2000)

local moveVelocityCvar = CreateConVar("pap_super_saiyan_move_velocity", 1200, {FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_REPLICATED}, "Move velocity", 0, 2000)

local airResistanceCvar = CreateConVar("pap_super_saiyan_air_resistance", 2.5, {FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_REPLICATED}, "Air resistance", 0, 10)

function UPGRADE:Apply(SWEP)
    -- Applying model if installed, and only while the weapon is held
    local superSaiyanModel = "models/konnie/jumpforce/goku_outfit.mdl"
    local modelInstalled = util.IsValidModel(superSaiyanModel)

    local function ToggleSuperSaiyan(ply, toSuperSaiyan)
        if not IsValid(ply) then return end

        if toSuperSaiyan then
            if modelInstalled then
                if not ply.TTTPAPSuperSaiyanOldModel then
                    ply.TTTPAPSuperSaiyanOldModel = ply:GetModel()
                end

                self:SetModel(ply, superSaiyanModel)
                -- Set model hair to yellow
                ply:SetBodygroup(2, 1)
            end

            ply:EmitSound("ttt_pack_a_punch/super_saiyan/powerup.mp3")
            -- Looping passive "aura" sound while super saiyan
            ply:EmitSound("ttt_pack_a_punch/super_saiyan/aura.wav")
            -- Explosion effect
            local effect = EffectData()
            effect:SetStart(ply:GetPos())
            effect:SetOrigin(ply:GetPos())
            effect:SetScale(400)
            effect:SetRadius(400)
            effect:SetMagnitude(1000)
            util.Effect("Explosion", effect, true, true)
            ply.TTTPAPSuperSaiyan = true
        else
            if modelInstalled and ply.TTTPAPSuperSaiyanOldModel then
                self:SetModel(ply, ply.TTTPAPSuperSaiyanOldModel)
            end

            ply:StopSound("ttt_pack_a_punch/super_saiyan/aura.wav")
            ply.TTTPAPSuperSaiyan = false
        end
    end

    ToggleSuperSaiyan(SWEP:GetOwner(), true)
    SWEP:EmitSound("ttt_pack_a_punch/super_saiyan/its-over-9000.mp3")

    function SWEP:Deploy()
        self:SendWeaponAnim(ACT_VM_DRAW)
        ToggleSuperSaiyan(self:GetOwner(), true)

        return true
    end

    function SWEP:Holster()
        ToggleSuperSaiyan(self:GetOwner(), false)

        return true
    end

    function SWEP:PreDrop()
        ToggleSuperSaiyan(self:GetOwner(), false)
    end

    function SWEP:OnRemove()
        ToggleSuperSaiyan(self:GetOwner(), false)
    end

    -- Assuming most players won't be using the super saiyan than do, so more efficient to return cache when players aren't,
    -- and only check if a player should be a super saiyan when they are
    local function IsSuperSaiyan(ply)
        if ply.TTTPAPSuperSaiyan then
            local wep = ply:GetActiveWeapon()
            local isSuperSaiyan = IsValid(wep) and self:IsUpgraded(wep)

            if not isSuperSaiyan then
                ToggleSuperSaiyan(ply, false)
            end

            return isSuperSaiyan
        else
            return false
        end
    end

    -- Flying while the weapon is held!
    local moveSpeedCap = moveSpeedCvar:GetInt()
    local sideMoveSpeedCap = sideMoveSpeedCapCvar:GetInt()
    local moveVelocity = moveVelocityCvar:GetInt()
    local airResistance = airResistanceCvar:GetFloat()
    local flySound = Sound("ambient/atmosphere/sewer_air1.wav")

    self:AddHook("SetupMove", function(ply, moveData, _)
        if not IsSuperSaiyan(ply) then return end
        -- SetupMove code from TTT Jetpack mod: https://steamcommunity.com/sharedfiles/filedetails/?id=1735229517
        local vel = moveData:GetVelocity()

        -- Up movement speed
        if moveData:KeyDown(IN_JUMP) and vel.z < moveSpeedCap then
            vel.z = vel.z + moveVelocity * FrameTime()
        end

        if IsFirstTimePredicted() and SERVER then
            if moveData:KeyDown(IN_JUMP) and not ply.TTTPAPSuperSaiyanSound then
                ply:EmitSound(flySound)
                ply.TTTPAPSuperSaiyanSound = true

                timer.Simple(8, function()
                    if not IsValid(ply) then return end
                    ply:StopSound(flySound)
                end)
            elseif not moveData:KeyDown(IN_JUMP) then
                ply:StopSound(flySound)
                ply.TTTPAPSuperSaiyanSound = false
            end
        end

        local move_vel = Vector(0, 0, 0)
        local ang = moveData:GetMoveAngles()
        ang.p = 0
        move_vel:Add(ang:Right() * moveData:GetSideSpeed())
        move_vel:Add(ang:Forward() * moveData:GetForwardSpeed())
        move_vel:Normalize()
        move_vel:Mul(sideMoveSpeedCap * FrameTime())

        if vel:Length2D() < sideMoveSpeedCap then
            vel:Add(move_vel)
        end

        vel.x = math.Approach(vel.x, 0, FrameTime() * airResistance * vel.x)
        vel.y = math.Approach(vel.y, 0, FrameTime() * airResistance * vel.y)
        moveData:SetVelocity(vel)
        moveData:SetForwardSpeed(0)
        moveData:SetSideSpeed(0)
        moveData:SetUpSpeed(0)
    end)

    -- Super saiyan glowy-ness
    if CLIENT then
        self:AddHook("PreDrawHalos", function()
            local superSaiyans = {}

            for _, ply in player.Iterator() do
                if IsSuperSaiyan(ply) then
                    table.insert(superSaiyans, ply)
                end
            end

            halo.Add(superSaiyans, COLOR_YELLOW, 10, 10, 5, true, false)
        end)
    end

    -- Right-click teleport
    function SWEP:SecondaryAttack()
        if self.TTTPAPTeleportCooldown then return end
        local owner = self:GetOwner()
        if not IsValid(owner) then return end
        owner:SetPos(owner:GetEyeTrace().HitPos)
        UPGRADE:UnstuckPlayer(owner)
        owner:EmitSound("ttt_pack_a_punch/super_saiyan/teleport.mp3")
        self.TTTPAPTeleportCooldown = true

        timer.Simple(5, function()
            if IsValid(self) then
                self.TTTPAPTeleportCooldown = false
            end
        end)
    end
end

function UPGRADE:Reset()
    for _, ply in player.Iterator() do
        ply.TTTPAPSuperSaiyan = nil
        ply.TTTPAPSuperSaiyanOldModel = nil
        ply.TTTPAPSuperSaiyanSound = nil
    end
end

TTTPAP:Register(UPGRADE)