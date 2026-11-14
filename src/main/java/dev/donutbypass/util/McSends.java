package dev.donutbypass.util;

import net.minecraft.client.MinecraftClient;
import net.minecraft.network.packet.c2s.common.BrandCustomPayload;
import net.minecraft.network.packet.c2s.common.CustomPayloadC2SPacket;

/** Isolates the one version-sensitive call (brand payload) in a single class. */
public final class McSends {
    public static void brand(MinecraftClient mc, String brand) {
        if (mc.getNetworkHandler() == null) return;
        mc.getNetworkHandler().sendPacket(new CustomPayloadC2SPacket(new BrandCustomPayload(brand)));
    }

    private McSends() {}
}
