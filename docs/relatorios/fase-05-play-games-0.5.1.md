# Fase 5 — Login e restauração no segundo aparelho, versão 0.5.1

Concluído em 19 de novembro de 2026. Investigação iniciada em 18 de novembro.

## Resultado

A restauração foi observada no segundo aparelho, Samsung SM-A530F com Android 9 (API 28): 19 níveis fáceis concluídos, total de 56 estrelas, regras versão 2 e fases revisão 1. O app exibiu Progresso sincronizado. A versão 0.5.1 foi instalada por USB como atualização do mesmo pacote, preservando os resultados. Após abrir a nova versão, a tela inicial mostrou 19 concluídos e a tela de conta e privacidade novamente mostrou Progresso sincronizado. Um banner adaptativo com anúncio de teste do Google foi observado.

## Diagnóstico e correções

A ponte registrou sign_in / not_authenticated e o serviço Google devolveu SIGN_IN_REQUIRED com uma resolução pendente. O SDK era inicializado somente ao ativar a sincronização, após a criação da Activity. Após enviar o app para Home, retomá-lo e repetir a sincronização, a Activity Google de login abriu. O usuário escolheu a conta. Na sequência os registros remotos apareceram no salvamento local. Essas evidências sustentam a correção do ponto de inicialização, sem atribuir todo erro de autenticação possível à mesma causa.

Foi restaurado o provider oficial PlayGamesInitProvider, com initOrder 99, habilitado pelo recurso booleano arenis_games_configured somente quando há ID numérico diferente de zero. Assim o SDK registra o ciclo de vida antes da primeira Activity. A criação automática de novos perfis segue suprimida; um perfil existente pode ser reconhecido automaticamente pelo Google. A leitura e o envio de resultados continuam condicionados à opção Sincronizar progresso.

A atualização visual também foi corrigida: resultados recebidos com as configurações abertas marcam a tela de níveis para atualização após o fechamento do menu. Isso atualiza contadores, estrelas e bloqueios sem interromper o modal atual nem reiniciar uma partida ativa. A substituição entre os dois menus não dispara uma reconstrução sobre o novo modal.

O APK de diagnóstico agora usa o atributo debuggable do Android para decidir a exibição de detalhes e consulta diretamente o método da ponte para ler a etapa/código. Detalhes não incluem contas, tokens, mensagens de exceção ou conteúdo do progresso.

A versão passou de 0.5.0 (5) para 0.5.1 (6). Não houve alteração de pacote, assinatura, formato de salvamento, regras, campanha ou pontuação.

## Validação

- 4137 verificações em 17 suítes e seis cenários CLI, sem falhas.
- Serviços Android: 57 verificações; fluxo Android: 17 verificações. Novos casos cobrem diagnóstico oculto em release, manutenção do modal durante restauração, troca de modal, atualização das contagens/estrelas/liberação do próximo nível e preservação de uma partida ativa.
- Plugin nativo e APK compilados. Assinatura, pacote, versão, três idiomas, 150 fases e ARM64 inspecionados. Diretórios de desenvolvimento ausentes do APK.
- Manifesto confirma provider oficial com ativação por recurso booleano, initOrder 99 e supressão de criação automática de perfil. O recurso compilado está true para o projeto configurado.
- Atualização real via adb install -r concluída. Um primeiro comando encontrou autorização USB temporariamente indisponível; a conexão voltou a device antes da repetição bem-sucedida. Não foi feita desinstalação.
- Dados locais copiados para uma pasta temporária antes da atualização; nenhum arquivo de conta Google foi coletado. Registros e 56 estrelas conferidos após a atualização.
- Processo da nova versão sem erros Godot, AndroidRuntime ou ArenisCloud no período de abertura observado.
- Capturas locais conferidas: arenis-0.5.1-home.png e arenis-0.5.1-synced.png, em C:/Users/Renan/AppData/Local/Temp/arenis-device-diagnostics/.
- O diagnóstico detalhado Games foi devolvido a INFO no aparelho.

## Privacidade e publicação

A política em português, inglês e espanhol foi atualizada para explicar a preparação do SDK na abertura e a possível identificação automática de perfil existente, mantendo o backup opcional. Cinco páginas e 78 links foram validados. Apenas seis arquivos do site/geração/validação foram publicados no commit c734be6. Workflow concluído: https://github.com/renan-alves/arenis-mobile-game/actions/runs/44448474892 . As três políticas foram verificadas por HTTPS, com HTTP 200 e a data 2026-11-19. Dados do aparelho e código do jogo não foram enviados nesse commit.

## Limites e próximos passos

O teste final da 0.5.1 utilizou o perfil que o usuário já havia conectado durante a investigação. A abertura de login para um perfil totalmente novo não foi repetida após a correção, pois isso exigiria outro ambiente ou alterar o perfil existente. Resolução de conflitos reais entre dois aparelhos, comparação individual das melhores jogadas, falhas de rede, intersticiais e configuração final de produção continuam pendentes. A fase 5 inteira não é declarada concluída apenas por este teste.

## Artefato

build/android/arenis-play-games-0.5.1-debug.apk — 251440810 bytes.

SHA-256: 20ab16d2e39c80354bf598cd30caa7d50b9d0e57d9603b004cf7e9fb76071dd3.

Referências: https://developer.android.com/games/pgs/android/android-signin e https://developer.android.com/games/pgs/android/troubleshooting . Evidências estruturadas: fase-05-play-games-0.5.1.json.
