# Sprite Animation Notes

Last updated: 2025-12-28T18:33:11.180Z

## Peg-Leg Galloping Walk
This loop exaggerates imbalance to sell a peg leg or uneven weight distribution.

- Use a **6-frame cycle** where the dominant leg eases in/out while the peg leg snaps into place.
- Keep maximum leg extension within **6 pixels** of offset.
- Let the peg leg remain short for several frames, then drop sharply and hold ground contact slightly longer for the stomp.

| Frame | Dominant Leg Extension | Peg Leg Extension |
| ----- | ---------------------- | ----------------- |
| 1 | 6 px | 2 px |
| 2 | 5 px | 2 px |
| 3 | 4 px | 3 px |
| 4 | 3 px | 6 px |
| 5 | 4 px | 5 px |
| 6 | 5 px | 3 px |

If the animation feels off-balance, it is correct—the contrast between legs communicates the peg-leg gait.

## Regular Walking Motion
This loop is smooth and balanced with no gallop or stomp.

- Use a **6-frame cycle** where both legs mirror each other.
- Legs share the same 2–6 pixel range of motion; one extends as the other retracts.
- Avoid pauses, snaps, or timing holds—each frame receives equal duration.

| Frame | Left Leg Extension | Right Leg Extension |
| ----- | ------------------ | ------------------- |
| 1 | 6 px | 2 px |
| 2 | 5 px | 3 px |
| 3 | 4 px | 4 px |
| 4 | 3 px | 5 px |
| 5 | 2 px | 6 px |
| 6 | 3 px | 5 px |

If the walk feels steady, predictable, and even a bit boring, it is correct.
