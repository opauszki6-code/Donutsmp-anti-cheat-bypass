package dev.donutbypass.mixin;

import dev.donutbypass.DonutBypassClient;
import net.minecraft.client.ClientBrandRetriever;
import org.spongepowered.asm.mixin.Mixin;
import org.spongepowered.asm.mixin.injection.At;
import org.spongepowered.asm.mixin.injection.Inject;
import org.spongepowered.asm.mixin.injection.callback.CallbackInfoReturnable;

@Mixin(ClientBrandRetriever.class)
public abstract class ClientBrandRetrieverMixin {

    @Inject(method = "getClientModName", at = @At("HEAD"), cancellable = true)
    private static void donut$brand(CallbackInfoReturnable<String> cir) {
        if (DonutBypassClient.config().enabled && DonutBypassClient.config().spoofBrand) {
            cir.setReturnValue(DonutBypassClient.config().brandValue);
        }
    }
}
