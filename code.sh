#!/usr/bin/env bash
# donutbypass-setup.sh — materialises the DonutBypass Fabric mod repo.
# Usage:  bash donutbypass-setup.sh [folder]      (default folder: donutbypass)
set -euo pipefail

ROOT="${1:-donutbypass}"
SRC="$ROOT/src/main"
JAVA="$SRC/java/dev/donutbypass"

mkdir -p "$JAVA/util" "$JAVA/mixin" "$SRC/resources/assets/donutbypass/lang" "$ROOT/.github/workflows"

# ─────────────────────────────────────────────────────────── gradle.properties
cat > "$ROOT/gradle.properties" <<'EOF'
org.gradle.jvmargs=-Xmx2G
org.gradle.parallel=true

minecraft_version=1.21.11
yarn_mappings=1.21.11+build.1
loader_version=0.17.2
fabric_version=0.140.2+1.21.11
loom_version=1.11-SNAPSHOT

mod_version=1.0.0
maven_group=dev.donutbypass
archives_base_name=donutbypass
EOF

# ───────────────────────────────────────────────────────────── settings.gradle
cat > "$ROOT/settings.gradle" <<'EOF'
pluginManagement {
    repositories {
        maven { name = 'Fabric'; url = 'https://maven.fabricmc.net/' }
        mavenCentral()
        gradlePluginPortal()
    }
}
rootProject.name = 'donutbypass'
EOF

# ──────────────────────────────────────────────────────────────── build.gradle
cat > "$ROOT/build.gradle" <<'EOF'
plugins {
    id 'fabric-loom' version "${loom_version}"
}

version = "${mod_version}+${minecraft_version}"
group = project.maven_group

base { archivesName = project.archives_base_name }

repositories {
    maven { url = 'https://maven.fabricmc.net/' }
}

dependencies {
    minecraft "com.mojang:minecraft:${project.minecraft_version}"
    mappings "net.fabricmc:yarn:${project.yarn_mappings}:v2"
    modImplementation "net.fabricmc:fabric-loader:${project.loader_version}"
    modImplementation "net.fabricmc.fabric-api:fabric-api:${project.fabric_version}"
}

processResources {
    inputs.property "version", project.version
    filesMatching("fabric.mod.json") {
        expand "version": project.version
    }
}

tasks.withType(JavaCompile).configureEach {
    it.options.release = 21
    it.options.encoding = "UTF-8"
}

java {
    sourceCompatibility = JavaVersion.VERSION_21
    targetCompatibility = JavaVersion.VERSION_21
    withSourcesJar()
}
EOF

# ──────────────────────────────────────────────────────────────── .gitignore
cat > "$ROOT/.gitignore" <<'EOF'
.gradle/
build/
run/
out/
.idea/
*.iml
.vscode/
*.log
dist/
EOF

# ──────────────────────────────────────────────────────────────────── LICENSE
cat > "$ROOT/LICENSE" <<'EOF'
MIT License

Copyright (c) 2026 DonutBypass contributors

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
EOF

# ─────────────────────────────────────────────────── fabric.mod.json
cat > "$SRC/resources/fabric.mod.json" <<'EOF'
{
  "schemaVersion": 1,
  "id": "donutbypass",
  "version": "${version}",
  "name": "DonutBypass",
  "description": "Client-side bypass suite for DonutSMP's Grim-derived AC, translatable-component integrity probes and layered anti-XRAY.",
  "authors": ["you"],
  "license": "MIT",
  "environment": "client",
  "entrypoints": {
    "client": ["dev.donutbypass.DonutBypassClient"]
  },
  "mixins": ["donutbypass.mixins.json"],
  "depends": {
    "fabricloader": ">=0.16.0",
    "fabric-api": "*",
    "minecraft": ">=1.21.9 <1.22",
    "java": ">=21"
  }
}
EOF

# ─────────────────────────────────────────────────── donutbypass.mixins.json
cat > "$SRC/resources/donutbypass.mixins.json" <<'EOF'
{
  "required": true,
  "minVersion": "0.8",
  "package": "dev.donutbypass.mixin",
  "compatibilityLevel": "JAVA_21",
  "client": [
    "ClientBrandRetrieverMixin",
    "ClientConnectionMixin",
    "ClientPlayerEntityMixin",
    "ClientPlayerInteractionManagerMixin",
    "EntityMixin"
  ],
  "injectors": { "defaultRequire": 1 }
}
EOF

