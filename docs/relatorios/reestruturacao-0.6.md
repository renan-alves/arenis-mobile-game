# Reestruturação — jornada 0.6.0

Executada em 22/11/2026 no repositório oficial `arenis-mobile-game`, a partir das seis considerações aprovadas. A autorização inclui desconsiderar progresso anterior da beta e auditar todas as telas.

## Entrega

- Destino vazio ou com a mesma cor no topo. Despejos parciais permanecem válidos. Desfazer continua contando uma jogada.
- Campanha única: 150 níveis sequenciais, sem seletor de dificuldade, com mapa e ação Jogar/Continuar. Numeração e textos em pt-BR, inglês e es-419.
- Dificuldade crescente, de 3 a 11 tubos e capacidades de 3 a 7 unidades, até nove cores. Todos os tabuleiros foram refeitos e certificados nas regras 3.
- Fases livres intercaladas com limite de jogadas a partir do nível 16 e tempo a partir do 48. Nenhuma fase combina ambos. Areia escondida começa no 26; trancas combinadas no 61.
- Vitória na última jogada permitida vale. Cronômetro só começa na primeira jogada válida e pausa durante animações, menus, apresentações e segundo plano. Tempo fica salvo com a tentativa; desfazer não devolve tempo.
- Novas tentativas sem limite de vidas. Estrelas continuam por eficiência: três até 20% acima do mínimo, duas até 50%, uma por concluir.
- Fundo vetorial de deserto com paletas próprias; tubos translúcidos, reflexos, borda da boca e sombra discreta. Mascote e áudio aprovados preservados.
- Mapa com rolagem intencional e marcador de fase bloqueada. Menus adaptativos só rolam quando há excesso real; ajuda e treino mantêm ações visíveis. Ajustes finais deixaram o indicador de rolagem discreto e eliminaram o tabuleiro aparecendo atrás dos textos dos menus.

## Provas e validação

A campanha contém 65 fases livres, 74 com limite de jogadas e 11 cronometradas. Os mínimos variam de 3 a 25 jogadas.

O gerador Python propôs tabuleiros e testemunhas. O solver Godot verificou as testemunhas, esgotou os estados de custo inferior e reproduziu as soluções no núcleo real, com limites habilitados. Uma primeira rodada atingiu o orçamento de busca no nível 142; esse tabuleiro foi substituído por outro candidato, mantendo as 149 provas já aceitas somente quando o fingerprint coincidia. A substituição também foi comprovada. Não foi aceito mínimo por estimativa ou por encerramento da busca.

Evidências: [150 certificados](jornada-v3-provas.json), [mínimos, estrelas e orçamentos](jornada-v3-niveis.csv), [resultado estruturado](reestruturacao-0.6.json).

A execução final de `tools/check.ps1` passou: **7.386 verificações em 19 suítes, zero falhas**, mais **seis cenários CLI**. Inclui correspondência de cores, rejeição sem gasto, despejos parciais, última jogada, desfazer, tempo/restauração/pausas, certificados, busca comparada com BFS independente, nuvem/conflitos, traduções, animações e persistência. A nova auditoria percorreu mapa, quatro densidades de tabuleiro, menu da fase, reinício, configurações, conta, ajuda, treino, cinco apresentações, resultado e falha, nos três idiomas e nos dois temas.

A renderização gráfica foi capturada pelo próprio Godot/OpenGL em uma janela oculta, sem capturar a área de trabalho. As imagens em [jornada-0.6](imagens/jornada-0.6/map-light.png) foram inspecionadas para composição, legibilidade e limites da área útil. Capturas desktop usam a simulação de banner e o fallback sem Play Games, não representam teste nativo.

## Reset autorizado e sincronização

O novo arquivo `journey_progress.cfg`, regras 3, documento de nuvem schema 2 e snapshot `arenis_journey_v1` impedem importar resultados da campanha beta anterior. Os arquivos/snapshots antigos não são apagados nem mesclados à jornada. Preferências e escolha de sincronização permanecem; o treino das novas regras volta a aparecer.

Testes de lógica verificam merge, preservação da tentativa, ausência de regressão em estrelas/recordes e sincronização automática de conclusões. A nova versão foi conferida em um aparelho, inclusive com restauração real da nuvem após separar os arquivos locais. A validação entre dois dispositivos com a mesma conta permanece pendente.

## APK

