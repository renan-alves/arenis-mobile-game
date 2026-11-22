# Áudio Arenis

- `sand.wav`: mistura tratada de uma gravação de ampulheta pequena de **el_boss** com uma camada discreta de areia sobre vidro de **martinimeniscus**, ambas CC0. Fontes: [ampulheta](https://freesound.org/people/el_boss/sounds/625655/) e [areia sobre vidro](https://freesound.org/people/martinimeniscus/sounds/199361/).
- `tap.wav`: toque curto original, sintetizado para o projeto.
- `complete.wav`: três notas suaves originais para a conclusão.

O efeito busca a textura de areia fina caindo dentro do vidro. A ampulheta fornece o corpo sonoro; o contato com vidro entra filtrado e em ganho baixo. O volume diminui junto do fim do fluxo; depois da animação, uma cauda de 500 ms chega gradualmente ao silêncio. O controle de volume configurado continua sendo respeitado.

`tools/prepare_sand_audio.py` verifica os hashes das duas fontes, recorta e filtra as camadas e prepara `sand.wav`. Fontes e créditos estão em `tools/audio_sources/`, excluída da importação Godot. FFmpeg é necessário apenas na autoria; o aplicativo usa o WAV pronto. `tools/generate_audio.py` gera somente toque e conclusão.

Formato do jogo: PCM mono, 22.050 Hz e 16 bits. Não há música. As verificações usam preferências temporárias.
