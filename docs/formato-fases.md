# Formato e autoria de fases — schema 3, regras 3

`data/campaign.json` é a campanha oficial. `data/level-pack.schema.json` apoia editores; `scripts/level_catalog.gd` é o validador compartilhado com o jogo e confere relações entre campos. As seis demonstrações antigas foram recalculadas nas regras 3 para regressão, mantendo seus grupos internos.

## Dados

Pacote: `schema_version: 3`, `rules_version: 3`, `pack_id`, `pack_version` positivo e `levels` sem IDs repetidos. Campos desconhecidos são rejeitados.

Cada fase contém `id` estável, `version` da revisão do tabuleiro, `title`, `number` sequencial, `difficulty_id: journey`, `difficulty: Campanha`, `capacity` entre 3 e 7, `minimum_moves` positivo, `lesson`, `mode`, `move_limit`, `time_limit` e `bottles`. Os nomes exibidos são Nível N traduzidos; não inventar nomes. O agrupamento lógico journey não é uma dificuldade selecionável.

`mode` é `free`, `moves` ou `timed`. Os dois orçamentos são inteiros não negativos. Fases livres têm ambos zero; moves exige apenas `move_limit > 0`; timed exige apenas `time_limit > 0`. Orçamento de jogadas não pode ser menor que o mínimo. O solver prova o tabuleiro sem orçamentos; a reprodução final usa os limites reais.

Cada tubo tem `colors` da base ao topo, com até capacity elementos. `[]` representa vazio. `hidden` contém índices inteiros únicos a partir de zero; `unlock_color` é opcional. Cada cor deve somar um múltiplo da capacidade e a cor de uma tranca deve existir. Cores aceitas: coral, aqua, gold, lilac, sky, sage, rose, peach, indigo e mint. Consulte [regras](regras.md) para revelação, abertura e despejos.

## Acrescentar níveis

1. Acrescente ao fim do pacote um novo ID `level-NNN`, number sequencial e version 1, sem alterar IDs publicados. Escolha cores/tubos e comece com minimum_moves 0 para autoria.
2. Calcule o mínimo com `tools/validate-levels.ps1 -InputPath data/seu-rascunho.json -Solve`, informando `-GodotPath` quando necessário. Só status optimal comprova mínimo. Transfira a resposta ao rascunho e atribua limites que permitam a solução.
3. Valide sem -Solve e reproduza a solução com as regras e limites atuais. Rode `tools/check.ps1`, teste a fase manualmente e revise a dificuldade percebida antes de distribuí-la.

A campanha atual tem testemunhas em `docs/relatorios/jornada-v3-provas.json`. Para revalidá-la:

```powershell
godot --headless --path . --script tools/validate_journey.gd
```

A saída é tmp/journey-certified.json. Parâmetros opcionais depois de --: --input, --witnesses e --output. A saída deve ser diferente das entradas. Para reusar certificados já aceitos, --reuse exige fingerprint idêntico; não substitui prova de um tabuleiro alterado.

A* verifica uma testemunha legal e vencedora antes de usá-la como limite superior. Prova o mínimo quando esgota todos os estados com custo estimado menor. Testemunhas inválidas são ignoradas. Tempo/estados esgotados retornam limit, sem inventar mínimo ou impossibilidade. A heurística admissível é o número de blocos contínuos menos o total de tubos completos exigidos; desfazer não melhora o mínimo por ser um ciclo de custo positivo. Testes confrontam a busca com BFS posicional independente.

O fingerprint inclui regras, ID, revisão, capacidade, grupo lógico, cores, segredos, trancas, modo e orçamentos. Exclui prosa e resposta declarada. Certificados antigos não valem para regras 3.

`tools/build_journey.py` gera candidatos determinísticos por semente e usa busca Python limitada, sem sobrescrever a campanha. Interrupções por tempo podem variar conforme a máquina; os arquivos aprovados e seus certificados são a fonte fixa. A substituição curada do nível 142 está em `data/journey-authoring-overrides.json` e também passa pela prova independente Godot. Use --input res://tmp/journey-pack.json --witnesses res://tmp/journey-witnesses.json para avaliar novos candidatos. Nenhum algoritmo de geração roda no Android.

Resultados e tentativas referenciam versões/regras/fingerprint. Na reestruturação autorizada da beta, o progresso local e remoto usa um namespace novo. Para revisões após lançamento, definir migração explícita antes de substituir tabuleiros.
