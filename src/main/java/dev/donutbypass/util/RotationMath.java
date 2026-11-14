package dev.donutbypass.util;

import dev.donutbypass.BypassConfig;
import dev.donutbypass.DonutBypassClient;
import net.minecraft.client.MinecraftClient;

/**
 * a) spreads one mouse delta over several ticks -> no rotation "snap" at tick boundaries
 * b) quantises yaw/pitch to the mouse-sensitivity GCD -> passes Grim's mouse-delta sanity check
 */
public final class RotationMath {
    private static float pendingYaw;
    private static float pendingPitch;

    public static void onLook(double deltaX, double deltaY) {
        pendingYaw += (float) deltaX * 0.15f;
        pendingPitch += (float) deltaY * 0.15f;
    }

    public static void tick() {
        MinecraftClient mc = MinecraftClient.getInstance();
        BypassConfig c = DonutBypassClient.config();
        if (mc.player == null || !c.rotationSmoother) {
            pendingYaw = 0;
            pendingPitch = 0;
            return;
        }
        if (pendingYaw == 0.0f && pendingPitch == 0.0f) return;

        float step = Math.max(0.05f, Math.min(1.0f, c.rotationStep));
        float cap = Math.max(1.0f, c.maxRotationPerTick);

        float dy = clamp(pendingYaw * step, cap);
        float dp = clamp(pendingPitch * step, cap);

        float yaw = mc.player.getYaw() + dy;
        float pitch = mc.player.getPitch() + dp;

        if (c.gcdSnap) {
            double sens = mc.options.getMouseSensitivity().getValue();
            yaw = snap(yaw, sens);
            pitch = snap(pitch, sens);
        }
        pitch = Math.max(-90.0f, Math.min(90.0f, pitch));

        mc.player.setYaw(yaw);
        mc.player.setPitch(pitch);

        pendingYaw -= dy;
        pendingPitch -= dp;
        if (Math.abs(pendingYaw) < 0.01f) pendingYaw = 0.0f;
        if (Math.abs(pendingPitch) < 0.01f) pendingPitch = 0.0f;
    }

    private static float clamp(float v, float cap) {
        return Math.max(-cap, Math.min(cap, v));
    }

    public static float snap(float value, double sensitivity) {
        float f = (float) sensitivity * 0.6f + 0.2f;
        float gcd = f * f * f * 1.2f;
        if (gcd <= 0.0f) return value;
        return Math.round(value / gcd) * gcd;
    }

    private RotationMath() {}
}
