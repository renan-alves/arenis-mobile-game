# Arenis — identidade visual v0.1

## Direção de marca

Arenis é um quebra-cabeça de areia sereno, legível e tátil. A identidade combina superfícies claras, formas arredondadas e detalhes inspirados em vidro, água e dunas. A interface deve manter bastante respiro e deixar as cores da areia em destaque.

## Mascote

**Ari** (nome provisório) é uma única forma geométrica arredondada, inspirada em um grão de areia polido. Os únicos traços do personagem são os olhos. Não há corpo robótico, membros, boca, roupa ou acessórios. O desenho usa apenas a ideia geral de um personagem geométrico expressivo, sem reproduzir a silhueta ou os elementos distintivos do Grok Bot.

### Animação dos olhos

- Em repouso, o olhar fica centralizado e pisca ocasionalmente.
- Ao selecionar um frasco, as pupilas acompanham o frasco selecionado.
- Durante o despejo, o olhar acompanha o arco da areia até o destino.
- Se uma jogada não for permitida, o olhar pode apontar por um instante para o frasco de destino.
- Ao concluir uma fase, os olhos se abrem levemente e depois retornam ao repouso.

As animações são cosméticas: nunca mudam as regras ou o estado da fase. Na implementação, os olhos devem ser elementos separados do formato principal para permitir mover as pupilas e fechar as pálpebras sem redesenhar o personagem.

## Paleta

| Uso | Nome | Cor |
|---|---|---|
| Fundo principal | Papel de duna | `#F5F0E4` |
| Texto e contornos | Verde-petróleo | `#245358` |
| Areia principal | Âmbar | `#D7A35A` |
| Acento | Barro rosado | `#D77F68` |
| Acento secundário | Vidro-marinho | `#83ADA8` |
| Fundo auxiliar | Névoa clara | `#D9E7E2` |
| Texto secundário | Ardósia | `#53696A` |

As cores dos quebra-cabeças também recebem padrões ou símbolos, para que a identificação não dependa apenas da cor.

## Tipografia

Usar uma sans-serif arredondada e legível, com pesos semibold para títulos e regular para instruções. O SVG usa `Nunito Sans` com alternativas locais; a fonte final pode ser empacotada no jogo após a escolha/licença do arquivo.

## Formas e movimento

- Cantos suaves, contornos consistentes e poucos detalhes por ícone.
- Vidros translúcidos com bordas verde-petróleo discretas.
- Animações curtas e macias; grãos desenhados em posições determinísticas.
- Evitar brilho excessivo, ruído visual e sombras pesadas.

## Arquivos

- `assets/branding/arenis-logo.svg`: assinatura horizontal e escalável.
- `assets/branding/arenis-app-icon.svg`: conceito do ícone do aplicativo.
- `assets/branding/ari-mascot.svg`: forma principal e olhos do mascote vetorial.
- `assets/branding/arenis-ui-icons.svg`: prancha inicial de ícones da interface.

## Observações de produção

Estes SVGs são a primeira direção visual, feitos para revisão e refinamento. Antes da publicação, gerar versões rasterizadas nos tamanhos exigidos pelo Android e revisar contraste, legibilidade em tamanhos pequenos e visualização em telas claras e escuras.
