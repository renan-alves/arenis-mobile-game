# Android — build e configuração

## Versão de teste da fase 5

O APK atual é `build/android/arenis-journey-0.6.0-debug.apk`, com os IDs públicos de teste do Google. Instale no Android 7.0 ou superior (API 24). O pacote definido para o aplicativo é `com.frontmakers.arenis`, versão 0.6.0, código 7. Use esse mesmo identificador no Play Console e nas credenciais Android do Play Games.

Copie o APK para o celular, abra-o e permita a instalação por aquele aplicativo quando o Android solicitar. Se usar USB com depuração autorizada:

```powershell
& 'C:\caminho\Android\Sdk\platform-tools\adb.exe' install -r '.\build\android\arenis-debug.apk'
```

`-r` atualiza o mesmo pacote preservando seus dados quando a assinatura é a mesma. Em caso de assinatura diferente, não desinstale automaticamente: a desinstalação apagaria o salvamento local.

Esta versão inclui a ponte nativa e anúncios de teste. A exibição depende de rede, consentimento e disponibilidade do SDK. Sem anúncio, o espaço fica livre e o jogo continua. Play Games permanece indisponível no menu até que o projeto seja configurado; isso não impede jogar ou salvar no aparelho.

## Ferramentas fixadas

| Componente | Versão |
|---|---|
| Godot padrão e templates | 4.7.2 |
| Java | JDK 17 |
| SDK Platform / target | 36 |
| Build Tools | 36.1.0 |
| Minimum SDK | 24 |
| Gradle / Android Gradle Plugin | 8.11.1 / 8.6.1, do template Godot |
| Google Mobile Ads, API tradicional | 25.5.0 |
| User Messaging Platform | 4.0.0 |
| Play Games Services v2 | 22.1.0 |

Os SDKs foram conferidos na documentação e nos repositórios oficiais. O template Godot fixado usa AGP 8.6.1 e emite um aviso de compatibilidade com compileSdk 36; a compilação do plugin e do APK passou. Não foi suprimido esse aviso nem substituído o AGP do engine. Reavaliar o conjunto na homologação, antes de atualizar versões isoladamente.

Instale o JDK 17 e os templates de exportação pelo Godot. O Java global do computador pode continuar na versão 25. Instale as ferramentas de linha de comando Android e os pacotes `platform-tools`, `platforms;android-36` e `build-tools;36.1.0`. Não é necessário compilar o engine nem instalar NDK/CMake para esta ponte Java com bibliotecas Godot pré-compiladas.

O build desta entrega usou instalações portáteis em `%TEMP%\arenis-android-tools` e o Godot em `%TEMP%\arenis-godot`. São caminhos desta máquina; prefira uma instalação durável de SDK/JDK para o uso diário.

```powershell
.\tools\build-android.ps1 `
  -GodotPath 'C:\caminho\Godot_v4.7.2-stable_win64_console.exe' `
  -AndroidSdkPath 'C:\caminho\Android\Sdk' `
  -JavaSdkPath 'C:\caminho\jdk-17'
```

O script extrai `android_source.zip` dos templates quando necessário, compila o plugin Java, copia seu AAR para o addon e exporta o APK. Atualiza somente os dois caminhos Android nas configurações do editor, preservando uma cópia em `editor_settings-4.7.tres.before-arenis-android.bak`. Evita daemons Gradle que podem manter o console do Godot aberto no Windows. Os diretórios gerados não vão para o Git.

```powershell
.\tools\inspect-android.ps1 `
  -AndroidSdkPath 'C:\caminho\Android\Sdk' `
  -JavaSdkPath 'C:\caminho\jdk-17'
