# Revisão do final do som de areia

Data: 12/11/2026. Continuação da fase 4 em `C:\git-workspace\arenis-mobile-game`.

## Alteração

O timbre aprovado e o arquivo `sand.wav` foram preservados. O ajuste acontece na reprodução:

- O fluxo sonoro diminui progressivamente junto dos últimos grãos, antes de a animação terminar.
- Após a animação, permanece uma cauda de **500 ms**, cuja amplitude chega suavemente a zero antes de parar o player.
- A cauda continua durante o assentamento e a apresentação do resultado, sem atrasar a vitória ou a próxima ação.
- Uma nova transferência cancela o encerramento anterior e inicia seu próprio som. Desfazer usa o mesmo comportamento. Desativar efeitos continua silenciando imediatamente.

O encerramento anterior fazia uma queda rápida em decibéis, percebida como corte. A nova curva reduz a amplitude de forma suave, partindo do fluxo restante. O volume configurado pelo usuário continua multiplicando essa curva; mudar a preferência não restaura o fluxo ao volume cheio.

`scripts/main.gd` comunica a evolução do fluxo a `scripts/audio.gd`. O núcleo, as jogadas, os mínimos, as estrelas e o progresso não foram alterados. Nenhum arquivo pessoal de configurações ou resultados foi modificado pelos testes.

## Verificação

**3.232 verificações e seis cenários de CLI passaram, sem falhas.** A nova suíte `tests/sand_ending_test.gd` contém 13 verificações: diminuição antes do fim; respeito ao volume; ausência de parada imediata; cauda ainda audível durante a redução; proteção contra atualização de fluxo após início do encerramento; nova jogada cancelando a cauda anterior; ausência de parada atrasada na nova jogada; término silencioso; mute imediato; continuidade na jogada de vitória e parada posterior.

O WAV de 2,1 segundos comporta a transferência mais longa e a cauda inteira. Os testes exercitam a reprodução no Godot e a última transferência real do protótipo, verificando que a vitória continua aguardando a animação visual e que o som permanece em encerramento depois dela. A aprovação subjetiva desse final fica para a experiência do usuário no jogo; ouvir o WAV isolado não reproduz a curva aplicada em tempo de execução.

Alterações locais, sem commit ou push. Para continuar a fase 4, permanece indicado **GPT-6.1 Sol, raciocínio Alto**.
