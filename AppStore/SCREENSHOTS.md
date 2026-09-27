# Lift Relay screenshot system

Use real UI from a seeded demo account and photograph believable adult gym users. Do not show invented ratings, awards, testimonials, live availability, or outcome claims. Keep skin texture, clothing, equipment wear, lighting, and body proportions natural.

## Layout system

- iPhone: compose master artwork at 1320 × 2868, with type and critical UI inside a 72 px safe margin.
- iPad: recompose rather than scaling; use a 4:3 scene with the device/UI taking 55–65% of the frame.
- Use the acid-lime Lift Relay accent against charcoal, warm white, and real gym neutrals.
- Headline: no more than two lines, upper-left aligned, with a strong 7–9 word maximum.
- UI must remain legible and correspond to functionality in the submitted build.
- Localise typography and line breaks per storefront; mirror composition for Arabic.

## Seven-frame story

1. **THE GYM IS BUSY. YOUR WORKOUT ISN'T OVER.** An ordinary after-work gym user beside occupied racks; overlay the Equipment Unavailable action.
2. **SWAP EQUIPMENT. KEEP YOUR TRAINING ON TRACK.** Close crop of the recommendation sheet showing Best Match and the plain-language explanation.
3. **REBUILD TODAY'S WORKOUT IN SECONDS.** Relay Mode comparison: Barbell Back Squat to Goblet Squat, Cable Row to One-Arm Dumbbell Row.
4. **LOG SETS WITHOUT TOUCHING YOUR PHONE.** A user finishing a real set; overlay “Log eight reps at eighty kilos” and the visible confirmation card.
5. **ONLY 20 MINUTES? MAKE THEM COUNT.** Time Rescue with a condensed three-movement session; label the duration as estimated.
6. **TRACK WHAT YOU ACTUALLY TRAINED.** History showing Planned: Barbell Bench Press and Performed: Dumbbell Bench Press.
7. **DIFFERENT GYM. SMARTER WORKOUT.** Home Gym, Work Gym, and Hotel Gym cards with distinct equipment lists.

## Image-generation prompts

Use these as photographic background prompts, then composite real captured product UI separately so the interface is never hallucinated.

- **Busy commercial gym:** “Documentary fitness photography, diverse adult recreational lifter in normal training clothes, standing calmly near visibly occupied squat racks in a credible commercial gym at 6pm, mixed body types, natural overhead lighting, realistic equipment wear, subtle depth of field, room for headline in upper left, no logos, no text, no phone screen, not a bodybuilding advertisement.”
- **Voice logging:** “Candid side view of an adult gym user immediately after a challenging but controlled dumbbell bench set, phone safely on nearby bench stand, believable exertion, ordinary athletic build, busy background softly out of focus, natural skin texture, no text or logos, negative space on left.”
- **Hotel gym:** “Realistic compact hotel gym in morning light, adult traveller in simple training clothes adapting a workout with dumbbells and a small cable station, limited equipment clearly visible, calm premium editorial photography, no logos, no text, no exaggerated physique.”
- **Independent gym:** “Warm documentary photograph inside a small independent strength gym, mixed-age adults training, one user checking available equipment without blocking others, authentic plates and benches, human and approachable, no text, no brand logos, no staged influencer pose.”

## Export checklist

- Capture light and dark mode, Dynamic Type at default and one larger size, and one Arabic RTL pass.
- Remove all personal data; use deterministic demo history.
- Verify every displayed feature ships in the reviewed binary.
- Export sRGB PNG/JPEG with no transparency and validate exact sizes in App Store Connect.
