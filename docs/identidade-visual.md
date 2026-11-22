# Arenis — Identidade visual 1.0

Silhueta A escolhida pelo usuário em 12/11/2026. Direção: outline, tons pastéis, composição clean. Os arquivos de produção ficam em `assets/`; os estudos em `design/concepts/v1` são histórico de exploração.

## Marca e tipografia

Nome oficial: **Arenis: Sand Sort Challenge**, preservado em inglês. A assinatura usa “arenis” em minúsculas e o subtítulo Sand Sort Challenge. Não esticar ou alterar a proporção dos SVGs. Usar `logo-light.svg` em fundo claro e `logo-dark.svg` em fundo escuro.

Fonte: Manrope variável. Peso 500 para leitura e controles, 600 para títulos. Os SVGs da assinatura têm letras convertidas em curvas; o aplicativo usa o arquivo de fonte. A fonte original e sua licença estão em `assets/fonts/`. Preservar `OFL.txt` ao distribuir a fonte. [Origem da fonte](https://github.com/google/fonts/tree/main/ofl/manrope).

## Paleta

| Papel | Claro | Escuro |
|---|---|---|
| Fundo | `#F8F7F2` | `#202E33` |
| Superfície | `#FFFEFA` | `#29393E` |
| Texto/olhos | `#354E50` | `#E3ECE5` |
| Texto secundário | `#60736F` | `#ADBFBA` |
| Contorno de controles | `#7D9188` | `#7D9892` |
| Acento suave | `#DCEAE1` | `#354F47` |

Areia: coral `#EBC4BC`, água `#BBDADD`, areia dourada `#E8D9B1`. Lavanda `#D9D0E9` compõe a paleta de apoio. A campanha inicial usa coral, aqua, gold e lilac, com lavanda incorporada aos tubos e símbolo + quando a acessibilidade está ativa; novas cores de jogo precisarão de símbolo, contraste e catálogo correspondentes na fase de campanha.

Usar pastel nas áreas de preenchimento do tema claro e tons mais profundos no tema escuro, mantendo texto e informação funcional em cores contrastantes. Os símbolos na areia são opcionais, desligados por padrão e controlados por “Símbolos nas cores (daltonismo)” em Configurações; a indicação de tranca tem contorno escuro/claro além do preenchimento da cor-chave. Símbolos opcionais não são desenhados nas camadas ocultas. Bordas decorativas podem ser suaves; a origem selecionada se diferencia por pequeno marcador e elevação, sem engrossar o contorno.

## Mascote

Um triângulo arredondado com dois olhos verticais, sem boca, membros, roupas ou acessórios. Não recebe nome próprio nesta versão. A base vetorial é 128 × 128, com preenchimento sálvia discreto e contorno 3,2 unidades. Não deformar a silhueta durante a animação dos olhos.

Arquivos completos: `mascot-light.svg` e `mascot-dark.svg`. Para animação, usar os corpos sem olhos (`mascot-body-light.svg` e `mascot-body-dark.svg`) com o componente `scripts/mascot.gd`. Os olhos são desenhados separadamente pelo componente.

- Olhar: limite horizontal de ±5,5 e vertical de -4 a +5 unidades na base 128.
- Mudança de direção: suavização exponencial, constante de aproximadamente 130 ms.
- Piscada: cerca de 220 ms, com fechamento breve e abertura suave.
- Ociosidade: mudanças lentas de olhar e piscadas espaçadas; sem movimento brusco ou expressão de cobrança.
- Seleção: olhar para a origem. Despejo: seguir o arco da areia. Conclusão: olhar para o destino.
- Retorno inválido: olhar breve para o destino, sem expressão agressiva.
- Vitória: olhos ligeiramente mais abertos e olhar central. O resultado mostra o mascote acima do texto.

O mascote é consumidor de eventos visuais; não acessa nem modifica regras, pontuação ou progresso. O componente oferece `set_motion_enabled` para a futura configuração de redução de movimento.

## Ícones e componentes

Os ícones em `assets/icons/` usam grade 24 × 24, contorno 1,7 e terminações arredondadas. São brancos com fundo transparente para receber a cor do tema em execução. Os estudos coloridos permanecem na pasta de conceitos.

Os controles usam cantos de 14 unidades, contorno discreto e foco visível. Evitar sombras pesadas, gradientes e detalhes decorativos nos frascos. O protótipo aplica o tema por `scripts/identity.gd`; o padrão do aparelho é consultado na abertura quando ainda não há escolha manual. O controle sol/lua fica sempre visível na camada global, inclusive sobre menus e resultados. A escolha é salva e a mudança usa transição suave, preservando o estado da tela. Não há opção de tema dentro de Configurações. A opção de símbolos já é persistida localmente.

## Ícone do aplicativo e Android

`assets/branding/app-icon.svg` é o original quadrado, com fundo completo e sem máscara de launcher aplicada. É também o ícone configurado no projeto Godot.

O pacote `assets/branding/android/` contém:

- `icon-48.png`, `icon-72.png`, `icon-96.png`, `icon-144.png`, `icon-192.png` e `icon-512.png`.
- Camadas foreground/background/monochrome em SVG 108 × 108 e PNG 432 × 432.
- VectorDrawables `arenis_foreground.xml`, `arenis_background.xml`, `arenis_monochrome.xml` e exemplo de recurso `ic_launcher.xml`.

As camadas seguem a base 108 × 108 e preservam a informação central dentro de 66 × 66. Fundo e figura não têm máscara ou sombra incorporada, conforme a [orientação Android para ícones adaptativos](https://developer.android.com/develop/ui/compose/system/icon_design_adaptive).

Na integração Android, os VectorDrawables podem ser mapeados para `res/drawable/` e o adaptativo para `res/mipmap-anydpi-v26/`, ou as camadas PNG podem ser configuradas no exportador. O pacote visual foi validado como XML/SVG e rasterizado; compilação e inspeção no launcher de um APK serão feitas na fase 5.

Para regenerar os PNGs a partir dos originais SVG:

```powershell
godot --headless --path . --script design/source/export_identity.gd
```

## Referências e manutenção

O peso da Manrope no aplicativo é configurado por FontVariation, conforme a [documentação do Godot](https://docs.godotengine.org/en/stable/classes/class_fontvariation.html). O código e as imagens da entrega estão descritos no [relatório da fase 3](relatorios/fase-03-identidade.md).

Preservar esta identidade nas próximas telas. Ajustes futuros podem evoluir a versão visual sem alterar IDs ou mínimos das fases.

## Revisão da tela de nível

Após avaliação do usuário, o nível usa cabeçalho sem marca, ações apenas por ícone no topo e tubos de ensaio de contorno com base arredondada. Corpo visual de referência: 52 × 252; área de interação: 88 × 304. Até quatro tubos cabem na mesma linha do protótipo. O contador de jogadas fica separado do título e da dificuldade, e os textos de orientação são substituídos por retorno breve quando necessário. [Relatório da revisão](relatorios/revisao-tela-niveis.md).

## Ajustes de apresentação e movimento

Nos menus do aplicativo, a assinatura é composta em texto com Manrope 34 (arenis) e 16 (Sand Sort Challenge), para manter a leitura no cabeçalho compacto. Dentro dos níveis a marca permanece ausente. Ícones dos botões de ação são elementos independentes do texto, preservando seu centro geométrico. Toggles de configuração têm arte 56 × 32 e área vertical mínima 58.

Despejos e desfazer usam níveis fracionários de preenchimento e corrente de grãos com entrada/saída suave. Telas e menus usam fades curtos, e a troca de tema sobrepõe uma captura do estado anterior por cerca de 300 ms. A faixa inferior usa 75 unidades na referência de 540 × 960, simulando 50 dp numa tela de 360 dp de largura. Unidades Godot não equivalem diretamente a dp. A dimensão definitiva virá da medição do SDK nativo e será convertida para a área jogável; ainda não há anúncio real. A grade adapta a altura dos tubos e suporta até três linhas e quatro colunas, preservando áreas de toque de pelo menos 88 unidades de largura.

## Refinamento de seleção e campanha

Somente a origem selecionada recebe elevação de 4 unidades e um pequeno marcador acima da boca, em 160 ms. Não há cápsula de fundo nem alteração no contorno. A espessura do contorno fica em 1,4 unidade tanto selecionado quanto em repouso. Reiniciar saiu da barra superior e permanece no menu da fase. A barra tem 80 unidades de altura e todos os controles, incluindo o tema global, compartilham a mesma linha central.

A paleta foi ampliada com sky `#A2C7E7`, sage `#9DBDA3`, rose `#D9A5C0`, peach `#EFCBA4`, indigo `#AAA9D9` e mint `#C5DFBE`, mantendo as quatro cores anteriores. Cada uma possui símbolo próprio na opção de daltonismo. A dificuldade maior combina mais tubos, cores e misturas.

## Aproveitamento vertical

As células usam 26 unidades acima do corpo e 6 abaixo, com 12 entre fileiras. A altura do corpo é calculada pelo espaço disponível até a margem do banner, limitada a 300 unidades. Mensagens transitórias ficam na margem acima do banner e não reservam uma linha vazia na grade. Na referência 540 × 960, três fileiras passam de aproximadamente 135 para 178 unidades de corpo por tubo.

Os toggles possuem cores e fundos explícitos nos estados normal, hover, pressionado, hover com estado ativo, desativado e foco. Texto mantém contraste nos temas claro e escuro, inclusive com o toggle ativo sob o cursor.

## Paleta de areia por tema

Os identificadores e famílias de cor continuam iguais; o modo escuro recebe tons menos luminosos. O contorno e o tamanho dos tubos permanecem iguais. Partículas claras usam menor opacidade no escuro para evitar aparência brilhante.

| Cor | Claro | Escuro |
|---|---|---|
| Coral | `#EBC4BC` | `#B8796C` |
| Turquesa | `#BBDADD` | `#5D9E9B` |
| Dourado | `#E8D9B1` | `#B49B58` |
| Lavanda | `#D9D0E9` | `#9880B2` |
| Azul | `#A2C7E7` | `#6694BB` |
| Sálvia | `#9DBDA3` | `#6D9274` |
| Rosa | `#D9A5C0` | `#AA718E` |
| Pêssego | `#EFCBA4` | `#BD8B60` |
| Índigo | `#AAA9D9` | `#7D7CAF` |
| Menta | `#C5DFBE` | `#8AA77E` |

A paleta é compartilhada por areia, corrente, cadeados e demonstrações. Trocar o tema durante o despejo ou o desfazer atualiza a corrente também. Símbolos de acessibilidade usam tinta adequada a cada paleta, com contraste conferido; camadas ocultas continuam neutras e sem símbolos.
