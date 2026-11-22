# Fase 5 — Identificador Android Frontmakers

Data: 12/11/2026. Alteração solicitada pelo usuário durante o cadastro no Play Console.

## Resultado

O identificador definitivo escolhido é `com.frontmakers.arenis`. Os presets de APK e AAB em `export_presets.cfg` e o guia `docs/android.md` foram atualizados. As credenciais Android do Play Games devem usar esse mesmo nome de pacote.

O APK de desenvolvimento foi recompilado na pasta oficial e substitui `build/android/arenis-debug.apk`. A versão permanece 0.5.0, código 5. Uma cópia do APK e das configurações anteriores foi preservada em uma pasta temporária antes da alteração.

## Verificação

- Exportação Android concluída com sucesso.
- `aapt` confirmou `com.frontmakers.arenis`, versão 0.5.0/código 5, API mínima 24 e target 36.
- Assinatura verificada pelo `apksigner`.
- As 150 fases, os três idiomas e a biblioteca ARM64 estão presentes no APK.
- Manifesto final não contém o identificador antigo e mantém o App ID público de teste do Google AdMob.
- Evidência, hash do novo APK e SHA-1 público do certificado de debug registrados em [fase-05-pacote-frontmakers.json](fase-05-pacote-frontmakers.json).

A suíte de regras não foi repetida: a alteração foi de configuração de exportação e documentação. Não houve teste de execução Android em aparelho nesta alteração. Os relatórios de verificações anteriores preservam o identificador e o hash dos artefatos que efetivamente verificaram naquele momento.

## Instalação e serviços

O Android trata pacotes diferentes como aplicativos independentes. Uma instalação anterior com `com.renanalves.arenis` não é atualizada nem tem seu progresso migrado automaticamente para o novo pacote. Nenhum dado do usuário foi apagado. O progresso da execução desktop do Godot não foi modificado.

Usar `com.frontmakers.arenis` no cadastro do app e nos clientes OAuth Android do Play Games. O ID do app AdMob e seus blocos permanecem os já cadastrados. Uma eventual vinculação futura à loja deve apontar para o novo pacote.

Nenhuma chave de assinatura de publicação, senha ou token foi criado ou publicado. Sem commit, push ou alteração dos serviços remotos nesta mudança; somente os arquivos locais autorizados e o APK foram atualizados.
