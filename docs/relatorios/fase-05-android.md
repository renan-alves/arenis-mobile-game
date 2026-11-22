# Fase 5 — Android e serviços

Data: 12/11/2026. Repositório oficial: `C:\git-workspace\arenis-mobile-game`.

Modelo indicado: **GPT-6.1 Sol, raciocínio Alto**. Escopo autorizado: iniciar as integrações Android. O usuário confirmou que ainda não tem AdMob/Play Console configurados e pediu anúncios de teste e documentação da configuração.

## Estado da entrega

**Implementação técnica para testes entregue; homologação nativa pendente.** Há APK debug e compilação dos SDKs, mas a execução em Android, a exibição de anúncios e a sincronização com um projeto Google real ainda não foram aprovadas. Não houve publicação, commit ou push.

| Frente | Implementação |
|---|---|
| Exportação | Presets de APK debug e AAB release, package provisório `com.renanalves.arenis`, versão 0.5.0/código 5, API mínima 24 e target 36. |
| Build reproduzível | Script extrai o template 4.7.2, compila o plugin, configura SDK/JDK e exporta. Outro script verifica assinatura, campanha e idiomas do APK. |
| Ponte nativa | Plugin Godot Android v2 próprio, Java 17, com dependências fixadas. Bibliotecas geradas, credenciais e builds ignorados pelo Git. |
| Banner | AdMob adaptativo ancorado no rodapé; dimensão medida e espaço da barra de sistema comunicados ao Godot. Sem anúncio, a reserva é liberada. |
| Intersticial | Pedido na saída do resultado após duas conclusões, incluindo rejogadas. Contador local persistente, sem duplicação ao reabrir resultado, sem recompensas e sem bloquear navegação em falhas. |
| Consentimento | UMP consulta o estado a cada abertura; pedidos só após autorização do SDK. Entrada de opções de privacidade quando exigida pela UMP. |
| Play Games | Inicialização sob escolha do jogador, sem provider automático. Sem ID configurado, o jogo segue local e não tenta autenticar. |
| Progresso remoto | União de resultados por ID/revisão/regras, mais estrelas e menos jogadas. Conflitos manuais, limites de tamanho/repetição, timeout e reenvio de alterações concorrentes. |
| Interface | Conta e privacidade em página própria das configurações, com textos em pt-BR/en/es-419. Controles respeitam o recorte superior informado pelo Android. |

## Decisões implementadas

O banner não usa 50 dp como dimensão obrigatória. O SDK escolhe a altura adaptativa para a largura disponível e o layout recebe os pixels medidos. O placeholder continua apenas na execução desktop. O topo ganha o espaço necessário quando a área do Godot se estende sob a barra/câmera do aparelho.

Uma conclusão habilita o contador uma vez por tentativa. A oportunidade de intersticial acontece na próxima navegação depois do resultado e da animação. Indisponibilidade/falha mantém o contador no máximo de dois; ele zera somente quando o SDK informa que mostrou o anúncio. Não há acúmulo de uma fila de anúncios ao voltar da ausência de rede. Resultado e contador estão em arquivos distintos: uma interrupção entre as duas gravações pode deixar de contar aquele resultado para anúncios; o progresso já salvo permanece.

O tipo intersticial do SDK pode retornar criativos de imagem ou vídeo. Não foi usado um anúncio recompensado para tentar impor vídeo, e nenhuma ação ou estrela depende de anúncio.

Preferências, partidas e contador ficam no aparelho. Saved Games recebe somente conclusões/recordes, em JSON com schema próprio. A união é comutativa, associativa e idempotente; tentativas em andamento permanecem intactas. Recordes antigos são arquivados e não desbloqueiam revisões atuais. Dados corrompidos/desconhecidos não são enviados de volta para substituir o snapshot remoto.

A ponte usa Java para manter uma biblioteca pequena que chama as APIs oficiais. O projeto Godot continua em GDScript; nenhuma mudança no solver, nos mínimos das 150 fases, na paleta ou no áudio aprovado foi necessária.

## Verificação

**4.121 verificações e seis cenários de CLI passaram, sem falhas.** A regressão compreende as 15 suítes anteriores mais duas novas. Localização passa a ter 117 mensagens por idioma, com 721 verificações.

| Cobertura adicionada | Verificações |
|---|---:|
| Serviços Android e nuvem | 47 |
| Fluxo do jogo com serviços | 11 |

Os testes exercitam união em diferentes ordens, idempotência, revisões/regras incompatíveis, dados inválidos/grandes, restauração dos resultados, preservação das tentativas, contador entre sessões, anúncios ausentes/atrasados, toques repetidos, callbacks duplicados, sincronizações concorrentes, opt-out e timeout. O fluxo da cena comprova conclusão antes da apresentação, repetição do resultado sem nova contagem, rejogada contando outra conclusão e aplicação/reversão da área segura superior.

O plugin Java e o APK compilaram com os SDKs oficiais. O pacote foi inspecionado para conferir assinatura de teste, metadados Android, campanha com 150 fases, os três idiomas e bibliotecas ARMv7/ARM64/x86_64. Documentação, testes e ferramentas de autoria não entram como arquivos de desenvolvimento no APK.

O AGP 8.6.1 fornecido pelo template Godot emite aviso por compileSdk 36; a compilação passou. Esse aviso está registrado no guia, sem supressão. O computador usa Java global 25, mas o build usa JDK 17 portátil e não troca a instalação global.

## Limitações e próximos passos

Nenhum aparelho estava conectado. O emulador não tinha driver de aceleração disponível; as duas tentativas em software encerraram durante a inicialização, com código `0xC0000005`. Isso impediu a validação nativa de abertura, toque, anúncios e áreas de sistema. Os testes Godot não substituem essas verificações.

AdMob e Play Console ainda não foram criados/configurados pelo usuário. A integração de nuvem está implementada e testada com uma ponte simulada, mas autenticação, permissões Saved Games e resolução real entre dois aparelhos dependem dessa configuração. O menu informa indisponibilidade nesta versão, em vez de apresentar conexão bem-sucedida fictícia.

O próximo passo é instalar o APK em aparelho e seguir a lista de homologação do [guia Android](../android.md). O mesmo guia traz as etapas para cadastrar os serviços e preparar um AAB assinado; nenhuma chave de publicação foi criada automaticamente. A fase 6 reúne a homologação completa e a preparação da loja. Modelo indicado: **GPT-6.1 Sol, raciocínio Alto**.

## Artefato e evidência

APK gerado e inspecionado na pasta oficial: `build/android/arenis-debug.apk`, 251439730 bytes (aproximadamente 239.8 MiB, debug com três arquiteturas). SHA-256: `0be44a513603ec1347e0eef9d7030d856af49e9d5298212361e6d236fd77a457`.

[Resultados das suítes e metadados do APK](fase-05-verificacao.json). A suíte completa passou na cópia de trabalho; os 39 arquivos foram conferidos por SHA-256 após a aplicação, o APK foi recompilado na pasta oficial e os dois novos testes foram repetidos nela com zero falhas.

## Atualização do identificador Android

O usuário definiu com.frontmakers.arenis durante o cadastro da loja. Os presets e o guia atual foram alterados, e um novo APK foi gerado e inspecionado. Os dados acima descrevem o primeiro artefato da fase 5; para o APK atual, consulte [alteração para Frontmakers](fase-05-pacote-frontmakers.md) e sua evidência JSON.
