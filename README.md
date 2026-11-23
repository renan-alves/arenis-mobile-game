# Arenis: Sand Sort Challenge

Jogo Android em Godot 4.7.2 e GDScript, com identidade outline, cores suaves e uma campanha única de 150 níveis. Repositório oficial: https://github.com/renan-alves/arenis-mobile-game

## Executar

Importe `project.godot` no Godot padrão (não exige .NET) e pressione F5. A tela inicial abre o mapa e o botão Jogar/Continuar aponta para a fase atual.

```powershell
.\tools\play.ps1 -GodotPath 'C:\caminho\Godot_v4.7.2-stable_win64_console.exe'
```

Toque no tubo de origem e depois em um tubo vazio ou com a mesma cor no topo. Só o bloco superior é despejado, inclusive parcialmente. Um destino incompatível com areia vira a nova origem; tocar novamente na origem cancela a seleção. Desfazer também custa uma jogada. Voltar abre o menu da fase, onde fica Reiniciar.

## Versão 0.6.0 — jornada

- 150 fases fixas com solução e mínimo comprovados, desbloqueadas em sequência e rejogáveis.
- Dificuldade crescente: de três tubos a onze, capacidades de três a sete unidades e até nove cores.
- Introdução de limite de jogadas no nível 16, areia escondida no 26, tempo no 48 e combinação com trancas no 61. Há fases livres entre desafios.
- Limites de jogadas e tempo alternados. Cronômetro iniciado na primeira jogada, pausado em animações, menus e segundo plano. Tentativas ilimitadas.
- Mapa de jornada como início, fundo vetorial de deserto e tubos com reflexos discretos de vidro.
- Temas claro/escuro, português brasileiro, inglês e espanhol latino-americano; símbolos opcionais, efeitos de areia e mascote animado.
- Tentativa local única com desfazer, descobertas e tempo persistidos. Sincronização opcional de conclusões, estrelas e recordes pelo Play Games.

O progresso da beta anterior foi separado por autorização do responsável: novo arquivo local `journey_progress.cfg`, novas regras 3 e snapshot `arenis_journey_v1`. Preferências e escolha de sincronização permanecem. O APK de desenvolvimento continua usando anúncios de teste.

## Revisão 0.6.1 — publicidade

Banner mantido em todas as telas. Níveis 1–10 são isentos de anúncios de tela cheia, inclusive rejogadas. Depois, são necessárias cinco conclusões e um intervalo de cinco minutos, somente na saída do resultado. Os limites persistem entre sessões; a sincronização continua automática também nos níveis isentos. [Relatório da revisão](docs/relatorios/revisao-publicidade-0.6.1.md).

## Verificar

```powershell
.\tools\check.ps1 -GodotPath 'C:\caminho\Godot_v4.7.2-stable_win64_console.exe'
```

As suítes verificam regras, busca exata contra BFS independente, certificados de todos os tabuleiros, diário de ações, limites, sincronização, traduções, animações e encaixe das telas. O solver é offline e não roda durante o jogo.

```powershell
godot --headless --path . --script tools/validate_journey.gd
```

Esse comando revalida os 150 mínimos com testemunhas verificadas e grava `tmp/journey-certified.json`. Um limite de busca não comprova mínimo nem impossibilidade. Consulte [formato e autoria](docs/formato-fases.md) para acrescentar níveis.

## Android e documentação

- [Build, instalação e configuração dos serviços](docs/android.md)
- [Produto atual](docs/produto.md) e [regras atuais](docs/regras.md)
- [Identidade visual](docs/identidade-visual.md) e [brief do mascote](docs/brief-visual.md)
- [Relatório da reestruturação 0.6.0](docs/relatorios/reestruturacao-0.6.md)
- [Certificados das 150 fases](docs/relatorios/jornada-v3-provas.json)
- [Privacidade e página pública](https://arenis.frontmakers.com/)

Relatórios anteriores em `docs/relatorios/` descrevem as versões correspondentes. As campanhas por dificuldade e as regras de despejo sobre cores diferentes são históricas e não certificam a versão atual. O jogo ainda não foi lançado na Google Play.

O repositório é público. Caminhos locais, credenciais, chaves de assinatura e configurações privadas de serviços ficam fora do Git. Não envie senhas, arquivos de conta de serviço ou keystores ao repositório.
