# Idiomas

Pacotes offline: português do Brasil em `pt_BR.json`, inglês em `en.json` e espanhol latino-americano em `es_419.json`. O nome do jogo permanece em inglês.

As chaves são as mensagens fonte em português. Todos os pacotes precisam conter as mesmas chaves e preservar os marcadores `%s` e `%d`. Também traduzir as instruções dos níveis. Para acrescentar texto, atualizar os três JSONs e executar `tests/localization_test.gd`.

`scripts/localization.gd` constrói recursos Translation nativos do Godot e instala os pacotes uma vez. Detecção automática usa inglês para locales en, espanhol latino-americano para locales es e pt-BR como fallback. A configuração manual tem prioridade e é salva. O Godot pode padronizar internamente es_419 como es; o pacote selecionado e o conteúdo continuam sendo latino-americanos.

Textos dinâmicos são traduzidos antes de formatar seus argumentos. Números de nível e dados de progresso não mudam quando o idioma muda. Inglês, espanhol e português usam a fonte Manrope já incluída no projeto.

Na exportação Android da fase 5, incluir `*.json` no filtro de arquivos não-resource, abrangendo `locales/` e `data/`. O jogo não baixa pacotes durante a execução.
