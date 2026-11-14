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
