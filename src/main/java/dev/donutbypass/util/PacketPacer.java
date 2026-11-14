package dev.donutbypass.util;

import dev.donutbypass.BypassConfig;
import dev.donutbypass.DonutBypassClient;
import net.minecraft.client.MinecraftClient;
import net.minecraft.network.packet.Packet;
import net.minecraft.network.packet.c2s.common.CustomPayloadC2SPacket;
import net.minecraft.network.packet.c2s.play.PlayerActionC2SPacket;
import net.minecraft.network.packet.c2s.play.PlayerInteractBlockC2SPacket;
import net.minecraft.network.packet.c2s.play.PlayerInteractItemC2SPacket;

import java.util.concurrent.ThreadLocalRandom;

/**
 * Outbound throttle. DonutSMP's timer/action-rate check kicks on fast-place cadence and flags
 * static intervals, so we cap the rate AND jitter it.
 */
public final class PacketPacer {
    private static int lastInteractTick = -100;
    private static int lastBreakTick = -100;
    private static int lastInteractDelay = 1;
    private static boolean rewritingBrand = false;

    public static void tick() {
        // reserved for future burst limiting
    }

    public static boolean shouldDrop(Packet<?> packet) {
        BypassConfig c = DonutBypassClient.config();
        MinecraftClient mc = MinecraftClient.getInstance();
        if (!c.enabled || mc.player == null || mc.world == null) return false;

        if (c.spoofBrand && !rewritingBrand && packet instanceof CustomPayloadC2SPacket cp) {
            try {
                if ("minecraft:brand".equals(cp.payload().getId().toString())) {
                    rewritingBrand = true;
                    McSends.brand(mc, c.brandValue);
                    rewritingBrand = false;
                    return true;
                }
            } catch (Throwable ignored) {
            }
        }

        if (!c.packetPacer) return false;

        if (c.hideCustomChannels && packet instanceof CustomPayloadC2SPacket cp) {
            try {
                String id = cp.payload().getId().toString();
                if (id.contains("meteor")) return true;
            } catch (Throwable ignored) {
            }
        }

        int tick = mc.player.age;

        if (packet instanceof PlayerInteractBlockC2SPacket || packet instanceof PlayerInteractItemC2SPacket) {
            if (tick - lastInteractTick < Math.max(1, lastInteractDelay)) return true;
            lastInteractTick = tick;
            int jitter = c.interactJitterTicks > 0
                    ? ThreadLocalRandom.current().nextInt(c.interactJitterTicks + 1) : 0;
            lastInteractDelay = Math.max(0, c.minInteractDelayTicks) + jitter;
        }

        if (packet instanceof PlayerActionC2SPacket action
                && action.getAction() == PlayerActionC2SPacket.Action.START_DESTROY_BLOCK) {
            if (tick - lastBreakTick < Math.max(1, c.minBreakDelayTicks)) return true;
            lastBreakTick = tick;
        }

        return false;
    }

    private PacketPacer() {}
}
