# Complemento da fase 5 — Página de privacidade

Data: 12/11/2026. Repositório oficial: `C:\git-workspace\arenis-mobile-game`.

## Resultado

Página estática da Política de Privacidade preparada em pt-BR, en e es-419, com contato público `support.arenis@gmail.com`. Segue a identidade outline e os temas claro/escuro do Arenis, com fonte e mascote locais. Quatro documentos HTML disponibilizam o conteúdo integral e navegação entre idiomas, sem depender de scripts ou redirecionamentos.

O texto foi confrontado com os serviços implementados: armazenamento local, AdMob/UMP, Google Play Games opcional, união de conclusões e exclusão independente de dados locais/remotos. Há referências às políticas e instruções dos provedores. Não foi publicado um formulário sem contato, uma declaração de “nenhuma coleta” ou uma promessa de que desligar a sincronização apaga dados na nuvem.

## Validação

Validação estática das quatro páginas, 12 seções por página, três idiomas e 60 links. Presença do contato, títulos, idioma, data, arquivos locais e licença da fonte conferida. Ausência de scripts, iframes, formulários e recursos remotos verificada. O validador rejeita rascunho com contato pendente.

Microsoft Edge: seis prévias, uma combinação móvel clara (390 px) e desktop escura (1280 px) para cada idioma, sem erros de página ou overflow horizontal. Foram inspecionadas visualmente as prévias em português claro e inglês escuro.

Não houve alteração nas regras, na campanha, no áudio ou no APK; a suíte do jogo não foi repetida por essa mudança de documentos e hospedagem. Os scripts e o workflow da página foram preparados separadamente do build Android.

## Publicação — atualização após autorização

A preparação inicial não executou alterações remotas. Após autorização explícita do usuário, a página foi enviada ao GitHub e implantada com sucesso. O endereço final é `https://arenis.frontmakers.com/privacy/`; o DNS, o certificado e o redirecionamento HTTPS foram concluídos e validados.

O remoto estava vazio no início. O commit inicial publicou somente a página, os dois scripts e o workflow. Depois foi publicado o `.gitignore` para proteger arquivos locais e materiais de assinatura. O restante do trabalho do app não integrou esses commits.

O [guia de publicação](../publicacao-privacidade.md) registra arquivos, referências, comandos e pendências. A URL dentro do app e as declarações do Play Console seguem após a publicação. Modelo de continuidade acordado: GPT-6.1 Sol, raciocínio Alto.

## Evidência da implantação e proteção de credenciais

- Commit da página: `b130f96e35e311d5f2b3764b9819ca47b50546a1`.
- Commit das exclusões de credenciais: `e517c38`.
- [Implantação GitHub Actions concluída com sucesso](https://github.com/renan-alves/arenis-mobile-game/actions/runs/43339561444).
- GitHub Pages ativado com origem `workflow` e domínio `arenis.frontmakers.com` associado.
- Português, inglês e espanhol servidos com HTTP 200, nome do app e contato corretos, usando resolução temporária da requisição para o servidor GitHub. Esse teste não altera DNS nem comprova HTTPS do domínio.
- DNS CNAME ainda ausente na conferência; certificado não emitido e `https_enforced=false`. Configuração na Squarespace é a próxima etapa.
- Auditoria do histórico inicial: um commit, 13 blobs únicos, nenhuma ocorrência nos padrões de credenciais examinados. O `.gitignore` enviado depois contém apenas regras de exclusão.
- Secret scanning e push protection confirmados como ativos; zero alertas abertos no GitHub no momento da consulta.
- Arquivos `.env`, contas de serviço, credenciais locais, chaves privadas, keystores e saídas Android excluídos pelo `.gitignore` versionado. Doze casos de caminhos sensíveis e quatro caminhos de exemplos públicos conferidos.
- Autoria dos commits usa o endereço noreply do GitHub. O contato público da política foi informado expressamente pelo usuário.

A auditoria se limita ao conteúdo publicado e aos padrões consultados; as proteções não dispensam a revisão dos arquivos em futuros commits. Nenhum token, senha ou chave privada foi incluído nos commits desta entrega.

## Validação do apontamento DNS

O usuário adicionou o CNAME na Squarespace. O DNS público confirmou arenis.frontmakers.com → renan-alves.github.io, e a política respondeu HTTP 200 pelo hostname real. A análise do GitHub confirmou domínio válido e elegível a HTTPS, sem erro CAA. A emissão do certificado permanece sendo verificada antes de liberar a URL HTTPS para o AdMob.

## Domínio e HTTPS concluídos

A política está disponível em https://arenis.frontmakers.com/privacy/. O GitHub emitiu certificado aprovado para o domínio e HTTPS obrigatório foi ativado. As políticas em pt-BR, en e es-419 e os recursos CSS, mascote e fonte responderam HTTPS 200, sem ignorar validação de certificado. HTTP redirecionou com 301 para a mesma URL em HTTPS. O conteúdo servido confirmou os idiomas e o contato support.arenis@gmail.com.

A emissão foi reiniciada uma única vez pela reaplicação do domínio após a validação do CNAME. O DNS foi configurado pelo usuário na Squarespace. O registro não foi alterado pelo agente. Evidência: [verificação do domínio](fase-05-dominio-verificacao.json). A URL já pode ser cadastrada na mensagem AdMob; a publicação dessa mensagem continua no painel do usuário.
