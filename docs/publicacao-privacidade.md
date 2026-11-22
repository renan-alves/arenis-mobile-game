# Política de privacidade — preparação e publicação

Preparada em 12/11/2026 para Arenis: Sand Sort Challenge. Contato público escolhido pelo usuário: `support.arenis@gmail.com`. Desenvolvedor identificado no texto: Renan Alves.

## Arquivos preparados

- `website/privacy/index.html`: português brasileiro.
- `website/privacy/en/index.html`: inglês.
- `website/privacy/es-419/index.html`: espanhol latino-americano.
- `website/index.html`: a política completa em português também abre na raiz.
- `website/styles.css`, `mascot.svg` e `fonts/`: identidade aprovada e recursos locais, incluindo licença da fonte Manrope.
- `website/.gdignore`: impede que a página seja importada como parte do projeto Godot.
- `tools/build_privacy_site.py`: texto fonte das três traduções e gerador estático.
- `tools/check_privacy_site.py`: valida contato, idiomas, estrutura, links e ausência de conteúdo ativo.
- `.github/workflows/privacy-pages.yml`: publica somente `website/` via GitHub Pages depois que o serviço estiver ativado. Não envia APK, configurações locais ou código do jogo para o artefato do site.

Nenhuma publicação é realizada pela geração dos arquivos. Não é necessário comprar domínio para a URL do GitHub Pages.

## Conteúdo conferido

O texto reflete `scripts/progress.gd`, `preferences.gd`, `service_state.gd`, `android_services.gd`, `cloud_records.gd`, o manifesto e o plugin Java. Descreve salvamento local, tratamento dos SDKs Google, consentimento e sua reabertura, sincronização opcional apenas de conclusões, retenção/exclusão, contato, direitos, famílias e hospedagem.

O app não usa backend próprio. Não foram declarados anonimato completo, ausência de coleta por SDKs ou exclusão remota ao apenas desativar sincronização. A conexão Play Games é descrita de forma condicional porque ainda depende da configuração do serviço. O texto não declara a aprovação da conta AdMob nem da publicação na Play Store.

A classificação de público geral já foi definida para o produto; a faixa etária exata, as declarações do console e os requisitos de publicidade para os públicos selecionados ainda precisam ser fechados na homologação. A política não substitui essas configurações. Se o comportamento ou os serviços mudarem, atualizar o texto e a data antes da distribuição correspondente.

## Regenerar e verificar

Na raiz do repositório:

```powershell
python tools/build_privacy_site.py --contact-email support.arenis@gmail.com
python tools/check_privacy_site.py
```

`--draft` gera uma prévia marcada como rascunho e sem contato. A validação e o workflow rejeitam esse estado para publicação. O gerador reutiliza as cópias da fonte/mascote em `website/` se os assets do jogo não estiverem presentes no checkout.

Foram verificadas quatro páginas, três idiomas e 60 links locais/externos quanto ao formato e aos destinos locais. O validador não faz promessas sobre a disponibilidade futura dos links externos. A prévia no Microsoft Edge passou em seis combinações: português/inglês/espanhol em claro a 390 px e escuro a 1280 px, sem erro JavaScript ou rolagem horizontal. As páginas não executam JavaScript nem incluem formulários, anúncios, fontes externas ou ferramentas de análise. O GitHub continua podendo registrar requisições de hospedagem, conforme sua política.

## Publicar depois da revisão

O repositório `renan-alves/arenis-mobile-game` é público e a conta tem acesso de administração. Na conferência inicial, o remoto estava vazio e o GitHub Pages não estava configurado. A branch local é `main`, sem commits; todo o trabalho do app permanece não rastreado.

A publicação deve criar um commit inicial contendo somente `website/`, os dois scripts de privacidade e `.github/workflows/privacy-pages.yml`, sem usar `git add .`. O envio desse commit para `main` e a ativação do GitHub Pages são alterações remotas, que serão realizadas depois da autorização de publicação. O restante do projeto permanece local até um envio próprio.

No GitHub: **Settings → Pages → Build and deployment → Source → GitHub Actions**. Depois da ativação, executar **Actions → Publish Arenis privacy page → Run workflow**. O workflow também publicará novas alterações em `website/` enviadas à `main`.

Endereço esperado, ainda não publicado na preparação:

```text
https://arenis.frontmakers.com/privacy/
```

Somente depois de confirmar resposta HTTPS 200 e conferir o texto servido, informar essa URL em **AdMob → Privacidade e mensagens → mensagem europeia → Selecionar apps → Adicionar URL**. Não usar uma URL de exemplo, um endereço `file://`, o repositório de código ou um PDF como substituto da página.

O link dentro do aplicativo e no Play Console deve ser configurado depois que a URL pública estiver ativa. A etapa de `app-ads.txt` é separada: o crawler busca o arquivo na raiz do domínio usado como site do desenvolvedor; a URL por projeto da política não configura automaticamente esse arquivo na raiz de `renan-alves.github.io`.

## Fontes oficiais

- [Requisitos de política de privacidade do Google Play](https://support.google.com/googleplay/android-developer/answer/10144311?hl=pt-BR).
- [URL da política nas mensagens AdMob](https://support.google.com/admob/answer/10113106?hl=pt-BR).
- [Dados tratados pelo SDK Mobile Ads](https://developers.google.com/admob/android/privacy/play-data-disclosure).
- [Dados do SDK Play Games](https://developer.android.com/games/pgs/data-collection).
- [Excluir dados do Play Games](https://support.google.com/googleplay/answer/9130646?hl=pt-BR).
- [Privacidade do Google](https://policies.google.com/privacy) e [privacidade do GitHub](https://docs.github.com/site-policy/privacy-policies/github-general-privacy-statement).
- [Criar um GitHub Pages](https://docs.github.com/pt/pages/getting-started-with-github-pages/creating-a-github-pages-site) e [workflow de publicação](https://docs.github.com/en/pages/getting-started-with-github-pages/using-custom-workflows-with-github-pages).

## Domínio próprio informado

O usuário informou frontmakers.com, com DNS na Squarespace. A proposta atual é arenis.frontmakers.com, usando GitHub Pages com domínio personalizado. O vínculo em Pages precisa ser feito antes do CNAME. Consulte [configuração do domínio](dns-frontmakers.md). A publicação foi autorizada e a implantação GitHub foi concluída. O domínio foi associado ao Pages; o usuário configurou o DNS na Squarespace e DNS/HTTPS foram conferidos. A URL https://arenis.frontmakers.com/privacy/ está pronta para uso.
