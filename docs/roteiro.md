> Estado em 22/11/2026: a reestruturação autorizada 0.6.0 substitui as três dificuldades por uma jornada única, altera a regra de cor, introduz limites e renova as telas. Consulte [produto atual](produto.md) e [relatório da reestruturação](relatorios/reestruturacao-0.6.md). As fases abaixo registram o planejamento e entregas anteriores.

# Roteiro de execução

## 0. Especificação inicial

Entregável: produto, regras, arquitetura proposta e brief visual registrados no repositório. As principais decisões funcionais foram aprovadas em 12/11/2026. Modelo acordado para planejamento: GPT-6.1 com esforço médio.

## 1. Protótipo das regras — concluído

Construir um recorte jogável em Godot com poucas fases representativas: organização básica, transferência parcial, areia escondida, trancas e espaço livre distribuído sem frasco vazio.

Incluir seleção por toques, contagem, vitória, desfazer e reinício. Validar a experiência antes de produzir toda a campanha. Recomendação já discutida: GPT-6.1 com esforço médio.

## 2. Solver e formato de fases — concluído

Compartilhar regras entre jogo e ferramentas, comprovar solução e mínimo e medir os casos de capacidade 7. Consolidar formato versionado e política de atualização de fases antes da produção em escala. Recomendação já discutida: GPT-6.1 com esforço alto.

## 3. Identidade visual e mascote — concluído

Criar e revisar conceitos de logo, ícone, linguagem de interface e mascote. Demonstrar olhar e piscadas antes de finalizar os recursos. Modelo recomendado anteriormente: GPT-6.1 com esforço extra alto e ferramenta de geração de imagens quando adequada; recursos vetoriais e animações serão implementados em formato editável.

## 4. Campanha e experiência completa — concluída no escopo local

Produzir e validar as 150 fases. Construir tela inicial, grade, tutoriais, pausa, resultados, recordes, salvamento local, temas, idiomas, acessibilidade e áudio. Esforço médio para interface; alto para autoria/validação que envolva o solver.

## 5. Integrações Android — implementação para testes

Implementados APK de desenvolvimento, plugin Android v2 próprio em Java, AdMob com UMP, banner adaptativo medido, intersticial após duas conclusões e sincronização opcional de recordes por Saved Games. IDs de teste por padrão; configuração de contas documentada. Modelo acordado: **GPT-6.1 Sol, raciocínio Alto**.

A entrega técnica está pronta para testes. Ainda falta homologar execução em aparelho, anúncios nativos e sincronização com projeto Play Games configurado. O emulador local encerrou antes de inicializar. Essas pendências não foram declaradas aprovadas por testes de lógica. Consulte [Android](android.md) e o [relatório da fase 5](relatorios/fase-05-android.md).

## 6. Validação e publicação

Verificar regras, mínimos, restauração, conflitos de nuvem, comportamento offline, anúncios, idiomas, temas, legibilidade e desempenho em aparelhos reais. Preparar materiais da loja e a versão de lançamento. Publicação será uma ação separada ao final, com o resultado pronto para revisão.

Modelo recomendado para integração, diagnóstico e validação técnica: **GPT-6.1 Sol, raciocínio Alto**.

## Uso de modelos

As indicações de modelo acima registram o planejamento da conversa e não representam verificação atual de catálogo, preço ou disponibilidade. Antes de cada fase, indicar a escolha disponível no Codex. Ajustes pequenos e bem delimitados podem usar um modelo mais econômico, conforme disponibilidade.

A troca de modelo é manual. Não iniciar a produção final do mascote durante a fase de regras; a tarefa visual tem sua própria etapa.

## Relatórios de execução

- [Fase 1 — Protótipo](relatorios/fase-01-prototipo.md)
- [Fase 2 — Solver e formato](relatorios/fase-02-solver.md)

- [Fase 3 — Identidade visual e mascote](relatorios/fase-03-identidade.md)

- [Fase 4A — Campanha e progresso básico](relatorios/fase-04a-campanha.md). Experiência local concluída na fase 4B.

- [Revisão de paleta e obstáculos](relatorios/revisao-paleta-obstaculos.md): paleta escura própria, remoção de Resultados anteriores e introduções específicas às mecânicas. O tutorial básico interativo e a retomada de partidas foram entregues na fase 4B.

- [Fase 4B — Salvamento, idiomas e treino interativo](relatorios/fase-04b-experiencia.md). Próxima etapa: APK para testes e integrações Android da fase 5.

- [Fase 5 — Android e serviços](relatorios/fase-05-android.md). Implementação para testes; homologação nativa e configuração das contas ainda pendentes.
