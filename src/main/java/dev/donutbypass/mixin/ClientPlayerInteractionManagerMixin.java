package dev.donutbypass.mixin;

import dev.donutbypass.BypassConfig;
import dev.donutbypass.DonutBypassClient;
import net.minecraft.client.network.ClientPlayerInteractionManager;
import net.minecraft.entity.Entity;
import net.minecraft.entity.player.PlayerEntity;
import net.minecraft.util.math.Box;
import net.minecraft.util.math.Vec3d;
import org.spongepowered.asm.mixin.Mixin;
import org.spongepowered.asm.mixin.injection.At;
import org.spongepowered.asm.mixin.injection.Inject;
import org.spongepowered.asm.mixin.injection.callback.CallbackInfo;

@Mixin(ClientPlayerInteractionManager.class)
public abstract class ClientPlayerInteractionManagerMixin {

    @Inject(method = "attackEntity", at = @At("HEAD"), cancellable = true)
    private void donut$clampReach(PlayerEntity player, Entity target, CallbackInfo ci) {
        BypassConfig c = DonutBypassClient.config();
        if (!c.enabled || !c.reachClamp) return;
        Vec3d eye = player.getEyePos();
        Box b = target.getBoundingBox();
        double dx = Math.max(0.0, Math.max(b.minX - eye.x, eye.x - b.maxX));
        double dy = Math.max(0.0, Math.max(b.minY - eye.y, eye.y - b.maxY));
        double dz = Math.max(0.0, Math.max(b.minZ - eye.z, eye.z - b.maxZ));
        double limit = c.maxAttackReach;
        if (dx * dx + dy * dy + dz * dz > limit * limit) ci.cancel();
    }
}
