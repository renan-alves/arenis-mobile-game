# Domínio do Arenis — frontmakers.com

Preparação em 12/11/2026. Domínio informado pelo usuário: `frontmakers.com`. Gestão de DNS informada: Squarespace. Subdomínio proposto para o jogo: `arenis.frontmakers.com`.

URL pretendida da política, depois da publicação e ativação do HTTPS:

```text
https://arenis.frontmakers.com/privacy/
```

Na consulta DNS desta preparação, `arenis.frontmakers.com` retornou NXDOMAIN para A, AAAA e CNAME. O domínio principal usa nameservers `ns-cloud-e1` a `ns-cloud-e4.googledomains.com`, compatíveis com domínios migrados para Squarespace. O painel autenticado de DNS não foi acessado, e nenhum registro foi criado ou modificado.

## Ordem de configuração

1. Revisar a página já pronta em `website/` e autorizar sua publicação com o endereço proposto.
2. Enviar somente os arquivos da página, seus dois scripts e o workflow ao repositório oficial; ativar GitHub Pages com origem GitHub Actions.
3. No GitHub, em **repositório → Settings → Pages → Custom domain**, vincular `arenis.frontmakers.com`. O domínio deve estar associado ao Pages antes de apontar o CNAME. A verificação de propriedade por TXT, nas configurações pessoais de Pages, também é recomendada pelo GitHub; seu valor é gerado pela conta, não deve ser inventado.
4. No painel Squarespace, abrir **Domains → frontmakers.com → DNS → DNS Settings → Custom Records → Add record** e adicionar o registro abaixo.
5. Conferir a resolução DNS, a implantação e o certificado. Ativar **Enforce HTTPS** no GitHub quando disponível. A propagação/certificado pode levar até 24 horas segundo o GitHub.
6. Conferir resposta HTTPS 200, textos e links da URL final antes de cadastrá-la no AdMob e no app.

## Registro de DNS previsto

| Campo Squarespace | Valor |
|---|---|
| Type | `CNAME` |
| Name / Host | `arenis` |
| Data / Target | `renan-alves.github.io` |
| TTL | Padrão do provedor |

O destino é apenas o hostname, sem `https://`, barras ou nome do repositório. O usuário verá o domínio personalizado no endereço da página; o destino técnico do DNS continua identificando a hospedagem GitHub.

Esta proposta cria um registro específico para `arenis`; não exige trocar nameservers nem editar os registros do domínio raiz, `www` ou e-mail. Se houver um registro novo para o mesmo host quando a configuração for feita, conferir a finalidade antes de substituí-lo.

O workflow existente publica por GitHub Actions. Nesse modo, o GitHub documenta que um arquivo `CNAME` no artefato é ignorado; o vínculo efetivo deve ser configurado em Pages. Não criar um arquivo `CNAME` e tratá-lo como configuração suficiente.

## Situação

Atualização após autorização: página publicada via GitHub Actions, com implantação concluída com sucesso, e GitHub Pages associado a `arenis.frontmakers.com`. Ainda falta adicionar o CNAME na Squarespace e conferir emissão/ativação de HTTPS. Nenhum DNS foi alterado pelo agente.

## Referências

- [Domínio personalizado e subdomínios no GitHub Pages](https://docs.github.com/en/pages/configuring-a-custom-domain-for-your-github-pages-site/managing-a-custom-domain-for-your-github-pages-site).
- [Verificar propriedade do domínio no GitHub](https://docs.github.com/en/pages/configuring-a-custom-domain-for-your-github-pages-site/verifying-your-custom-domain-for-github-pages).
- [Registros de hospedagem e CNAME na Squarespace](https://support.squarespace.com/hc/en-us/articles/31119879125645-DNS-records-for-web-hosting).

## DNS confirmado pelo usuário e validado

Após o usuário informar a criação do registro, a consulta pública DNS retornou CNAME de arenis.frontmakers.com para renan-alves.github.io. A política respondeu HTTP 200 pelo domínio real e continha nome e contato corretos. O GitHub indicou domínio válido e elegível a HTTPS, sem bloqueio de CAA. A primeira tentativa HTTPS falhou por certificado ainda não emitido; a emissão está sendo acompanhada. Nenhuma configuração de DNS foi alterada pelo agente.

## Configuração concluída

DNS público confirmado, domínio associado ao Pages, certificado aprovado e HTTPS obrigatório ativo. Políticas e recursos responderam HTTPS 200 e HTTP redirecionou com 301. URL pronta para uso no AdMob: https://arenis.frontmakers.com/privacy/. Consulte docs/relatorios/fase-05-dominio-verificacao.json para os resultados. As pendências descritas nas anotações anteriores foram resolvidas nesta validação.
