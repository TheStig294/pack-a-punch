local UPGRADE = {}
UPGRADE.id = "vacuum_eater"
UPGRADE.class = "weapon_can_eater"
UPGRADE.name = "Vacuum Eater"
UPGRADE.desc = "Sucks people in to eat them!"

UPGRADE.convars = {
    {
        name = "pap_vacuum_eater_force",
        type = "int"
    },
    {
        name = "pap_vacuum_eater_range",
        type = "int"
    },
    {
        name = "pap_vacuum_eater_angle",
        type = "int"
    },
}

local forceCvar = CreateConVar("pap_vacuum_eater_force", "1000", {FCVAR_REPLICATED, FCVAR_NOTIFY}, "Player-sucking force", 1, 1500)

local rangeCvar = CreateConVar("pap_vacuum_eater_range", "200", {FCVAR_REPLICATED, FCVAR_NOTIFY}, "Player-sucking range", 1, 1000)

local angleCvar = CreateConVar("pap_vacuum_eater_angle", "45", {FCVAR_REPLICATED, FCVAR_NOTIFY}, "Player-sucking angle cone", 1, 180)

function UPGRADE:Apply(SWEP)
    SWEP.Primary.Force = forceCvar:GetInt()
    SWEP.Primary.Range = rangeCvar:GetInt()
    SWEP.Primary.Angle = angleCvar:GetInt()
    -- Hardcoded because that's the length of the vacuum sound effect
    SWEP.Primary.Duration = 7
    -- Squared for distance calculation optimisation
    SWEP.Primary.EatRange = 100 * 100
    SWEP.Primary.ForceStopTime = nil
    SWEP.Primary.ForceStop = false
    SWEP.Primary.IsSucking = false

    self:AddToHook(SWEP, "PrimaryAttack", function()
        local owner = SWEP:GetOwner()
        if not IsValid(owner) then return end
        SWEP:EmitSound("ttt_pack_a_punch/vacuum_eater/vacuum.mp3")
        SWEP.Primary.IsSucking = true
    end)

    function SWEP:Think()
        local owner = self:GetOwner()
        if not IsValid(owner) then return end

        -- Do sucking
        if owner:KeyDown(IN_ATTACK) then
            if self.Primary.ForceStop then
                if self.Primary.IsSucking then
                    self:StopSound("ttt_pack_a_punch/vacuum_eater/vacuum.mp3")
                    self:EmitSound("ttt_pack_a_punch/vacuum_eater/vacuum_end.mp3")
                    self.Primary.IsSucking = false
                end
            else
                for _, ent in ipairs(ents.FindInCone(owner:GetShootPos(), owner:GetAimVector():GetNormalized(), self.Primary.Range, math.cos(math.rad(self.Primary.Angle)))) do
                    if not IsValid(ent) then continue end
                    ent:SetGroundEntity(NULL)
                    ent:SetVelocity(-owner:GetAimVector() * Vector(self.Primary.Force, self.Primary.Force, 0))
                    local phys = ent:GetPhysicsObject()

                    if IsValid(phys) then
                        phys:ApplyForceOffset(-owner:GetAimVector() * self.Primary.Force, ent:GetPos())
                    end

                    if UPGRADE:IsAlivePlayer(ent) and owner:GetPos():Distance2DSqr(ent:GetPos()) < self.Primary.EatRange then
                        self:PrimaryAttack()
                        self.Primary.ForceStopTime = CurTime() + self.Primary.Duration
                    end
                end
            end

            if self.Primary.ForceStopTime then
                if self.Primary.ForceStopTime < CurTime() then
                    self.Primary.ForceStop = true
                end
            else
                self.Primary.ForceStopTime = CurTime() + self.Primary.Duration
            end
            -- Stop sucking
        else
            if self.Primary.ForceStop then
                self.Primary.ForceStop = false
                self.Primary.ForceStopTime = nil
            else
                if self.Primary.IsSucking then
                    self:StopSound("ttt_pack_a_punch/vacuum_eater/vacuum.mp3")
                    self:EmitSound("ttt_pack_a_punch/vacuum_eater/vacuum_end.mp3")
                    self.Primary.IsSucking = false
                end
            end
        end
    end
end

TTTPAP:Register(UPGRADE)