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
