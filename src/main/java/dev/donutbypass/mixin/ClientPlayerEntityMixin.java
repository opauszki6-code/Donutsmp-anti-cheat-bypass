package dev.donutbypass.mixin;

import dev.donutbypass.DonutBypassClient;
import dev.donutbypass.util.LayerSpoof;
import net.minecraft.client.network.ClientPlayerEntity;
import org.spongepowered.asm.mixin.Mixin;
import org.spongepowered.asm.mixin.injection.At;
import org.spongepowered.asm.mixin.injection.Inject;
import org.spongepowered.asm.mixin.injection.callback.CallbackInfo;

@Mixin(ClientPlayerEntity.class)
public abstract class ClientPlayerEntityMixin {

    @Inject(method = "sendMovementPackets", at = @At("TAIL"))
    private void donut$haunt(CallbackInfo ci) {
        if (!DonutBypassClient.config().enabled) return;
        try {
            LayerSpoof.tick();
        } catch (Throwable ignored) {
        }
    }
}
