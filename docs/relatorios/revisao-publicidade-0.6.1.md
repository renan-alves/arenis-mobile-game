# Revisão de publicidade — 0.6.1

Executada em 22/11/2026. O pedido foi reduzir as interrupções de anúncios de tela cheia e manter o banner em todas as telas.

## Comportamento entregue

- Banner adaptativo permanente, com o mesmo espaço reservado.
- Níveis 1 a 10 isentos de intersticiais, inclusive ao rejogar. Suas conclusões não entram na contagem.
- A partir do Nível 11, é preciso concluir cinco fases elegíveis e esperar pelo menos 300 segundos desde a última exibição. As duas condições são exigidas juntas; o anúncio só pode ser solicitado ao sair do resultado de uma conclusão real.
- Carência inicial de 300 segundos ao instalar ou migrar a política. O intervalo usa tempo cronológico, incluindo o período fora do app.
- Contador e referência de tempo persistidos. A contagem satura em cinco, sem formar fila de anúncios. Abrir o app, perder, reiniciar e abrir menus/tutoriais não exibem intersticiais.
- Pedido sem anúncio disponível, erro ou timeout permite continuar sem consumir a oportunidade. Só o callback de exibição zera o contador e reinicia o intervalo. Callback duplicado não reinicia o relógio; falha de gravação após a exibição mantém o limite em memória.

Para uma campanha iniciada do zero, a primeira oportunidade é após cinco conclusões do Nível 11 em diante, respeitando também o tempo mínimo. Rejogar níveis protegidos nunca remove a isenção, mesmo com outra oportunidade acumulada.

## Migração e preservação

A política local de publicidade passa à versão 2 em services.cfg. A contagem antiga, de dois resultados, é descartada; começa uma nova carência. Progresso, estrelas, recordes, preferências e escolha de sincronização permanecem. As conclusões dos níveis isentos continuam disparando a sincronização automática. Contador e referência de tempo são locais e não entram no snapshot.

## Verificação

**7.433 verificações em 20 suítes, zero falhas**, mais seis cenários CLI. A suíte nova tem 46 verificações de política: limites de 299/300 segundos, exigência conjunta de cinco conclusões, isenção das dez fases, persistência entre sessões, migração, dados inválidos, relógio retrocedendo, falha de gravação e entradas reais da interface. A integração cobre timeout, indisponibilidade, callbacks duplicados e sincronização.

O APK foi inspecionado: assinatura válida, pacote com.frontmakers.arenis, versão 0.6.1/código 8, 150 níveis, três idiomas e ARM64 presentes. Regras e tabuleiros não foram alterados; seus certificados permanecem válidos. Anúncios continuam de teste.

## Celular

Instalado no Samsung SM-A530F, Android 9/API 28. A cópia no aparelho foi conferida por SHA-256 antes da instalação. O salvamento principal foi comparado antes/depois da atualização, sem alteração durante a instalação.

A migração preservou a opção de nuvem e iniciou contador zero. Rejogou-se o Nível 5, já concluído: contador permaneceu zero, resultado e mapa mantiveram o banner e a saída não abriu intersticial. A tela de conta mostrou Progresso sincronizado. Ao encerrar e reabrir o app, a referência de tempo e o contador permaneceram iguais. Não foram encontrados erros nas consultas limitadas ao processo do app nas categorias Godot/AndroidRuntime e avisos ArenisCloud.

O jogador já tinha concluído cinco níveis antes da atualização; esse progresso foi preservado. O teste usou uma rejogada e deixou o mapa pronto para o Nível 6. Nenhum intersticial elegível de fase avançada foi forçado no aparelho; esse caminho foi validado com adaptador nativo simulado e relógio controlado.

Evidências: [resultado protegido com banner](imagens/publicidade-0.6.1/protected-result-061.png), [retorno ao mapa](imagens/publicidade-0.6.1/no-interstitial-after-replay-061.png) e [sincronização com banner](imagens/publicidade-0.6.1/cloud-and-banner-061.png).

## Build e documentação

A instalação temporária do SDK/Java estava incompleta. Foram restaurados arquivos ausentes a partir dos pacotes oficiais verificados, mantendo API 36/revisão 2, Build Tools 36.1.0 e Temurin 17.0.21+9. O script de build agora verifica arquivos essenciais antes de iniciar o Gradle. A compilação final passou; o aviso conhecido de compatibilidade do AGP 8.6.1 com compileSdk 36 permanece.

Produto, guia Android, README e página pública foram atualizados. A política de privacidade em três idiomas agora menciona contador e referência de tempo locais. A validação do site passou em cinco páginas e 78 links. Configurações locais, cópias de segurança, chaves e APKs ficam fora do Git.

## Artefatos

APK: build/android/arenis-ads-0.6.1-debug.apk — 253,362,710 bytes.

SHA-256: `65bef8e387c405732b2a17f050e90b7c9072e2bdbbf364822648cc10439a2dbc`.

[Resultado estruturado](revisao-publicidade-0.6.1.json). Publicação na loja e anúncios de produção permanecem etapas separadas.
