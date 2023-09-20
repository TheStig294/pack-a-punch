local UPGRADE = {}
UPGRADE.id = "passive_levitator"
UPGRADE.class = "weapon_ttt_jetpack"
UPGRADE.name = "Passive Levitator"
UPGRADE.desc = "Way better controls, can shoot while flying!"

UPGRADE.convars = {
    {
        name = "pap_passive_levitator_move_speed",
        type = "int"
    },
    {
        name = "pap_passive_levitator_side_move_speed_cap",
        type = "int"
    },
    {
        name = "pap_passive_levitator_move_velocity",
        type = "int"
    },
    {
        name = "pap_passive_levitator_air_resistance",
        type = "float",
        decimals = 1
    }
}

local moveSpeedCvar = CreateConVar("pap_passive_levitator_move_speed", 224, {FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_REPLICATED}, "Move speed", 0, 1000)

local sideMoveSpeedCapCvar = CreateConVar("pap_passive_levitator_side_move_speed_cap", 1200, {FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_REPLICATED}, "Side move speed cap", 0, 2000)

local moveVelocityCvar = CreateConVar("pap_passive_levitator_move_velocity", 1200, {FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_REPLICATED}, "Move velocity", 0, 2000)

local airResistanceCvar = CreateConVar("pap_passive_levitator_air_resistance", 2.5, {FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_REPLICATED}, "Air resistance", 0, 10)

function UPGRADE:Apply(SWEP)
    local moveSpeedCap = moveSpeedCvar:GetInt()
    local sideMoveSpeedCap = sideMoveSpeedCapCvar:GetInt()
    local moveVelocity = moveVelocityCvar:GetInt()
    local airResistance = airResistanceCvar:GetFloat()
    local flySound = Sound("ambient/atmosphere/sewer_air1.wav")

    -- local flySound = Sound("plats/elevator_large_start1.wav")
    self:AddHook("SetupMove", function(ply, moveData, _)
        local wep = ply:GetWeapon(self.class)
        if not IsValid(wep) or not wep.PAPUpgrade then return end
        -- SetupMove code from TTT Jetpack mod: https://steamcommunity.com/sharedfiles/filedetails/?id=1735229517
        local vel = moveData:GetVelocity()

        -- Up movement speed
        if moveData:KeyDown(IN_JUMP) and vel.z < moveSpeedCap then
            vel.z = vel.z + moveVelocity * FrameTime()
        end

        if IsFirstTimePredicted() and SERVER then
            if moveData:KeyDown(IN_JUMP) and not ply.PAPLevitatorSound then
                ply:EmitSound(flySound)
                ply.PAPLevitatorSound = true

                timer.Create("TTTPAPLevitatorSound", 8, 1, function()
                    ply:StopSound(flySound)
                end)
            elseif not moveData:KeyDown(IN_JUMP) then
                ply:StopSound(flySound)
                ply.PAPLevitatorSound = false
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

    SWEP.PAPOldDeploy = SWEP.Deploy

    function SWEP:Deploy()
        self:GetOwner():PrintMessage(HUD_PRINTCENTER, "No need to hold, use guns!")
        self:GetOwner():PrintMessage(HUD_PRINTTALK, "No need to hold, use guns!")

        return self:PAPOldDeploy()
    end

    function SWEP:Think()
    end
end

TTTPAP:Register(UPGRADE)