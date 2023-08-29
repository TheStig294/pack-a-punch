local UPGRADE = {}
UPGRADE.id = "darkness_knife"
UPGRADE.class = "weapon_kil_knife"
UPGRADE.name = "Darkness Knife"
UPGRADE.desc = "Right-click to make the map go dark!\nLasts until you die, or lose the knife!"

function UPGRADE:Apply(SWEP)
    if SERVER then
        util.AddNetworkString("TTTPAPDarknessKnifeActivate")
    end

    function SWEP:SecondaryAttack()
        if CLIENT or self.PAPMapDark then return end
        self.PAPMapDark = true
        engine.LightStyle(0, "a")
        net.Start("TTTPAPDarknessKnifeActivate")
        net.WriteBool(true)
        net.Broadcast()
    end

    function SWEP:OnRemove()
        if CLIENT then return end
        engine.LightStyle(0, "m")
        net.Start("TTTPAPDarknessKnifeActivate")
        net.WriteBool(false)
        net.Broadcast()
    end

    if CLIENT then
        net.Receive("TTTPAPDarknessKnifeActivate", function()
            local activate = net.ReadBool()

            if activate then
                surface.PlaySound("ttt_pack_a_punch/darkness_knife/whisper.mp3")
                self:AddHook("PreDrawSkyBox", function() return true end)
            end

            render.RedownloadAllLightmaps(true, true)
        end)
    end
end

function UPGRADE:Reset()
    render.RedownloadAllLightmaps(true, true)
end

TTTPAP:Register(UPGRADE)