```

A inspeção confere assinatura, campanha, idiomas e presença de ARM64. O APK de desenvolvimento inclui ARMv7, ARM64 e x86_64, por isso é maior que o download por aparelho distribuído por um AAB. Dados e idiomas são incluídos explicitamente por `export_presets.cfg`.

## AdMob e consentimento

1. Crie uma conta AdMob e cadastre Arenis como aplicativo Android. Ainda não é preciso publicar o jogo na loja para cadastrar o app.
2. Crie uma unidade de banner e outra intersticial. Não use formatos de recompensa. O SDK intersticial pode fornecer criativos de imagem ou vídeo conforme a configuração e o inventário; o código não promete vídeo em toda impressão.
3. Em Privacidade e mensagens, configure as mensagens aplicáveis. A UMP atualiza o estado em cada abertura, apresenta o formulário quando necessário e libera pedidos somente quando `canRequestAds()` permite. O menu Conta e privacidade oferece a reabertura das opções quando o SDK informa que ela é obrigatória.
4. Copie `platform/android/services.example.properties` para `services.local.properties`. Preencha os três IDs públicos e mantenha `production=false` durante o desenvolvimento.
5. Antes da distribuição, configure público e classificação no Play Console, mensagens de privacidade e declarações de dados/SDKs a partir do comportamento final. Público geral foi a decisão de produto; a configuração do console ainda não foi realizada.

IDs de teste incorporados:

- App: `ca-app-pub-3940256099942544~3347511713`.
- Banner adaptativo: `ca-app-pub-3940256099942544/9214589741`.
- Intersticial: `ca-app-pub-3940256099942544/1033173712`.

O banner é ancorado na parte inferior e tem largura/altura calculadas pela API adaptativa, não uma altura fixa de 50 dp. Sua altura efetiva e o espaço da barra de sistema são informados ao Godot. Não existe recompensa, carregamento de anúncio no meio de um despejo ou bloqueio de progresso por falha de anúncio.

O contador local é global entre dificuldades e fica em `user://services.cfg`: a primeira conclusão conta um, a segunda habilita o intersticial na próxima saída do resultado, inclusive ao rejogar. Reinícios, desistências e abertura repetida do mesmo resultado não contam. O contador só zera no callback de exibição; indisponibilidade/falha mantém a oportunidade para uma transição futura. Ele satura em dois, sem acumular uma fila de anúncios enquanto offline. Fechar o app depois da exibição não gera uma cobrança duplicada na próxima sessão. Resultado e contador usam arquivos distintos; uma interrupção exatamente entre as duas gravações pode deixar de contar aquela conclusão para anúncios, sem perder o resultado salvo.

APKs de desenvolvimento gerados pelo script sempre usam os IDs de teste, mesmo se o arquivo local contiver IDs reais. Um AAB com anúncios reais exige `production=true` e a opção explícita `-ProductionAds` junto de `-Release`. O build rejeita IDs vazios e IDs de exemplo nesse modo.

## Play Games e Saved Games

1. No Play Console, crie o jogo e a configuração do Play Games Services. Habilite Saved Games.
2. Cadastre uma credencial Android para o pacote `com.frontmakers.arenis` e o SHA-1 do certificado que assina o aplicativo. O debug local, a chave de upload e o certificado de assinatura gerenciado pelo Google Play são certificados diferentes; configure os necessários para cada canal de teste.
3. Inclua sua conta como testadora e mantenha os projetos/configurações vinculados conforme indicado no console.
4. Preencha `games.project_id` no arquivo local e gere novamente o APK. Esse é o ID numérico do Play Games, não um client secret nem a chave privada de assinatura.
5. No app, abra Configurações → Conta e privacidade e ative Sincronizar progresso. Isso verifica a autenticação do SDK e habilita a leitura e o envio de resultados. Desativar interrompe a sincronização; não exclui dados locais/remotos nem equivale a sair da conta Google do aparelho.

Sem ID configurado, o provider do Play Games fica desativado pelo recurso booleano arenis_games_configured. Com um ID configurado, o provider oficial prepara o SDK antes da primeira Activity, para registrar seu ciclo de vida corretamente; o Google pode reconhecer automaticamente um perfil existente. A leitura e o envio de resultados continuam condicionados à opção Sincronizar progresso. A criação automática de novos perfis está suprimida; a conexão explícita pode apresentar a interface do Google.

Snapshot: `arenis_journey_v1`, JSON schema 1, máximo 1 MiB. São enviados apenas IDs/revisões de fases, versão de regras, estrelas e melhores jogadas. Não são enviados partidas ativas, histórico de desfazer, preferências ou contador de anúncios.

Os resultados são unidos por ID + revisão + regras, mantendo mais estrelas e menos jogadas. A operação é comutativa, associativa e idempotente. Conflitos retornados pelo SDK são mesclados novamente, com até cinco resoluções. Versões antigas continuam arquivadas e não liberam tabuleiros atuais; a sequência liberada deriva das conclusões atuais, sem confiar em um número remoto arbitrário. O merge local preserva as tentativas, mesmo quando um upload falha. Não há exclusão remota nem sincronização entre contas diferentes por um servidor próprio.

Dados inválidos/versões de schema desconhecidas cancelam a gravação remota. Falhas de rede deixam o salvamento local disponível; o app tenta novamente ao retomar, concluir ou usar Sincronizar agora. Uma operação parada expira em 30 segundos. Alterações feitas durante a sincronização provocam nova rodada, sem abrir snapshots concorrentes.

