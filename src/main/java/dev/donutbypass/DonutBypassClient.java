package dev.donutbypass;

import dev.donutbypass.util.LayerSpoof;
import dev.donutbypass.util.PacketPacer;
import dev.donutbypass.util.RotationMath;
import net.fabricmc.api.ClientModInitializer;
import net.fabricmc.fabric.api.client.event.lifecycle.v1.ClientTickEvents;
import net.fabricmc.fabric.api.client.keybinding.v1.KeyBindingHelper;
import net.fabricmc.fabric.api.client.rendering.v1.HudRenderCallback;
import net.fabricmc.loader.api.FabricLoader;
import net.minecraft.client.MinecraftClient;
import net.minecraft.client.option.KeyBinding;
import net.minecraft.client.util.InputUtil;
import net.minecraft.text.Text;
import org.lwjgl.glfw.GLFW;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.nio.file.Path;

public final class DonutBypassClient implements ClientModInitializer {
    public static final String MOD_ID = "donutbypass";
    public static final Logger LOG = LoggerFactory.getLogger("DonutBypass");

    private static BypassConfig config = new BypassConfig();
    private static Path configPath;
    private static KeyBinding toggleKey;

    public static BypassConfig config() { return config; }

    @Override
    public void onInitializeClient() {
        configPath = FabricLoader.getInstance().getConfigDir().resolve("donutbypass.json");
        config = BypassConfig.load(configPath);
        LOG.info("[DonutBypass] loaded, enabled={}", config.enabled);

        toggleKey = KeyBindingHelper.registerKeyBinding(new KeyBinding(
                "key.donutbypass.toggle", InputUtil.Type.KEYSYM, GLFW.GLFW_KEY_RIGHT_SHIFT, "category.donutbypass"));

        ClientTickEvents.END_CLIENT_TICK.register(client -> {
            while (toggleKey.wasPressed()) {
                config.enabled = !config.enabled;
                config.save(configPath);
                if (client.player != null) {
                    client.player.sendMessage(Text.literal("[DonutBypass] " + (config.enabled ? "ON" : "OFF")), true);
                }
            }
            if (!config.enabled) return;
            RotationMath.tick();
            PacketPacer.tick();
        });

        HudRenderCallback.EVENT.register((context, tickCounter) -> {
            if (!config.enabled || !config.hud) return;
            MinecraftClient mc = MinecraftClient.getInstance();
            if (mc.player == null || mc.options.hudHidden || mc.getDebugHud().shouldShowDebugHud()) return;
            String line = "DonutBypass  components=" + (config.textSanitizer ? "on" : "off")
                    + " pace=" + (config.packetPacer ? "on" : "off")
                    + " rot=" + (config.rotationSmoother ? "on" : "off")
                    + " xray=" + (config.layerHaunt ? "on" : "off");
            context.drawText(mc.textRenderer, line, 4, 4, 0xFF9EFFA0, true);
        });
    }
}
