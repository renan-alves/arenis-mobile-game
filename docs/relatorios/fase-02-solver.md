# Relatório da fase 2 — Solver e formato das fases

Data: 12/11/2026. Modelo: GPT-6.1 Sol, esforço alto.

## Entrega

Implementado solver offline exato, com limites explícitos de tempo e estados. A busca compartilha a aplicação de movimentos do jogo e retorna mínimo comprovado, impossibilidade comprovada ou interrupção por orçamento. Resultado limitado não recebe mínimo nem é declarado impossível.

O formato de pacotes agora usa schema 2 e regras 1, com IDs e revisões de fases, IDs lógicos das dificuldades e metadados do pacote. As seis demonstrações foram migradas. O jogo e as ferramentas carregam o mesmo validador, rejeitando estruturas inválidas com mensagens em vez de tentar usá-las no núcleo.

A ferramenta de autoria calcula soluções sem editar o fonte, verifica mínimos declarados, reproduz soluções e emite evidência JSON com fingerprint. Há schema para editores e documentação para acrescentar fases.

## Arquivos principais

- `scripts/solver.gd`: BFS exata com armazenamento de pais e orçamento.
- `scripts/level_catalog.gd`: carga e validação compartilhadas.
- `scripts/rules.gd`: versão central das regras e opção de despejo sem histórico para busca.
- `scripts/main.gd`: carregamento pelo catálogo validado.
- `data/level-pack.schema.json` e `data/prototype_levels.json`: schema e migração dos dados.
- `tools/validate_levels.gd` e `tools/validate-levels.ps1`: ferramenta de autoria.
- `tests/solver_test.gd`, `tests/cli_test.ps1`, `tests/data/benchmark_levels.json`: cobertura e benchmarks reproduzíveis.
- `docs/formato-fases.md`: referência e fluxo de autoria/publicação.

## Verificação

Godot 4.7.2 em Windows. Regras: 85 verificações; interface: 13; solver/catálogo: 142. Todas passaram. Mais seis cenários de CLI passaram: pacote válido, mínimo incorreto, cálculo sem exigir o valor declarado, limite de estados, proteção contra sobrescrita do fonte e JSON malformado com invalidação do relatório anterior.

O solver foi comparado com uma implementação de referência para todas as 20 configurações de duas cores distribuídas em dois frascos cheios de capacidade 3 e um apoio vazio. Também foram testadas trancas circulares impossíveis, estado inicialmente concluído, esgotamento sem solução, limites de tempo/estados, impressões digitais e dados malformados de diversos tipos.

O schema foi verificado por `jsonschema` (Draft 2020-12) disponível no ambiente; as demonstrações e o pacote de benchmark passaram. Essa biblioteca foi usada somente na verificação da entrega, sem adicionar dependência ao jogo ou à ferramenta Godot.

## Medições

Referência local; tempos variam por máquina e execução. O relatório JSON registra os resultados completos.

| Caso | Mínimo | Estados armazenados | Tempo observado |
|---|---:|---:|---:|
| Fácil 1 | 5 | 11 | cerca de 1 ms |
| Fácil 2 | 3 | 6 | menos de 1 ms |
| Sem frasco vazio | 2 | 4 | cerca de 1 ms |
| Areia escondida, capacidade 5 | 9 | 437 | cerca de 41 ms |
| Tranca, capacidade 5 | 3 | 4 | menos de 1 ms |
| Segredos + tranca, capacidade 7 | 3 | 4 | menos de 1 ms |
| Capacidade 7, duas cores alternadas | 13 | 1.251 | cerca de 148 ms |
| Capacidade 7, três cores alternadas | 19 | 13.576 | cerca de 2.211 ms |

O orçamento de 3 segundos por benchmark foi suficiente nesta execução. Não se pode extrapolar esses tempos para qualquer fase de capacidade 7. Busca em largura pode crescer muito com mais cores e frascos; fases que excederem o orçamento precisam de nova execução com recursos adequados, revisão de autoria ou melhoria futura do algoritmo. Nenhuma fase limitada pode ser publicada com mínimo estimado como se fosse comprovado.

## Decisões e limites

A busca conserva a posição dos frascos e o estado das trancas, sem reduções de simetria ou poda heurística que pudessem eliminar soluções. O conhecimento de cores escondidas não afeta a legalidade e fica fora da chave: o mínimo segue a decisão aprovada de conhecimento completo do tabuleiro.

A paleta validada ainda é a do protótipo: coral, aqua e gold. A ampliação de cores/símbolos será coordenada com a identidade visual. Revisões de fase e regras estão preparadas no formato; a migração concreta de salvamentos será implementada na fase de persistência.

A ferramenta valida dados e prova soluções, mas não produz automaticamente a campanha nem avalia diversão ou dificuldade percebida. Permanecem as limitações de apresentação e plataforma da fase 1: arte provisória, sem APK e sem persistência entre sessões.

## Git e próxima fase

Entrega no repositório oficial; ainda sem commits ou push. Os arquivos continuam no diretório de trabalho, incluindo o planejamento e a fase 1.

Próxima fase: **3 — Identidade visual e mascote**. Modelo indicado no roteiro: **GPT-6.1 Sol, esforço extra alto**. Antes de produzir os recursos finais, revisar conceitos de forma, contorno/preenchimento e demonstração do olhar.
