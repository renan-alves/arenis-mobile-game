# Fase 5 — Página inicial e termos para OAuth

Data: 17 de novembro de 2026.

## Resultado

Página inicial de apresentação em português e termos de uso em português preparados para o domínio já utilizado pelo Arenis. A Política de Privacidade continua disponível em português, inglês e espanhol da América Latina, com os mesmos textos de tratamento de dados e links para início e termos. As páginas em inglês e espanhol identificam que os termos estão em português.

- Página inicial: https://arenis.frontmakers.com/
- Privacidade: https://arenis.frontmakers.com/privacy/
- Termos: https://arenis.frontmakers.com/terms/
- Logo existente para envio ao OAuth: assets/branding/android/icon-512.png (PNG quadrado, 15.621 bytes).

A página inicial descreve as regras, as dificuldades, os recursos e o status em desenvolvimento, sem link fictício para a loja. Os termos abordam uso pessoal, progresso local, sincronização opcional, publicidade, serviços externos, menores, conteúdo, atualizações e contato. Direitos obrigatórios do consumidor são preservados; não há eleição de foro ou renúncia geral de responsabilidade.

## Validação

- Gerador e validador executados: cinco páginas, 75 links locais/esquemas verificados, sem scripts, formulários ou recursos carregados de terceiros.
- Seis cenários reais de navegador Edge: início, termos e política em 390 px/claro e 1280 px/escuro; fontes locais carregadas, sem erros nem rolagem horizontal.
- Capturas e dados locais: C:/Users/Renan/AppData/Local/Temp/arenis-public-pages/.
- Conferência visual das capturas da página inicial e dos termos realizada.
- Publicação concluída no commit `e2551c0`; workflow https://github.com/renan-alves/arenis-mobile-game/actions/runs/44221397783 concluído com sucesso.
- Cinco páginas públicas verificadas com HTTP 200, TLS validado e conteúdo esperado; evidências em `fase-05-oauth-site-verificacao.json`.
- A execução de publicação registrou avisos da plataforma sobre migração de Node 20 para 24 e do ubuntu-latest, sem impedir a implantação.

## Limites e próximos passos

Este trabalho prepara a identificação pública exigida pelo fluxo OAuth. Não publica o jogo nem conclui a verificação OAuth. Verificação de domínio no Google Search Console, quando solicitada, e credenciais Android continuam sendo etapas separadas.

A configuração pública não contém senhas, chaves privadas ou tokens. Apenas arquivos do site e suas ferramentas serão enviados neste commit; código do jogo, configurações locais e builds permanecem fora da publicação.

Referências: https://support.google.com/cloud/answer/15549049 e https://www.planalto.gov.br/ccivil_03/leis/l8078compilado.htm .