# ─────────────────────────────────────────────────── lang/en_us.json
cat > "$SRC/resources/assets/donutbypass/lang/en_us.json" <<'EOF'
{
  "key.donutbypass.toggle": "Toggle DonutBypass",
  "category.donutbypass": "DonutBypass"
}
EOF

# ─────────────────────────────────────────────────── BypassConfig.java
cat > "$JAVA/BypassConfig.java" <<'EOF'
package dev.donutbypass;

import com.google.gson.Gson;
import com.google.gson.GsonBuilder;

import java.nio.file.Files;
import java.nio.file.Path;

public final class BypassConfig {
    public boolean enabled = true;
    public boolean hud = true;

    public boolean textSanitizer = true;
    public boolean useFallback = false;
    public boolean nbtGuard = true;

    public boolean spoofBrand = true;
    public String brandValue = "vanilla";
    public boolean hideCustomChannels = false;

    public boolean packetPacer = true;
    public int minInteractDelayTicks = 1;
    public int interactJitterTicks = 1;
    public int minBreakDelayTicks = 1;

    public boolean rotationSmoother = true;
    public float rotationStep = 0.35f;
    public float maxRotationPerTick = 45.0f;
    public boolean gcdSnap = true;

    public boolean reachClamp = true;
    public double maxAttackReach = 3.0;

    public boolean layerHaunt = false;
    public int hauntIntervalTicks = 40;
    public double hauntY = -64.0;

    private static final Gson GSON = new GsonBuilder().setPrettyPrinting().create();

    public static BypassConfig load(Path path) {
        try {
            if (Files.exists(path)) {
                BypassConfig c = GSON.fromJson(Files.readString(path), BypassConfig.class);
                if (c != null) return c;
            }
        } catch (Exception ignored) {
        }
        BypassConfig c = new BypassConfig();
        c.save(path);
        return c;
    }

    public void save(Path path) {
        try {
            Files.createDirectories(path.getParent());
            Files.writeString(path, GSON.toJson(this));
        } catch (Exception ignored) {
        }
    }
}
EOF

# ─────────────────────────────────────────────────── DonutBypassClient.java
cat > "$JAVA/DonutBypassClient.java" <<'EOF'
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
EOF

# ─────────────────────────────────────────────────── util/TextSanitizer.java
cat > "$JAVA/util/TextSanitizer.java" <<'EOF'
package dev.donutbypass.util;

import dev.donutbypass.DonutBypassClient;
import net.minecraft.nbt.NbtCompound;
import net.minecraft.nbt.NbtElement;
import net.minecraft.nbt.NbtList;
import net.minecraft.nbt.NbtString;
import net.minecraft.text.MutableText;
import net.minecraft.text.Text;
import net.minecraft.text.TranslatableTextContent;

/**
 * Kills server-driven translation probing. DonutSMP's integrity check ships translatable
 * components through anvils / signs; whether the client's lang files resolve the key is the
 * fingerprint. We never resolve: the key (or the server fallback) becomes a plain literal.
 */
public final class TextSanitizer {

    public static Text literalize(Text in) {
        if (in == null) return null;
        if (!hasTranslatable(in)) return in;
        return flatten(in);
    }

    private static boolean hasTranslatable(Text t) {
        if (t.getContent() instanceof TranslatableTextContent) return true;
        for (Text s : t.getSiblings()) if (hasTranslatable(s)) return true;
        return false;
    }

    private static MutableText flatten(Text t) {
        String raw;
        if (t.getContent() instanceof TranslatableTextContent tc) {
            String fallback = tc.getFallback();
            raw = (DonutBypassClient.config().useFallback && fallback != null && !fallback.isEmpty())
                    ? fallback : tc.getKey();
        } else {
            raw = safeString(t);
        }
        MutableText out = Text.literal(raw).setStyle(t.getStyle());
        for (Text s : t.getSiblings()) {
            out.append(hasTranslatable(s) ? flatten(s) : s.copy());
        }
        return out;
    }

    private static String safeString(Text t) {
        try {
            return t.getString();
        } catch (Throwable e) {
            return "";
        }
    }

