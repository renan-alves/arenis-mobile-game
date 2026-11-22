# Fase 5 — APK para teste real de Play Games

Data: 18 de novembro de 2026.

## Resultado

O usuário informou ter criado e vinculado a credencial Android no Play Console. O arquivo local platform/android/services.local.properties agora usa o projeto Play Games 471459189605, mostrado nas capturas da conta, no lugar de zero. O arquivo permanece ignorado pelo Git, com production=false. Não foram solicitadas ou publicadas senhas, chaves privadas ou tokens.

Foi gerado um APK separado, build/android/arenis-play-games-debug.apk, preservando o APK anterior. Pacote com.frontmakers.arenis, versão 0.5.0 (5), assinatura de debug existente. Os anúncios continuam usando os três IDs de teste oficiais do Google.

## Verificação

- Ponte nativa compilada; BuildConfig confirma GAMES_CONFIGURED=true e IDs de banner/intersticial de teste.
- Exportação Godot concluída.
- Assinatura APK válida, SHA-1 26:2B:BE:94:4C:11:51:FE:6B:B8:B2:5A:68:0B:3F:F6:0E:D8:88:A1, igual ao fornecido no cadastro Android.
- Recursos do APK contêm arenis_games_project_id e o valor 471459189605; manifesto contém metadados APP_ID do Games e app ID AdMob de teste.
- Campanha com 150 fases, três idiomas, ARM64 e exclusão de diretórios de desenvolvimento verificados.
- Apenas configuração local e documentação alteradas; nenhuma mudança da lógica. Suítes de regras não foram repetidas para essa troca de ID.
- Nenhum aparelho conectado ao adb. Autenticação, consentimento, anúncios e sincronização remota ainda precisam de execução no celular.
- Avisos já existentes: AGP 8.6.1 com compileSdk 36 e uso de API Java obsoleta; compilação passou.

## Ações no Console e teste

1. Ativar Jogos salvos em Configuração → Editar propriedades e salvar. Confirmação do usuário pendente.
2. Adicionar a conta usada no celular em Play Games Services → Configuração e gerenciamento → Testadores. Confirmação pendente. Se o OAuth estiver em modo Teste, incluir também essa conta nos usuários de teste do OAuth.
3. O Google informa até 24 horas para ativar Jogos salvos e algumas horas para novos testadores acessarem o serviço.
4. Instalar o novo APK como atualização e abrir Configurações → Conta e privacidade → Sincronizar progresso. Confirmar login e sincronização dos resultados concluídos; conferir restauração em outro aparelho com a mesma conta, sem apagar a instalação original.
5. Branding OAuth, credencial Play Store, release AAB e publicação do jogo permanecem etapas futuras. A tentativa de análise anterior não foi enviada por estar em desenvolvimento.

APK: 251439750 bytes. SHA-256: 12c5dfa32a14d2effd461febb42bb4ff9f3949729f40c3a0cc48cb8b7566a3b5.

Evidências em fase-05-play-games-teste.json.

Fontes: https://developer.android.com/games/pgs/console/enable-features e https://developer.android.com/games/pgs/console/publish .

## Validação manual no celular — 18 de novembro de 2026

O usuário instalou o APK vinculado ao Play Games. Uma tentativa inicialmente apresentou falha genérica. Posteriormente informou: “Agora deu certo. O progresso foi sincronizado”. Esse sucesso ocorreu no APK já instalado, antes da entrega de qualquer alteração de diagnóstico; portanto não se atribui o sucesso a uma correção de código. A causa da primeira falha não foi determinada. Autenticação e sincronização foram confirmadas por relato do teste manual; restauração em outro aparelho e resolução de conflitos reais permanecem pendentes.

Durante a investigação foi identificado independentemente um risco de leitura remota antes do término do login quando o aplicativo retoma a partir da interface Google. Uma correção preventiva e diagnóstico limitado a etapa/código estão sendo validados separadamente. Não há necessidade de instalar uma versão de diagnóstico para continuar usando o APK que já sincronizou.

## Atualização — restauração comprovada

Em 18–19 de novembro, a restauração de 19 níveis fáceis e 56 estrelas foi observada no segundo aparelho por USB. A versão 0.5.1 foi instalada como atualização e validada. Consulte fase-05-play-games-0.5.1.md para correções, evidências e limitações atuais.
