# Relatório da fase 3 — Identidade visual e mascote

Data: 12/11/2026. Estado: **conceitos prontos para avaliação; fase em andamento**.

Modelo indicado no roteiro: GPT-6.1 Sol, esforço extra alto. A configuração do seletor é controlada pelo usuário.

## Direção e entrega desta rodada

Aplicada a preferência do usuário por estilo outline, tons pastéis e visual clean. Os estudos usam contornos arredondados, preenchimento discreto, fundo off-white e cores suaves com texto e olhos escuros. A prancha inclui uma aplicação em fundo escuro.

Foram preparados três mascotes originais: A, triângulo suave; B, círculo; C, quadrado suave. Todos contêm somente uma forma e dois olhos, sem boca, membros, sobrancelhas ou acessórios. A é a sugestão por evocar um grão arredondado; a escolha final pertence ao usuário.

O pacote tem três assinaturas de marca, três estudos de ícone do aplicativo, seis versões de mascote (claro/escuro), 12 ícones de interface, paleta e proposta tipográfica Manrope com fonte e licença incluídas. São conceitos editáveis em SVG, ainda não um pacote final de exportação Android.

A prévia offline permite comparar silhuetas, alternar temas, retirar o preenchimento pastel, piscar e observar o olhar. Uma demonstração faz os olhos passarem pela origem, acompanhar a trajetória da areia e chegar ao destino. Em repouso, o movimento é lento e as piscadas discretas. Também há GIF da opção A para avaliação rápida.

## Arquivos para avaliar

- `design/concepts/v1/index.html`: prévia interativa offline. Abrir no navegador.
- `design/concepts/v1/previews/concept-board.png`: prancha completa.
- `design/concepts/v1/previews/mascot-options.png`: comparação A/B/C.
- `design/concepts/v1/previews/mascot-motion-a.gif`: olhar e piscada da sugestão A.
- `design/concepts/v1/mascots/`, `logos/`, `icons/`: originais vetoriais.
- `design/concepts/v1/README.md`: direção, especificações e regeneração.
- `design/concepts/v1/source/`: gerador dos vetores, renderização e captura reproduzível.

## Decisões de construção

Os recursos são vetoriais nativos: corpo e olhos separados permitem alterar o olhar e piscar sem recriar a arte. As letras das assinaturas e da prancha estão convertidas em curvas; a prévia usa o arquivo da fonte local. A prévia não carrega bibliotecas nem fontes remotas.

Olhar limitado a aproximadamente 5,5 unidades horizontais e 5 verticais sobre uma base 128. Mudanças suaves; piscada de cerca de 220 ms na prévia. A ociosidade cede prioridade ao despejo e aos eventos de interação. O usuário pode desativar o comportamento automático; a preferência de redução de movimento do sistema é considerada na abertura.

Fonte proposta: [Manrope no Google Fonts](https://github.com/google/fonts/tree/main/ofl/manrope), com `OFL.txt` preservado. O estudo não atribui nome próprio ao mascote e mantém o título oficial em inglês. As telas usam Nível 1; Level 1 e Nivel 1 continuam previstos para a localização.

## Verificação realizada

- 26 SVGs analisados como XML, com viewBox, IDs únicos e separação de corpo/olhos em todos os mascotes individuais.
- SVGs rasterizados no Godot 4.7.2 para inspecionar formas, textos, ícones e composição da prancha.
- Prévia executada em Chromium isolado, em viewports exatos de 1440 × 1320 e 390 × 2260.
- 12 verificações de interação por viewport: formas A/B/C, temas, preenchimento, seleção e olhar, piscada, bloqueio durante demonstração, conclusão e ausência de transbordamento horizontal.
- Capturas clara/escura e estreita inspecionadas; olhos presentes e legíveis. Métricas e resultados em `previews/browser-checks.json`.
- Pares de contraste conferidos: texto principal/fundo claro 8,31:1; texto secundário/superfície 4,98:1; texto secundário/fundo escuro 7,29:1; símbolos sobre coral e água 5,58:1 e 6,02:1. Os estados finais do aplicativo serão verificados quando a identidade for aplicada.

## Pendências para concluir a fase

Escolher ou refinar a silhueta e confirmar a direção da paleta, peso dos contornos e tipografia. Depois dessa revisão, finalizar recursos, exportações do ícone Android e animação integrada ao Godot. A prévia atual é um demonstrador visual; o jogo continua com a arte provisória enquanto a identidade está em revisão.

## Git e continuidade

Arquivos no repositório oficial `C:\git-workspace\arenis-mobile-game`, sem commit ou push. A fase 3 continua em revisão; não avançamos para a fase 4. Para os próximos ajustes visuais, permanece a indicação GPT-6.1 Sol, esforço extra alto.