    public static String sanitizeComponentJson(String json) {
        if (json == null || !json.contains("translate")) return json;
        return json.replace("\"translate\"", "\"text\"");
    }

    public static NbtCompound sanitizeNbt(NbtCompound in) {
        if (!DonutBypassClient.config().nbtGuard) return in;
        NbtCompound out = in.copy();
        walk(out);
        return out;
    }

    private static void walk(NbtCompound compound) {
        for (String key : compound.getKeys()) {
            NbtElement el = compound.get(key);
            if (el instanceof NbtString s) {
                String v = s.asString();
                if (v.indexOf('{') >= 0 && v.contains("translate")) {
                    compound.putString(key, sanitizeComponentJson(v));
                }
            } else if (el instanceof NbtCompound c) {
                walk(c);
            } else if (el instanceof NbtList list) {
                for (int i = 0; i < list.size(); i++) {
                    NbtElement e = list.get(i);
                    if (e instanceof NbtCompound c) {
                        walk(c);
                    } else if (e instanceof NbtString s) {
                        String v = s.asString();
                        if (v.indexOf('{') >= 0 && v.contains("translate")) {
                            list.set(i, NbtString.of(sanitizeComponentJson(v)));
                        }
                    }
                }
            }
        }
    }

    private TextSanitizer() {}
}
EOF

# ─────────────────────────────────────────────── util/PacketTextFilter.java
cat > "$JAVA/util/PacketTextFilter.java" <<'EOF'
package dev.donutbypass.util;

import dev.donutbypass.DonutBypassClient;
import net.minecraft.nbt.NbtCompound;
import net.minecraft.network.packet.Packet;
import net.minecraft.text.Text;

import java.lang.reflect.Field;
import java.lang.reflect.Modifier;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.concurrent.ConcurrentHashMap;

/**
 * Reflection-driven, mapping-independent inbound packet scrubber: every Text / List<Text> /
 * Optional<Text> / NbtCompound field on any S2C packet is flattened before rendering.
 */
public final class PacketTextFilter {
    private static final Map<Class<?>, List<Field>> CACHE = new ConcurrentHashMap<>();

    public static void filter(Packet<?> packet) {
        if (packet == null) return;
        for (Field f : fields(packet.getClass())) {
            try {
                Object v = f.get(packet);
                if (v == null) continue;
                Class<?> type = f.getType();

                if (Text.class.isAssignableFrom(type)) {
                    Text out = TextSanitizer.literalize((Text) v);
                    if (out != v) f.set(packet, out);
                } else if (type == List.class && v instanceof List<?> list && !list.isEmpty()
                        && list.get(0) instanceof Text) {
                    List<Text> out = new ArrayList<>(list.size());
                    for (Object o : list) out.add(TextSanitizer.literalize((Text) o));
                    f.set(packet, out);
                } else if (type == Optional.class && v instanceof Optional<?> opt
                        && opt.orElse(null) instanceof Text t) {
                    f.set(packet, Optional.ofNullable(TextSanitizer.literalize(t)));
                } else if (v instanceof NbtCompound nbt && DonutBypassClient.config().nbtGuard) {
                    f.set(packet, TextSanitizer.sanitizeNbt(nbt));
                }
            } catch (Throwable ignored) {
            }
        }
    }

    private static List<Field> fields(Class<?> cls) {
        return CACHE.computeIfAbsent(cls, c -> {
            List<Field> list = new ArrayList<>();
            for (Class<?> k = c; k != null && k != Object.class; k = k.getSuperclass()) {
                for (Field f : k.getDeclaredFields()) {
                    if (Modifier.isStatic(f.getModifiers())) continue;
                    Class<?> t = f.getType();
                    if (Text.class.isAssignableFrom(t) || t == List.class || t == Optional.class
                            || NbtCompound.class.isAssignableFrom(t)) {
                        try {
                            f.setAccessible(true);
                            list.add(f);
                        } catch (Throwable ignored) {
                        }
                    }
                }
            }
            return list;
        });
    }

    private PacketTextFilter() {}
}
EOF

# ──────────────────────────────────────────────────── util/PacketPacer.java
cat > "$JAVA/util/PacketPacer.java" <<'EOF'
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
EOF

