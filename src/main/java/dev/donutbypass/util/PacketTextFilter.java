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
