# Mariachi Flags 🎵🇲🇽

A kids geography game for iPhone. Jarabe Tapatío plays in the background while a 3D Earth globe spins. The music fades, the globe flies to a country, and you have to guess which flag belongs to it — before time runs out.

## Gameplay

- The globe rotates while music plays
- Music fades → globe zooms into a target country (borders highlighted in green)
- A flag emoji appears with 4 answer options
- Pick the right country name before the timer runs out
- 3 lives · streak multiplier · timer gets shorter as your score climbs
- High scores saved locally (top 10)

## Building

Requires Xcode and an iOS 16+ simulator or device.

```bash
make run    # build + launch in iPhone 17 simulator
make build  # compile only
make clean  # wipe build artifacts
```

To run on a physical iPhone: open the project in Xcode, set your development team, and run.

## Resources

All resources are free and open:

| Resource | Source | License |
|----------|--------|---------|
| Earth texture | [NASA Blue Marble](https://visibleearth.nasa.gov) | Public domain |
| Country borders | [johan/world.geo.json](https://github.com/johan/world.geo.json) | Public domain |
| Background music | Jarabe Tapatío — Mariachi Pulido via Internet Archive | Public domain |

## Tech

- SwiftUI + SceneKit (3D globe)
- AVFoundation (audio with ambient session)
- No third-party dependencies
