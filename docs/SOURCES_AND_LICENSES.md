# Sources and licences: where every part of the game comes from

Purpose: to be able to show, for every file and every piece of code, who or what made it, when, under which terms, and that nothing
was copied from someone else. Written by Claude Code on 2026-11-13 from what the repository and the working sessions show. **Claude is not a lawyer
and cannot check the live terms of a service: the "Open points" below must be confirmed by the owner before release.**
The per-file table for images is in `docs/ASSETS.md`; this file is the overview and the record for audio.

## 1. Rules for this project
1. Every asset is either made by the owner, made by an AI tool under a licence that allows commercial use, or taken from a source with a licence that is saved here (name, URL, date, licence text).
2. No asset is copied from another game, film, website or artist. Prompts never ask for "in the style of" a named artist, game or franchise.
3. Every new file gets a row in `docs/ASSETS.md` (file, tool, date, prompt) and, for audio, the generation id (section 3).
4. Keep the original downloads (`docs/sound-originals/`) and the account invoice for the month each asset was made.
5. AI-generated content must be declared in the Steam "AI content" disclosure (images, audio and code were AI-made or AI-assisted).

## 2. Overview
| Part | Made with | Terms that apply | Status |
|---|---|---|---|
| Code (`scripts/`, `shaders/`, `scenes/`) | Claude Code (Anthropic), AI-assisted, owner directing | Anthropic's terms for the owner's account; no third-party code was pasted in on purpose | Open point A |
| Engine | Godot 4 (MIT licence) | The Godot licence text and copyright notices must ship with the game (credits screen or a licence file) | Open point B |
| Images (`assets/`) | Gemini (Google) image generation; some placeholders drawn with a Python (PIL) script; two tiles with an unrecorded tool (probably Gemini) | Google's terms for the owner's account at the time; see `docs/ASSETS.md` | Open point C |
| Sound effects (`audio/`) | ElevenLabs Sound Effects (model `eleven_text_to_sound_v2`) through the ElevenLabs MCP / ElevenCreative flows | ElevenLabs terms for the owner's plan; paid plans include a commercial licence except for "Beta Services" | Open point D |
| Audio conversion | Blender 5.2 (its built-in audio library `aud`), used only to convert mp3 to ogg and trim | Blender is GPL; converting files with it does not put its licence on the output | none |
| Music (`audio/music_day.ogg`) | ElevenLabs Music, model `eleven_music_v2_5`, instrumental, 90 s, generation `aMVqKY2qjnLlblDIXCGf` in flow `12UlhMkJOxlP0Emyffj7`, 2026-11-13 | ElevenLabs Music Terms: per the notes saved in the Mobile-Game repository, the Starter plan allows commercial use in games that are not "Studio Games" (indie games are not), with no streaming of the music; confirm the plan (Open point D) | Open point D, G |
| Fonts | none (Godot's default font, shipped with the engine) | | check when custom fonts are added |

## 3. Audio: how each file was made
All files in `audio/` were generated on **2026-11-13** in one ElevenCreative flow: <https://elevenlabs.io/app/flows/12UlhMkJOxlP0Emyffj7> (flow id `12UlhMkJOxlP0Emyffj7`,
named "Make My Wife Happy SFX"), model `eleven_text_to_sound_v2`, one take each, requested through Claude Code with the owner's account. The mp3 originals are kept in
`docs/sound-originals/<id>_elevenlabs_2026-11-13.mp3`. The game plays the `.ogg` files (mono, Vorbis 96 kbps, trimmed to the length in the last column, with a short fade-out;
`work_loop` is untrimmed and loops). Nothing was sampled from a recording, game or film; each sound comes only from the text prompt.

