# Arquitetura proposta

O protótipo usa Godot 4.7.2 padrão com GDScript e renderizador Compatibility. Bibliotecas e ferramentas de integração Android serão verificadas na fase própria.

## Componentes

- Godot 4 e GDScript para regras, cenas, interface e animações.
- Núcleo determinístico independente das cenas: estado, movimentos legais, aplicação do despejo, vitória, trancas, desfazer e pontuação.
- Definições de fases em JSON versionado, separadas dos textos traduzidos e dos recursos gráficos.
- Ferramenta de validação e solver executados durante a produção das fases, fora do fluxo normal do aplicativo.
- Serviços de salvamento, nuvem e anúncios acessados por interfaces; o protótipo pode usar implementações locais.
- Integrações Android em plugin próprio Java 17 para Google Play Games Saved Games e AdMob, com as APIs oficiais e versões fixadas na fase 5.

## Estado e persistência

Separar definição imutável da fase, estado atual, histórico de desfazer e conhecimento das cores descobertas. Salvar histórico suficiente para manter o desfazer disponível após retomar uma partida.

Salvar localmente uma partida da campanha única, com tempo decorrido, progresso concluído, recordes, preferências, tutoriais já vistos e contador de anúncios. Versionar o formato e prever recuperação de um salvamento incompleto por escrita atômica ou equivalente.

Na nuvem, sincronizar apenas progresso concluído e recordes. Partidas locais em andamento não participam da resolução de conflitos remotos. Preferências permanecem locais inicialmente.

As atualizações devem tratar identificadores e versões das fases para não restaurar um tabuleiro incompatível nem atribuir recordes antigos a uma fase diferente.

## Apresentação

A animação representa uma jogada já calculada pelo núcleo. Os grãos seguem posições e trajetórias controladas; simulação física de cada grão não decide as regras. Impedir comandos concorrentes que alterem o tabuleiro durante uma transferência.

O mascote recebe eventos de seleção, despejo, retorno inválido, vitória e ociosidade. O comportamento visual do mascote não controla a partida.

Textos usam chaves de localização. Cores usam identificadores de dados, associados à paleta e a símbolos/padrões de acessibilidade.

## Questões técnicas a resolver no protótipo

- Godot fixado em 4.7.2; ferramentas Android e integrações ainda serão escolhidas na fase própria.
- Medir custo do solver para capacidade 7 e trancas antes da produção das 150 fases.
- Ordem implementada: transferência, revelação, desbloqueios em cadeia, vitória; consultar regras e testes.
- Definir a quantidade máxima de frascos legível em telas pequenas e aparelhos de referência.
- Escolher plugins ou desenvolver pontes Android após uma verificação de compatibilidade.

Essas escolhas técnicas não exigem nova rodada de aprovação do produto, salvo impacto material na experiência ou no escopo.

## Experiência local implementada — fase 4B

ConfigStore grava um arquivo temporário, mantém o último arquivo válido em .bak e renomeia a nova versão para o destino. Progress continua lendo o formato anterior de resultados, acrescentando uma tentativa da campanha no schema local 2. Cada tentativa tem ID/revisão, regras, fingerprint e diário de ações; Rules reproduz os despejos e desfazeres, reconstruindo história, conhecimento e trancas sem confiar em um tabuleiro arbitrário do arquivo.

A gravação é imediata após cada operação lógica e não espera a animação. Uma vitória grava o recorde e remove a tentativa no mesmo commit. O carregamento rejeita operações ilegais e revisões incompatíveis e pode recuperar o backup quando o arquivo principal não está disponível. A versão gráfica da jogada não é persistida.

Localização usa JSONs offline para pt-BR, en e es-419, convertidos em Translation nativa. A troca recompõe os controles preservando o mesmo estado de jogo. Incluir os JSONs como arquivos não-resource na exportação Android. O treino básico e os exemplos de obstáculos usam instâncias independentes de Rules.

## Integrações implementadas — fase 5

`AndroidServices` isola o singleton Android do restante do jogo, com fallback sem serviços no desktop. `ServiceState` persiste a escolha de sincronização e o contador de anúncios em arquivo independente. Uma vitória registra a contagem uma única vez por tentativa; os botões do resultado pedem uma transição ao serviço, que continua a navegação ao fechar/falhar o anúncio. O contador só é consumido na exibição.

O plugin Android v2 próprio fica em `platform/android`, em Java 17, com AAR gerado e addon de exportação em `addons/arenis_android`. Implementa AdMob, consentimento UMP, dimensão real do banner e áreas de sistema, além de Play Games/Saved Games. O provider oficial prepara o SDK Play Games antes da Activity quando há ID de projeto configurado; a leitura e o envio dos resultados continuam condicionados à escolha de sincronização do jogador. Sem ID, o provider fica desativado e a função indisponível. Sem conexão ou anúncio, o jogo local continua.

`CloudRecords` valida e une somente resultados concluídos, por ID/revisão/regras. `Progress.merge_cloud` preserva tentativas e grava a união com o mesmo armazenamento atômico local. Maior estrela e menor recorde vencem; revisões antigas são arquivadas. Conflitos do snapshot retornam à mesma operação de merge. Há uma operação por vez, repetição quando ocorrem mudanças durante a operação e timeout. Dados desconhecidos/corrompidos não substituem o snapshot remoto.

Os SDKs e ferramentas estão fixados em [Android](android.md). Os scripts geram APK debug ou AAB release sem criar chaves de publicação. APK de desenvolvimento usa anúncios de teste; publicação e homologação real dos serviços permanecem pendentes.

## Jornada 0.6.0

Regras/schema 3, catálogo linear journey e IDs level-NNN substituem as dificuldades na campanha. `JourneyMap` compõe a tela inicial, enquanto `Desert` desenha um cenário vetorial sem assets externos. O mesmo modal limita a área de conteúdo e mantém ações da ajuda/treino fixas.

`Rules` mantém elapsed_seconds, timer_started e failed_reason. A cena avança tempo somente em jogo ativo, fora de animações, overlays e segundo plano. A primeira atualização após retomar é descartada para evitar cobrar um intervalo suspenso. A tentativa inclui tempo, além do diário; checkpoints de fases cronometradas ocorrem a cada segundo e nas ações/pausas.

O arquivo local é journey_progress.cfg e o snapshot nativo arenis_journey_v1, com documento de nuvem schema 2. Essa separação é o reset da beta explicitamente autorizado; nenhuma migração dos resultados antigos é tentada. Preferências e estado de serviços continuam separados. As testemunhas de soluções são apenas entradas de ferramentas offline e não são usadas para dar dicas no produto.
