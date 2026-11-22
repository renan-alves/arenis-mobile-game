# Fontes do efeito de areia em vidro

As páginas abaixo declaram licença **CC0 1.0**: https://creativecommons.org/publicdomain/zero/1.0/

## Ampulheta — fonte principal

- Gravação: **Turning a Small Hour Glass.wav**, de **el_boss**, publicada em 28/03/2022.
- Página: https://freesound.org/people/el_boss/sounds/625655/
- Prévia pública preservada em `hourglass-625655.mp3`: https://cdn.freesound.org/previews/625/625655_9129912-hq.mp3
- SHA-256: `2d3c5cd4c1c40378bd7fa94ae6dd168f48a058c35dc9e47fa0a000b0f6bd31e8`.
- Trecho usado: 7,0–9,1 s, mono, filtro passa-altas em 300 Hz e passa-baixas em 8,5 kHz, ganho 0,8.

## Areia sobre vidro — camada secundária

- Gravação: **sand pour on glass FF675.aif**, de **martinimeniscus**, publicada em 11/09/2013.
- Página: https://freesound.org/people/martinimeniscus/sounds/199361/
- Prévia pública preservada em `sand-on-glass-199361.mp3`: https://cdn.freesound.org/previews/199/199361_2320755-hq.mp3
- SHA-256: `9cf74a6ac1ebfa3e9cbf85baffc6c92bc75031a661161f1e07e41cd1b534196b`.
- Trecho usado: 6,6–8,7 s, mono, filtro passa-altas em 1,5 kHz e passa-baixas em 6,5 kHz, ganho 0,05.

`tools/prepare_sand_audio.py` verifica as fontes e mistura as camadas, aplicando entrada de 120 ms e saída de 250 ms. O resultado é `assets/audio/sand.wav`. A reprodução no app reduz o fluxo sonoro junto dos últimos grãos e usa uma cauda de 500 ms após a animação, suavizando a amplitude até zero. A gravação aprovada foi preservada.

## Fonte histórica preservada

`sand-pour-199332.mp3` pertence ao efeito anterior de areia sobre areia, de martinimeniscus: https://freesound.org/people/martinimeniscus/sounds/199332/ (CC0).

SHA-256: `819a0c32f19ce02a3d6728f9521028d60e47b3b2984b8ab16096a7d63d3c1296`. Este arquivo não participa da mistura atual.

A pasta é excluída da importação Godot por `.gdignore`. O jogo depende somente do WAV preparado; FFmpeg é necessário apenas para refazer o processamento offline.
