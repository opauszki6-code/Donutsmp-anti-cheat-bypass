package dev.donutbypass.mixin;

import dev.donutbypass.DonutBypassClient;
import dev.donutbypass.util.PacketPacer;
import dev.donutbypass.util.PacketTextFilter;
import io.netty.channel.ChannelHandlerContext;
import net.minecraft.network.ClientConnection;
import net.minecraft.network.packet.Packet;
import org.spongepowered.asm.mixin.Mixin;
import org.spongepowered.asm.mixin.injection.At;
import org.spongepowered.asm.mixin.injection.Inject;
import org.spongepowered.asm.mixin.injection.callback.CallbackInfo;

@Mixin(ClientConnection.class)
public abstract class ClientConnectionMixin {

    @Inject(method = "channelRead0(Lio/netty/channel/ChannelHandlerContext;Lnet/minecraft/network/packet/Packet;)V",
            at = @At("HEAD"))
    private void donut$sanitizeInbound(ChannelHandlerContext ctx, Packet<?> packet, CallbackInfo ci) {
        if (!DonutBypassClient.config().enabled || !DonutBypassClient.config().textSanitizer) return;
        try {
            PacketTextFilter.filter(packet);
        } catch (Throwable ignored) {
        }
    }

    @Inject(method = "send(Lnet/minecraft/network/packet/Packet;)V", at = @At("HEAD"), cancellable = true)
    private void donut$paceOutbound(Packet<?> packet, CallbackInfo ci) {
        if (PacketPacer.shouldDrop(packet)) ci.cancel();
    }
}
