# Regras — versão 3

O núcleo determinístico é `scripts/rules.gd`. `Rules.RULES_VERSION` vale 3.

Só o bloco contínuo da cor no topo pode sair de um tubo destrancado. O destino precisa estar destrancado, ter espaço e estar vazio ou ter a mesma cor no topo. Transfere-se o máximo que couber; o restante permanece na origem. Uma tentativa inválida não gasta jogadas. Cada despejo válido conta uma jogada, independentemente da quantidade de unidades.

A vitória exige que cada tubo não vazio esteja cheio e contenha uma única cor. Tubos vazios são permitidos. Desfazer retorna ao tabuleiro anterior e custa uma jogada; as cores descobertas permanecem conhecidas. Reiniciar zera jogadas, tempo, histórico e descobertas.

## Limites e estrelas

Fases livres não impõem limite. Fases de jogadas encerram a tentativa ao esgotar o orçamento; completar os tubos exatamente na última jogada tem prioridade e vale vitória. Desfazer também consome esse orçamento.

Fases com tempo começam a contar na primeira jogada válida. Menus, animações, apresentações e segundo plano pausam a contagem. Desfazer não devolve tempo. O tempo persistido é retomado sem descontar o período fora do app. Ao esgotar, a tentativa termina. A interface oferece nova tentativa ou mapa, sem vidas ou recompensas. Não se combinam limite de jogadas e tempo na campanha inicial.

Concluir rende uma estrela. Até 50% acima do mínimo rende duas; até 20% acima rende três, incluindo a igualdade. As estrelas dependem apenas das jogadas. O mínimo considera conhecimento completo das cores e trancas e ignora tempo de reflexão. Uma prova matemática de mínimo não garante dificuldade percebida uniforme.

## Obstáculos

Areia escondida tem cores fixas, reveladas quando o bloco chega ao topo de um tubo destrancado. Não é sorteada durante a partida. As cores ocultas seguem participando das regras de correspondência.

Trancas impedem receber e despejar. Abrir exige completar outro tubo destrancado com a cor da chave. A abertura persiste durante despejos; desfazer restaura a tranca anterior. Cascatas de desbloqueio são resolvidas até estabilizar.

Há exemplos independentes para areia escondida, trancas e combinação; apresentações próprias para os novos limites. Confirmações são guardadas por mecânica na campanha. O treino inicial usa outro tabuleiro e não altera resultados.
