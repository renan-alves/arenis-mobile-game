# Fase 5 — Investigação da sincronização e melhoria preventiva

Data: 18 de novembro de 2026.

## Resultado observado

O usuário relatou inicialmente a mensagem genérica de falha de sincronização e depois confirmou: “Agora deu certo. O progresso foi sincronizado”. Essa confirmação ocorreu no APK anteriormente instalado, antes da entrega de qualquer correção. A causa da primeira falha não foi determinada; a propagação de configuração é uma hipótese, não um diagnóstico comprovado. A troca de código não causou o sucesso relatado. O APK já instalado pode continuar em uso.

## Correção independente

A análise identificou que o retorno da interface de login do Google podia acionar request_sync antes da confirmação de autenticação. A ponte agora acompanha os estados de conexão/autenticação e aguarda a confirmação para ler snapshots. Retomadas durante o login não disparam leitura nem outra interface de autenticação. Novas tentativas após falhas verificam a autenticação novamente.

Conexões têm timeout de 120 segundos e operações de snapshot mantêm o limite de 30 segundos. Cancelamento ou destruição da ponte invalida callbacks atrasados de login. O status de falha conserva o progresso no aparelho.

A ponte Java registra apenas etapa, código numérico do SDK ou classe da exceção, sem mensagens da exceção, contas, conteúdo de progresso, tokens ou credenciais. O detalhe aparece na tela de conta e privacidade somente em builds debug. O release mantém a mensagem simples existente. Campos de progresso, regras, fases e anúncios não foram modificados.

## Validação

- 4130 verificações, 17 suítes e seis cenários CLI passaram, sem falhas.
- Nove verificações adicionadas cobrem espera de login, retomada da interface Google, deduplicação de autenticação, falha/repetição de autenticação, exibição de diagnóstico apenas no debug, timeout e callbacks após desligamento.
- Plugin Java e APK de diagnóstico compilaram.
- Inspeção confirma assinatura válida, 150 fases, três idiomas e ARM64; diretórios de desenvolvimento não são exportados.
- Os anúncios permanecem no modo de teste.
- O novo APK não foi validado em aparelho: nenhum dispositivo estava conectado. O sucesso real registrado pertence ao APK anterior.

APK opcional para investigação futura: build/android/arenis-play-games-diagnostics-debug.apk, 251440466 bytes. SHA-256: 6d1814c4b249b105f144cba8f46ef7fcac7301470a29b61e5897ba9ea760c5ee.

## Próximo teste

Verificar restauração de estrelas e melhores jogadas em outro aparelho com a mesma conta testadora, mantendo a instalação original. Resolução de conflitos reais e cenários de rede continuam pendentes. A sincronização de uma partida em andamento não faz parte do recurso; são enviados resultados concluídos.

As alterações estão locais. Não foi feito commit ou publicação do código do jogo.
