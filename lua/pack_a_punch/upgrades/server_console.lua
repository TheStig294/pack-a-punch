local UPGRADE = {}
UPGRADE.id = "server_console"
UPGRADE.class = "weapon_ttt_adm_menu"
UPGRADE.name = "Server Console"
UPGRADE.desc = "Right-click someone to upgrade their weapon!\n +50 admin power! (Costs 50 power per upgrade)"

UPGRADE.convars = {
    {
        name = "pap_server_console_admin_power",
        type = "int"
    },
    {
        name = "pap_server_console_admin_power_cost",
        type = "int"
    }
}

local powerCvar = CreateConVar("pap_server_console_admin_power", "50", {FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_REPLICATED}, "Amount of extra admin power to give the admin", 1, 300)

local powerCostCvar = CreateConVar("pap_server_console_admin_power_cost", "50", {FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_REPLICATED}, "Power upgrading a weapon costs", 1, 100)

function UPGRADE:Apply(SWEP)
    local admin = SWEP:GetOwner()
    if not IsValid(admin) then return end
    admin:SetNWInt("TTTAdminPower", admin:GetNWInt("TTTAdminPower", 0) + powerCvar:GetInt())

    function SWEP:SecondaryAttack()
        if CLIENT then return end
        local owner = self:GetOwner()

        if not IsValid(owner) or owner:GetNWInt("TTTAdminPower", 0) < powerCostCvar:GetInt() then
            owner:ChatPrint("You don't have enough admin power to use this command!")

            return
        end

        local target = owner:GetEyeTrace().Entity

        if IsPlayer(target) then
            TTTPAP:OrderPAP(target)
            owner:SetNWInt("TTTAdminPower", owner:GetNWInt("TTTAdminPower", 0) - powerCostCvar:GetInt())
            target:ChatPrint("Your weapon has been upgraded by an Admin!")
        end
    end
end

TTTPAP:Register(UPGRADE)