Arquivo: `build/android/arenis-journey-0.6.0-debug.apk`, pacote `com.frontmakers.arenis`, versão 0.6.0, código 7. Android 7/API 24 ou superior, target 36, ARMv7/ARM64/x86_64. Assinatura verificada, 150 fases e três idiomas presentes. Build com anúncios de teste.

SHA-256: `257097f33e02f95965126f12d8f4ae2e606a4be7ed9be5858de215ddbb7be97a`. Tamanho: 251,518,152 bytes.

A compilação continua emitindo o aviso conhecido do AGP 8.6.1 sobre compileSdk 36; o build passou e o aviso não foi ocultado. Não foi criada chave de publicação nem AAB release.

## Site e repositório

Página inicial e política em três idiomas atualizadas para a campanha e persistência de tempo. A publicação do site passou no workflow 45082600182, commit d6edb47. Página inicial e privacidade responderam HTTP 200 com os novos textos. Nenhuma credencial, configuração local ou chave de assinatura integra essa publicação.

O código do jogo estava apenas no checkout local; a entrega inclui o fonte e as evidências no repositório oficial. Foram conferidos 409 arquivos, sem achados nos padrões de segredos; builds, configurações privadas e material de assinatura foram excluídos e sua regra de ignore foi verificada.

## Validação no celular — concluída nesta sessão

APK instalado no **Samsung Galaxy A8 (SM-A530F), Android 9/API 28, tela 1080 × 2220**. A conexão USB inicialmente perdeu autorização e a transferência direta do APK falhou. O envio em blocos de 8 MiB funcionou; o arquivo foi reunido no aparelho e seu SHA-256 conferido antes da instalação. A versão instalada é 0.6.0, código 7. A abertura foi feita pela Activity pública GodotAppLauncher. Não houve mudança no APK para esse procedimento.

Conferidos no aparelho: mapa, temas claro/escuro, banner adaptativo de teste, configurações, conta, treino inicial completo, ajuda, menu, confirmação de reinício e resultado. As configurações foram abertas em português, inglês e es-419. O espaço do banner e as barras do Android ficaram separados da interface útil.

O despejo em cor diferente foi rejeitado sem registrar jogada; o Nível 1 terminou em três jogadas e recebeu três estrelas. O Nível 2 foi liberado. Nele, um despejo seguido de desfazer registrou ambas as ações e exibiu duas jogadas. O reinício confirmado zerou a tentativa.

**A restauração nativa da nuvem foi confirmada.** Após sincronizar a conclusão, o app foi encerrado e ambos os arquivos locais da jornada foram separados, com cópias de segurança. Na nova abertura, o Play Games restaurou o Nível 1 com três estrelas e recorde de três jogadas no snapshot arenis_journey_v1. Isso valida envio e recuperação reais em um aparelho; não substitui o teste de dois aparelhos ou de conflito simultâneo.

As consultas de logs foram limitadas ao processo do Arenis e aos erros Godot/AndroidRuntime e avisos ArenisCloud, sem erros encontrados nessas categorias nas verificações finais. Não foi feita avaliação auditiva dos efeitos nem medição formal de desempenho.

Estado final no celular: **Nível 1 concluído com três estrelas; Nível 2 liberado, tentativa com zero jogadas**. Tema e idioma voltaram a seguir o sistema. Configurações locais de conta foram preservadas. Arquivos temporários do envio e cópias auxiliares no aparelho foram removidos após confirmar a recuperação; cópias de segurança locais ficam em tmp, fora do Git.

Evidências do aparelho: [mapa final](imagens/jornada-0.6/android/final-home.png), [resultado](imagens/jornada-0.6/android/first-win.png), [sincronização](imagens/jornada-0.6/android/after-win-synced.png), [mapa restaurado da nuvem](imagens/jornada-0.6/android/cloud-restored-map.png) e configurações em [inglês](imagens/jornada-0.6/android/settings-en.png) e [es-419](imagens/jornada-0.6/android/settings-es-light.png).

## Pendências práticas

Validar a nova jornada entre dois aparelhos e conflitos simultâneos de snapshots. Fases avançadas, limites e obstáculos passaram nos testes automatizados/desktop; esta sessão no celular percorreu os dois primeiros níveis e os menus principais. O intersticial nativo e anúncios de produção não foram exercitados nesta sessão.

Ajustar a curva e os orçamentos conforme o uso: prova de solução garante legalidade/mínimo, não a dificuldade percebida. Configuração final da loja, assinatura release e publicação continuam etapas separadas.
