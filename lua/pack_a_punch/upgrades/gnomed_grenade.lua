local UPGRADE = {}
UPGRADE.id = "gnomed_grenade"
UPGRADE.class = "weapon_gnome_grenade"
UPGRADE.name = "Gnomed Grenade"
UPGRADE.desc = "x2 grenades, victims actually get gnomed"

function UPGRADE:Apply(SWEP)
    SWEP.Primary.ClipSize = 2

    timer.Simple(0.1, function()
        SWEP:SetClip1(2)
    end)

    function SWEP:PrimaryAttack()
        if not self:CanPrimaryAttack() then return end
        local owner = self:GetOwner()
        self:SetNextPrimaryFire(CurTime() + self.Primary.Delay)
        self:SendWeaponAnim(ACT_VM_PULLBACK_HIGH)
        owner:ViewPunch(Angle(-1, -1, 0) * 4)
        self:TakePrimaryAmmo(1)

        timer.Simple(.75, function()
            if IsValid(self) then
                self:SendWeaponAnim(ACT_VM_THROW)

                if IsValid(owner) then
                    owner:ViewPunch(Angle(1, 1, 0) * 10)
                end

                timer.Simple(.1, function()
                    if CLIENT then return end

                    timer.Simple(0.20, function()
                        if IsValid(self) then
                            self:EmitSound("Weapon_Crowbar.Single")
                        end
                    end)

                    self:ThrowGrenade()
                end)

                timer.Simple(.5, function()
                    if IsValid(self) then
                        if engine.ActiveGamemode() == "terrortown" then
                            if SERVER and self:Clip1() <= 0 then
                                self:Remove()
                            end

                            if IsValid(owner) then
                                owner:ConCommand("lastinv")
                            end
                        else
                            self:Deploy()
                        end
                    end
                end)
            end
        end)
    end

    function SWEP:CreateGrenade(src, ang, vel, angimp, ply)
        local grenade = ents.Create("gnome_grenade_proj")
        if not IsValid(grenade) then return end
        grenade:SetPos(src)
        grenade:SetAngles(ang)
        grenade:SetOwner(ply)
        grenade:SetThrower(ply)
        grenade:SetGravity(0.4)
        grenade:SetFriction(0.2)
        grenade:SetElasticity(0.45)
        grenade:Spawn()
        grenade:PhysWake()
        grenade:SetMaterial(TTTPAP.camo)
        grenade.TTTPAPGnomedGrenade = true
        local phys = grenade:GetPhysicsObject()

        if IsValid(phys) then
            phys:SetVelocity(vel)
            phys:AddAngleVelocity(angimp)
        end

        self:GetOwner():SetAnimation(PLAYER_ATTACK1)

        return grenade
    end

    if SERVER then
        util.AddNetworkString("TTTPAPGnomedGrenadePopup")
    end

    self:AddHook("EntityTakeDamage", function(ply, dmg)
        if not self:IsPlayer(ply) then return end
        local inflictor = dmg:GetInflictor()

        if IsValid(inflictor) and inflictor.TTTPAPGnomedGrenade then
            net.Start("TTTPAPGnomedGrenadePopup")
            net.Send(ply)
        end
    end)

    if CLIENT then
        local recieved = false

        net.Receive("TTTPAPGnomedGrenadePopup", function()
            if recieved then return end
            recieved = true
            local mat = Material("ttt_pack_a_punch/gnomed_grenade/gnomed1.png")

            timer.Simple(4.283, function()
                mat = Material("ttt_pack_a_punch/gnomed_grenade/gnomed2.png")
            end)

            timer.Simple(6.342, function()
                mat = Material("ttt_pack_a_punch/gnomed_grenade/gnomed3.png")
            end)

            timer.Simple(8.45, function()
                mat = Material("ttt_pack_a_punch/gnomed_grenade/gnomed4.png")
            end)

            timer.Simple(11.575, function()
                mat = Material("ttt_pack_a_punch/gnomed_grenade/gnomed5.png")
            end)

            timer.Simple(12.708, function()
                mat = Material("ttt_pack_a_punch/gnomed_grenade/gnomed6.png")
            end)

            surface.PlaySound("ttt_pack_a_punch/gnomed_grenade/gnomed.mp3")

            hook.Add("HUDPaintBackground", "TTTPAPGnomedGrenadePopup", function()
                surface.SetDrawColor(255, 255, 255)
                surface.SetMaterial(mat)
                surface.DrawTexturedRect(0, 0, ScrW(), ScrH())
            end)

            timer.Simple(15.222, function()
                hook.Remove("HUDPaintBackground", "TTTPAPGnomedGrenadePopup")
                recieved = false
            end)
        end)
    end
end

TTTPAP:Register(UPGRADE)