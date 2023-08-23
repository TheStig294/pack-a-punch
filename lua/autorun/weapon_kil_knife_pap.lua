TTT_PAP_UPGRADES = TTT_PAP_UPGRADES or {}

if SERVER then
    util.AddNetworkString("TTTPAPKnifeActivate")
    util.AddNetworkString("TTTPAPKnifeDeactivate")
end

TTT_PAP_UPGRADES.weapon_kil_knife = {
    name = "Darkness Knife",
    desc = "Right-click to make the map go dark!\nLasts until you die, or lose the knife!",
    func = function(SWEP)
        function SWEP:SecondaryAttack()
            if CLIENT or self.PAPMapDark then return end
            self.PAPMapDark = true
            engine.LightStyle(0, "a")
            net.Start("TTTPAPKnifeActivate")
            net.Broadcast()
        end

        function SWEP:OnRemove()
            if CLIENT then return end
            engine.LightStyle(0, "m")
            net.Start("TTTPAPKnifeDeactivate")
            net.Broadcast()
        end
    end
}

if CLIENT then
    net.Receive("TTTPAPKnifeActivate", function()
        surface.PlaySound("ttt_pack_a_punch/killer_knife/whisper.mp3")
        render.RedownloadAllLightmaps(true, true)
        hook.Add("PreDrawSkyBox", "TTTPAPKillerKnifeRemoveSkybox", function() return true end)

        hook.Add("TTTPrepareRound", "TTTPAPKillerKnifeResetClient", function()
            render.RedownloadAllLightmaps(true, true)
            hook.Remove("PreDrawSkyBox", "TTTPAPKillerKnifeRemoveSkybox")
            hook.Remove("TTTPrepareRound", "TTTPAPKillerKnifeResetClient")
        end)
    end)

    net.Receive("TTTPAPKnifeDeactivate", function()
        render.RedownloadAllLightmaps(true, true)
        hook.Remove("PreDrawSkyBox", "TTTPAPKillerKnifeRemoveSkybox")
        hook.Remove("TTTPrepareRound", "TTTPAPKillerKnifeResetClient")
    end)
end