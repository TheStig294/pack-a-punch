local UPGRADE = {}
UPGRADE.id = "bat_fangs"
UPGRADE.class = "weapon_vam_fangs"
UPGRADE.name = "Bat Fangs"
UPGRADE.desc = "Temporarily become invincible and able to fly!\n(Right-click and hold Space)"

UPGRADE.convars = {
    {
        name = "pap_bat_fangs_move_speed",
        type = "int"
    },
    {
        name = "pap_bat_fangs_side_move_speed_cap",
        type = "int"
    },
    {
        name = "pap_bat_fangs_move_velocity",
        type = "int"
    },
    {
        name = "pap_bat_fangs_air_resistance",
        type = "float",
        decimals = 1
    }
}

local moveSpeedCvar = CreateConVar("pap_bat_fangs_move_speed", 224, {FCVAR_NOTIFY, FCVAR_REPLICATED}, "Move speed", 0, 1000)

local sideMoveSpeedCapCvar = CreateConVar("pap_bat_fangs_side_move_speed_cap", 1200, {FCVAR_NOTIFY, FCVAR_REPLICATED}, "Side move speed cap", 0, 2000)

local moveVelocityCvar = CreateConVar("pap_bat_fangs_move_velocity", 1200, {FCVAR_NOTIFY, FCVAR_REPLICATED}, "Move velocity", 0, 2000)

local airResistanceCvar = CreateConVar("pap_bat_fangs_air_resistance", 2.5, {FCVAR_NOTIFY, FCVAR_REPLICATED}, "Air resistance", 0, 10)

local batModel = "models/weapons/gamefreak/w_nessbat.mdl"
local batPlayermodel = "models/TSBB/Animals/Bat.mdl"
local bats = {}
local batInstalled = util.IsValidModel(batModel)
local batPlayerModelInstalled = util.IsValidModel(batPlayermodel)
local ForceSetPlayermodel = FindMetaTable("Entity").SetModel

-- Changes a player into a bat, baseball bat, or a smoke cloud, depending on what models are installed
local function ActivateBatMode(owner)
    if not IsValid(owner) then return end
    bats[owner] = {}

    if SERVER then
        owner:GodEnable()
        owner:SetNWBool("TTTPAPVampireFangsBatModeActive", true)
    end

    if batPlayerModelInstalled then
        bats[owner].playermodel = owner:GetModel()
        ForceSetPlayermodel(owner, batPlayermodel)

        if SERVER then
            owner:DrawWorldModel(false)
        end

        timer.Simple(0, function()
            owner:SetMaterial("")
        end)
    else
        owner:SetNoDraw(true)

        if SERVER and batInstalled then
            local bat = ents.Create("prop_dynamic")
            bat:SetModel(batModel)
            local pos = owner:GetPos()
            pos.z = pos.z + 20
            bat:SetPos(pos)
            bat:SetAngles(Angle(90, 0, 0))
            bat:SetParent(owner)
            bat:Spawn()
            bat:PhysWake()
            bats[owner].bat = bat
        end
    end
end

local function DeactivateBatMode(owner)
    if not IsValid(owner) then return end

    if SERVER then
        owner:GodDisable()
        owner:SetNWBool("TTTPAPVampireFangsBatModeActive", false)
    end

    if batPlayerModelInstalled then
        ForceSetPlayermodel(owner, bats[owner].playermodel)

        if SERVER then
            owner:DrawWorldModel(true)
        end
    else
        owner:SetNoDraw(false)

        if SERVER and batInstalled then
            local bat = bats[owner].bat

            if IsValid(bat) then
                bat:Remove()
            end
        end
    end

    bats[owner] = nil
end

function UPGRADE:Apply(SWEP)
    function SWEP:SecondaryAttack()
        if self:Clip1() == 100 then
            self:SetClip1(0)
            ActivateBatMode(self:GetOwner())
        end
    end

    -- Called on normal vampire invisibility deactivating
    self:AddHook("TTTVampireInvisibilityChange", function(owner, isActive)
        if isActive or not owner:GetNWBool("TTTPAPVampireFangsBatModeActive") then return end
        owner:SetNWBool("TTTPAPVampireFangsDisableBatMode", true)
    end)

    self:AddHook("TTTShouldPlayerSmoke", function(ply, _, shouldSmoke, smokeColor, smokeParticle, smokeOffset)
        if ply:GetNWBool("TTTPAPVampireFangsBatModeActive") then
            shouldSmoke = true
            smokeOffset = Vector(0, 0, 0)
        end

        return shouldSmoke, smokeColor, smokeParticle, smokeOffset
    end)

    local moveSpeedCap = moveSpeedCvar:GetInt()
    local sideMoveSpeedCap = sideMoveSpeedCapCvar:GetInt()
    local moveVelocity = moveVelocityCvar:GetInt()
    local airResistance = airResistanceCvar:GetFloat()

    self:AddHook("SetupMove", function(ply, moveData, _)
        if not ply:GetNWBool("TTTPAPVampireFangsBatModeActive") then return end

        -- Detecting if bat mode should be disabled and the player prevented from flying
        if ply:GetNWBool("TTTPAPVampireFangsDisableBatMode") or not ply:Alive() or ply:IsSpec() or not ply:HasWeapon("weapon_vam_fangs") or not ply:GetWeapon("weapon_vam_fangs").PAPUpgrade then
            DeactivateBatMode(ply)
            ply:SetNWBool("TTTPAPVampireFangsDisableBatMode", false)
        end

        -- SetupMove code from TTT Jetpack mod: https://steamcommunity.com/sharedfiles/filedetails/?id=1735229517
        local vel = moveData:GetVelocity()

        -- Up movement speed
        if moveData:KeyDown(IN_JUMP) and vel.z < moveSpeedCap then
            vel.z = vel.z + moveVelocity * FrameTime()
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
end

function UPGRADE:Reset()
    for _, ply in ipairs(player.GetAll()) do
        if ply:GetNWBool("TTTPAPVampireFangsBatModeActive") then
            DeactivateBatMode(ply)
        end
    end
end

TTTPAP:Register(UPGRADE)