## Homologação pendente

- Instalar em aparelho, abrir offline, jogar, matar/reabrir o processo e conferir restauração.
- Conferir recortes da tela, barras do Android, três fileiras de tubos, temas e os três idiomas.
- Ver anúncio de teste, completar duas fases/rejogadas e conferir transição, fechamento, falta de rede e mudança das opções de privacidade.
- Com Play Games configurado, testar autenticação recusada, duas instalações/contas de teste apropriadas, conflito de recordes, troca de versão de fase e desligamento da sincronização.
- Gerar/homologar AAB assinado de lançamento. Nenhuma publicação foi feita nesta fase.

O computador não tinha driver de aceleração do emulador e a tentativa em software encerrou com código `0xC0000005`. Não há validação de execução Android nem de exibição nativa de anúncio nesta entrega. As verificações automatizadas exercitam a lógica e o fluxo Godot; a compilação confere as APIs Java.

## Fontes oficiais consultadas

- [Exportação Android e requisitos](https://docs.godotengine.org/en/stable/tutorials/export/exporting_for_android.html) e [plugins Android v2](https://docs.godotengine.org/en/stable/tutorials/platform/android/android_plugin.html).
- [Configuração de AdMob](https://developers.google.com/admob/android/quick-start), [banner adaptativo](https://developers.google.com/admob/android/banner) e [intersticial](https://developers.google.com/admob/android/interstitial).
- [Consentimento UMP](https://developers.google.com/admob/android/privacy).
- [Autenticação Play Games v2](https://developer.android.com/games/pgs/android/android-signin) e [Saved Games/conflitos](https://developer.android.com/games/pgs/android/saved-games).

As versões de SDK foram fixadas; não usar dependências com `+` ou atualizar a versão do Godot sem repetir a compilação e a homologação.

## APK vinculado ao projeto Play Games de teste

Em 18 de novembro de 2026, o projeto numérico `471459189605` foi configurado em `platform/android/services.local.properties`, arquivo ignorado pelo Git. O usuário informou ter concluído a credencial Android no Console. O APK dedicado foi gerado em `build/android/arenis-play-games-debug.apk`, mantendo o APK anterior e anúncios de teste.

Antes de testar no aparelho:

1. Em Play Games Services → Configuração → Editar propriedades, habilite Jogos salvos e salve.
2. Em Configuração e gerenciamento → Testadores, adicione a conta Google usada no celular, incluindo sua própria conta. Testadores do Play Games e participantes de faixas de teste da Play Store são configurações distintas.
3. Se o OAuth estiver em modo Teste, adicione também a conta à lista de usuários de teste do OAuth no Google Cloud.
4. Instale o APK dedicado como atualização do mesmo pacote/assinatura. No jogo, abra Configurações → Conta e privacidade e ative Sincronizar progresso.
5. Confira autenticação e sincronização de resultados concluídos. Para avaliar a restauração, use outro aparelho com o mesmo APK e a mesma conta testadora, sem apagar os dados da instalação original.

O Google informa que a habilitação de Jogos salvos pode levar até 24 horas e que a liberação de novos testadores pode levar algumas horas. Não é necessário publicar o jogo ou o projeto Play Games para testar com contas autorizadas.

A validação de compilação e metadados não comprova autenticação, consentimento ou sincronização remota. Esses comportamentos exigem execução em aparelho. O resultado da preparação consta em `docs/relatorios/fase-05-play-games-teste.md`.

## Correção 0.5.1 — inicialização e atualização após restauração

O teste USB no Samsung SM-A530F com Android 9 mostrou sign_in / not_authenticated, e o serviço Google retornou SIGN_IN_REQUIRED com resolução pendente. Após sair para Home, retomar o app e repetir a conexão, a Activity Google de login abriu. O usuário conectou a conta; o salvamento local no segundo aparelho passou a conter 19 níveis fáceis com 56 estrelas, e o app exibiu Progresso sincronizado.

A versão 0.5.1 mantém o provider oficial habilitado somente quando há um ID de projeto válido, para preparar o SDK antes do ciclo de vida da Activity. Também atualiza as contagens e estrelas após fechar as configurações que estavam abertas durante a restauração, sem reiniciar partidas ativas. O modo de diagnóstico é determinado pelo atributo debuggable do APK Android.

A preparação do SDK e o possível reconhecimento automático do perfil são descritos na política pública atualizada em 19 de novembro de 2026. O backup de resultados continua opt-in. Use o mesmo pacote e assinatura para atualizar sem remover os dados.
