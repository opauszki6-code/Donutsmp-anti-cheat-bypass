package dev.donutbypass.mixin;

import dev.donutbypass.DonutBypassClient;
import dev.donutbypass.util.RotationMath;
import net.minecraft.client.MinecraftClient;
import net.minecraft.entity.Entity;
import org.spongepowered.asm.mixin.Mixin;
import org.spongepowered.asm.mixin.injection.At;
import org.spongepowered.asm.mixin.injection.Inject;
import org.spongepowered.asm.mixin.injection.callback.CallbackInfo;

@Mixin(Entity.class)
public abstract class EntityMixin {

    @Inject(method = "changeLookDirection(DD)V", at = @At("HEAD"), cancellable = true)
    private void donut$captureLook(double cursorDeltaX, double cursorDeltaY, CallbackInfo ci) {
        if (!DonutBypassClient.config().enabled || !DonutBypassClient.config().rotationSmoother) return;
        if ((Object) this != MinecraftClient.getInstance().player) return;
        RotationMath.onLook(cursorDeltaX, cursorDeltaY);
        ci.cancel();
    }
}
