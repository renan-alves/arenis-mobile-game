# Fase 5 — Revisão das pendências de branding OAuth

Data: 17 de novembro de 2026.

O Google informou que a página inicial exigia login e que o nome não correspondia ao aplicativo.

## Diagnóstico

- O GitHub Pages está público, com HTTPS obrigatório e domínio arenis.frontmakers.com.
- As requisições HTTP anônimas com User-Agent de navegador, Googlebot e Google-InspectionTool retornaram HTTP 200 sem redirecionamentos nem exigência de autenticação. Esses testes não reproduzem o ambiente interno de revisão do Google.
- O nome completo já existia no texto auxiliar e rodapé, mas o h1 continha uma frase de apresentação. Não foi possível determinar a causa da detecção de login. Cache, processamento do serviço ou URL diferente cadastrada continuam hipóteses, sem confirmação.

## Alteração e validação

- O h1 e o título HTML da página inicial agora são exatamente Arenis: Sand Sort Challenge.
- Commit 59a3cce, somente dois arquivos: tools/build_public_pages.py e website/index.html.
- Validador do site: cinco páginas e 75 links verificados.
- Seis verificações de layout em Edge, com claro/mobile e escuro/desktop; sem transbordamento horizontal ou erros e com fonte local carregada. Captura da nova página conferida visualmente.
- Publicação concluída: https://github.com/renan-alves/arenis-mobile-game/actions/runs/44226165464 .
- Após a publicação, um contexto novo de navegador Edge, sem cookies prévios, acessou https://arenis.frontmakers.com/ com HTTP 200; título e h1 exatos; nenhum formulário ou campo de senha. Evidência em fase-05-oauth-branding-verificacao.json.

## Próxima ação na conta

Confirmar a URL exata https://arenis.frontmakers.com/ na configuração OAuth e solicitar nova verificação. Se o erro de login persistir, pedir análise adicional por discordância do resultado e informar o acesso público constatado. A aprovação depende do Google e não foi realizada pelo agente.