# ──────────────────────────────────────────────────────── util/McSends.java
cat > "$JAVA/util/McSends.java" <<'EOF'
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
EOF

# ──────────────────────────────────────────────────── util/RotationMath.java
cat > "$JAVA/util/RotationMath.java" <<'EOF'
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
EOF

# ──────────────────────────────────────────────────────── util/LayerSpoof.java
cat > "$JAVA/util/LayerSpoof.java" <<'EOF'
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
EOF

# ───────────────────────────────────────────── mixin/ClientConnectionMixin.java
cat > "$JAVA/mixin/ClientConnectionMixin.java" <<'EOF'
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
EOF

# ──────────────────────────────────────────────────────── mixin/EntityMixin.java
cat > "$JAVA/mixin/EntityMixin.java" <<'EOF'
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
EOF

# ──────────────────────────────────────────── mixin/ClientPlayerEntityMixin.java
cat > "$JAVA/mixin/ClientPlayerEntityMixin.java" <<'EOF'
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
EOF

# ────────────────────────────── mixin/ClientPlayerInteractionManagerMixin.java
cat > "$JAVA/mixin/ClientPlayerInteractionManagerMixin.java" <<'EOF'
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
EOF

# ──────────────────────────────────────── mixin/ClientBrandRetrieverMixin.java
cat > "$JAVA/mixin/ClientBrandRetrieverMixin.java" <<'EOF'
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
EOF

# ────────────────────────────────────────────── .github/workflows/build.yml
cat > "$ROOT/.github/workflows/build.yml" <<'EOF'
name: Build

on:
  push:
    branches: [ main ]
    tags: [ 'v*' ]
  pull_request:
  workflow_dispatch:

permissions:
  contents: write

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Set up JDK 21
        uses: actions/setup-java@v4
        with:
          distribution: temurin
          java-version: '21'

      - name: Cache Gradle
        uses: actions/cache@v4
        with:
          path: |
            ~/.gradle/caches
            ~/.gradle/wrapper
          key: gradle-${{ runner.os }}-${{ hashFiles('**/*.gradle*', '**/gradle.properties') }}
          restore-keys: gradle-${{ runner.os }}-

      - name: Setup Gradle
        uses: gradle/actions/setup-gradle@v3
        with:
          gradle-version: '8.12'

      - name: Build
        run: gradle build --no-daemon --stacktrace

      - name: Collect jar
        id: find
        run: |
          mkdir -p dist
          found=$(find build/libs -maxdepth 1 -name '*.jar' ! -name '*-sources.jar' ! -name '*-dev.jar' | head -n1)
          echo "jar=$found" >> "$GITHUB_OUTPUT"
          cp "$found" dist/
          ls -l dist

      - uses: actions/upload-artifact@v4
        with:
          name: donutbypass-${{ github.sha }}
          path: dist/*.jar
          if-no-files-found: error

      - name: Release on tag
        if: startsWith(github.ref, 'refs/tags/v')
        uses: softprops/action-gh-release@v2
        with:
          files: dist/*.jar
          generate_release_notes: true
EOF

# ────────────────────────────────────────────────────────────── README.md
cat > "$ROOT/README.md" <<'EOF'
# DonutBypass

Fabric client-side bypass suite for the current DonutSMP stack (customised GrimAC +
translatable-component client-integrity probes + layered anti-XRAY), targeting 1.21.11.

## Modules

| Module | Targets | How |
|---|---|---|
| Text sanitizer | anvil/sign translation profiling (Meteor/Freecam bans) | flatten every non-literal S2C component; never resolve lang keys |
| NBT guard | sign lines / item names carrying component JSON | `"translate"` -> `"text"` rewrite |
| Brand / channel spoof | client fingerprint | brand `vanilla`, optional meteor channel suppression |
| Packet pacer | Grim timer / fast-place kick | rate cap + random jitter on interact/break packets |
| Rotation smoother | rotation-snap + mouse-GCD flags | spread deltas across ticks, quantise to sensitivity GCD |
| Reach clamp | reach check | cancel attacks beyond 3.0 block box distance |
| Layer haunt | layered anti-XRAY / anti-ESP | alternating claimed Y to force deeper layer reveals |

## Build

```bash
gradle build
# -> build/libs/donutbypass-1.0.0+1.21.11.jar
