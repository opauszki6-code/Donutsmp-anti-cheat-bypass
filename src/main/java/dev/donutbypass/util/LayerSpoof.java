package dev.donutbypass.util;

import dev.donutbypass.BypassConfig;
import dev.donutbypass.DonutBypassClient;
import net.minecraft.client.MinecraftClient;
import net.minecraft.network.packet.c2s.play.PlayerMoveC2SPacket;
import net.minecraft.util.math.Vec3d;

/**
 * DonutSMP's layered anti-XRAY reveals block layers based on the Y a client claims to be at.
 * We alternate one forced position packet at hauntY with one at the real Y so the server hands
 * over layers it would otherwise hide, then reconciles the position a tick later.
 */
public final class LayerSpoof {
    private static int phase = 0;

    public static void tick() {
        BypassConfig c = DonutBypassClient.config();
        MinecraftClient mc = MinecraftClient.getInstance();
        if (!c.layerHaunt || mc.player == null || mc.getNetworkHandler() == null || mc.world == null) return;
        int interval = Math.max(2, c.hauntIntervalTicks);
        if (mc.player.age % interval != 0) return;

        Vec3d p = mc.player.getPos();
        boolean fake = (phase++ % 2) == 0;
        double y = fake ? c.hauntY : p.y;
        mc.getNetworkHandler().sendPacket(
                new PlayerMoveC2SPacket.PositionAndOnGround(p.x, y, p.z, mc.player.isOnGround(), false));
    }

    private LayerSpoof() {}
}
