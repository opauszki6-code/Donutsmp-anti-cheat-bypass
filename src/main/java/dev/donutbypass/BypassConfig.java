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