| File | Generation id | Prompt sent (verbatim) | Length used |
|---|---|---|---|
| `pickup.ogg` | `vDzplmx7hijrNfW4I8gk` | Cartoon pop of picking up an object: a quick light bouncy "bloop" with a tiny rising whoosh, playful casual game sound, very short, dry, no music. | 0.4 s |
| `drop.ogg` | `nlepz8srQU2E3HceHWqb` | Cartoon sound of setting an object down on the floor: a soft cute "thup" with a tiny falling tone, playful casual game sound, very short, dry, no music. | 0.35 s |
| `step_done.ogg` | `1XoBQFcO3OSb0bFitiXF` | A short cheerful two-note "ding-ding" confirmation chime with a sparkle, bright and bouncy, casual cooking game task step done, no music. | 0.7 s |
| `quest_new.ogg` | `HJ6poDM1jxfPIsNkimOn` | A new order ticket arriving in a casual cooking game: a paper printer tear with a bright attention "ting" bell, playful and urgent but friendly, no music. | 1.1 s |
| `quest_complete.ogg` | `qwHryuGDx8MtmLgo48RN` | Triumphant task complete jingle: a happy rising three-note fanfare with a cash register "cha-ching" and a little sparkle, cheerful cartoon casual game success sound, 1.5 seconds, no music bed. | 1.0 s |
| `quest_failed.ogg` | `WSQrolyg5ThNcsaQIAFs` | A funny cartoon failure sound: a sad descending "wah-wah" trombone with a small comedic splat, casual game task failed, 1.2 seconds, no music bed. | 1.5 s |
| `coin.ogg` | `g3pOxtFWcZn2iVLRofKb` | A single gold coin collected in a casual game: a bright metallic "ting" with a short bouncy sparkle, very short, no music. | 0.6 s |
| `wife_happy.ogg` | `bAJmZ7ApGuUmitwiWXAu` | A woman's happy delighted giggle and a pleased "mmm", warm, short, cartoonish but natural, cheerful sitcom feel, no words, no music. | 1.4 s |
| `wife_angry.ogg` | `3bhzIaD0YXttU7r9ay55` | A woman's annoyed exasperated groan and an angry "hmph" with a sharp sigh, comedic sitcom feel, short, no words, no music. | 1.4 s |
| `meter_warning.ogg` | `q8ypIqCssfn5S8XTUjs8` | A gentle, soft reminder tone for a game: two warm rounded low marimba notes, slow and soft, a mellow wooden "bom-bom" with a quiet gentle fade, calm and friendly, pleasant to the ear, no sharp or harsh sounds, no alarm, no beeping, very quiet and smooth, no music. (node settings: duration 1.5 s, prompt influence 0.5; generated 2026-11-13, replaces the first, harsher take `KGgwMrPIOhjzg5bRmNtv`, prompt: "A tense urgent warning pulse for a game: two quick low heartbeat thumps with a short rising alarm blip, anxious but not scary, one cycle, no music.", which is no longer in the repository) | 1.48 s |
| `step_wood.ogg` | `KNwrFrd5xkPvQ1uFQepu` | One soft footstep of sneakers on a wooden floor indoors, light and slightly cartoonish, very short, dry, no music. | 0.3 s |
| `day_win.ogg` | `Kg6LF2D6bOyiJHI8VES4` | Victory fanfare for finishing a day in a cheerful cartoon game: bright trumpets and bells, rising cheerful melody ending on a big happy chord with confetti pop, 3 seconds, no vocals. | 3.2 s |
| `game_over.ogg` | `Yk0F5RwqIw0f0fagAr2f` | Comedic game over sting: a slow descending sad trombone "wah wah wah waaah" with a cartoon deflating sound, 2.5 seconds, no vocals. | 2.0 s |
| `ui_click.ogg` | `iXXhbEjRzmTZgRMNah3s` | A soft friendly menu button click for a casual cartoon game, a tiny wooden "tock" with a light pop, very short, no music. | 0.25 s |
| `work_loop.ogg` | `8pW521B38zoskYDbBwQD` | (the same flow node as `ui_click`, re-run with loop on, 2 s) A cheerful busy household chore working loop: light rhythmic scrubbing and tapping with a soft bubbly bouncy cartoon texture, steady and repeating, casual game action in progress, not too loud, no music. | 2.25 s |

Notes: "trombone" and "cha-ching" describe generic sound types, not a named song or game. The wife sounds are synthetic effects made by the tool from the text, not a recording of a
real person and not a cloned or named voice.

## 4. Open points (the owner must confirm; Claude cannot)
- **A. Code:** the code is AI-assisted (stated in `docs/ASSETS.md`). If any third-party code or library is added, add its name, URL and licence here first.
- **B. Godot licence:** add the Godot MIT licence text and the third-party notices (`Engine.get_license_text()` and `Engine.get_copyright_info()`) to an in-game credits screen or a `LICENSES.txt` that ships with the build.
- **C. Images:** for each Gemini image keep the prompt (already in `docs/ASSETS.md`) and the date, and confirm in Google's terms that generated images may be used commercially in a game on the owner's account type; save the terms page (the Gemini notes of the Mobile-Game repository, `docs/ASSETS.md` section 6, show how it was done there). The two tiles whose tool was not recorded (`floor_wood.png`, `grass.png`) should be re-made or the tool confirmed. The item icons drawn with the PIL script are placeholders to be replaced.
- **D. ElevenLabs:** (1) Which plan the account was on on 2026-11-13. The Mobile-Game notes record a Starter plan bought 2026-11-03; confirm it was still an active **paid** plan, because on the Free plan sound effects are personal use only. (2) These sounds were made through ElevenCreative flows (the MCP), not the Sound Effects page: confirm in ElevenLabs' current terms that this product is not a "Beta Service", which is excluded from the commercial licence. (3) Save the invoice and the terms page with the date. The proofs already saved for the same account are in the other repository: `docs/legal-proofs/ElevenLabs_terms-notes_2026-11-03.md` and the screenshots next to it.
- **G. Music:** `music_day.ogg` was made with this prompt (verbatim): "Pleasant, warm and light instrumental background music for a cozy casual household-chores game: gentle plucked ukulele and soft marimba melody over a relaxed bouncy rhythm with light brushed percussion and a soft upright bass, sunny and friendly, easygoing, slightly playful, loop-friendly with a steady groove and no big build-ups or sudden changes, mellow volume dynamics, around 100 bpm. No vocals." (instrumental on, 90 s, 1350 credits). The original mp3 is `docs/sound-originals/music_day_elevenlabs_2026-11-13.mp3`; the ogg is stereo Vorbis 128 kbps with a 30 ms fade-in. The ElevenLabs music licence is more limited than the sound-effects one (the notes in the Mobile-Game repository record: no streaming of the music on its own, not for "Studio Games", and a size limit for "Indie Game" status); re-check it before release and replace the track if the game outgrows it. Do not upload the soundtrack on its own to Spotify or similar.
- **E. Steam:** declare AI-generated art, audio and code in the Steam AI disclosure.
- **F. Similarity:** keep the game original (a chores game where a wife hands out tasks, in the spirit of the cooking-chaos genre, not a copy of one game). Do not use names, characters, music or art of another game.
