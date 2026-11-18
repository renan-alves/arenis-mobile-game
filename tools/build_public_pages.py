"""Generate the public homepage and terms using the existing static site assets."""
from html import escape
from pathlib import Path
from urllib.parse import quote

DATE = "2026-11-17"

def build_public_pages(site: Path, email: str, draft: bool = False):
    contact = (f'<a href="mailto:{quote(email, safe="@.+-_")}">{escape(email)}</a>'
               if not draft else 'Contato a definir')
    robots = '<meta name="robots" content="noindex,nofollow">' if draft else ''
    banner = '<p class="draft">Rascunho local: contato público pendente.</p>' if draft else ''
    def page(title, description, body, assets, current):
        links = [("Início", assets, "home"), ("Privacidade", assets + "privacy/", "privacy"),
                 ("Termos de uso", assets + "terms/", "terms")]
        nav = ''.join(f'<a href="{url}"' + (' aria-current="page"' if key == current else '') + f'>{label}</a>' for label, url, key in links)
        return f'''<!doctype html>
<html lang="pt-BR"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1">{robots}
<meta name="color-scheme" content="light dark"><meta name="description" content="{escape(description, quote=True)}">
<title>{escape(title)} · Arenis: Sand Sort Challenge</title>
<link rel="stylesheet" href="{assets}styles.css"><link rel="icon" type="image/svg+xml" href="{assets}mascot.svg"></head>
<body><div class="page"><header><a class="brand" href="{assets}"><img src="{assets}mascot.svg" width="56" height="56" alt=""><span><b>arenis</b><small>Sand Sort Challenge</small></span></a>
<nav aria-label="Navegação principal">{nav}</nav></header><main>{banner}{body}
<aside class="contact"><h2>Suporte e contato</h2><p>{contact}</p></aside></main>
<footer><span>Arenis: Sand Sort Challenge · © 2026 Renan Alves</span><span><a href="{assets}privacy/">Política de Privacidade</a> · <a href="{assets}terms/">Termos de uso</a></span></footer></div></body></html>
'''
    home = '''<div class="intro"><p class="eyebrow">Arenis: Sand Sort Challenge · Android</p>
<h1>Um pouco de areia.<br>Uma nova possibilidade.</h1>
<p class="lead">Organize areias coloridas em tubos de ensaio. Planeje cada transferência até preencher cada tubo com uma única cor, no seu ritmo.</p>
<p class="date">Em desenvolvimento · Ainda não disponível na Google Play</p></div>
<div class="summary"><div><strong>Sem cronômetro</strong><p>Observe, experimente e encontre seu caminho.</p></div><div><strong>Três dificuldades</strong><p>Fácil, Intermediário e Difícil, com progressão por níveis.</p></div><div><strong>Um visual tranquilo</strong><p>Contornos leves, temas claro e escuro e um mascote curioso.</p></div></div>
<article><section id="jogo"><h2>Como funciona</h2><p>Toque em um tubo e escolha outro para transferir o bloco de areia da cor que está no topo. O destino pode receber areia de qualquer cor, desde que esteja desbloqueado e tenha espaço; se o espaço for menor, parte do bloco é transferida.</p><p>Você conclui o nível quando todos os tubos com areia estão cheios e contêm uma única cor. Tubos vazios podem permanecer como apoio. Suas estrelas dependem da quantidade de movimentos, incluindo o desfazer.</p></section>
<section id="recursos"><h2>Mais possibilidades a cada nível</h2><p>O jogo reúne 150 níveis predefinidos, com areia escondida e tubos trancados introduzidos ao longo da progressão. O app tem português, inglês e espanhol da América Latina, além de símbolos opcionais para ajudar a distinguir as cores.</p><p>As partidas e preferências ficam no dispositivo. A sincronização de resultados concluídos com o Google Play Games será opcional nas versões que disponibilizarem o recurso.</p></section>
<section id="suporte"><h2>Publicidade e privacidade</h2><p>O modelo previsto é gratuito, com banners e anúncios intersticiais entre partidas, sem recompensas ligadas a anúncios. Consulte a <a href="privacy/">Política de Privacidade</a> e os <a href="terms/">Termos de uso</a> para saber mais.</p><p>Desenvolvido de forma independente por Renan Alves. Para dúvidas sobre o jogo ou seus dados, use o contato abaixo.</p></section></article>'''
    (site/'index.html').write_text(page('Jogo de organizar areias', 'Conheça Arenis: Sand Sort Challenge, um jogo para Android de organizar areias coloridas, sem cronômetro, com três dificuldades.', home, './', 'home'), encoding='utf-8')
    sections = [
        ('sobre', '1. Sobre o jogo e estes termos', 'Estes termos descrevem o uso de Arenis: Sand Sort Challenge, jogo para Android desenvolvido de forma independente por Renan Alves. O app está em desenvolvimento; recursos podem depender da versão instalada. Leia estes termos e a Política de Privacidade antes de utilizar o jogo. Para dúvidas, entre em contato pelo e-mail ao final.'),
        ('uso', '2. Uso do aplicativo', 'Você pode instalar e utilizar o jogo para seu entretenimento pessoal. Utilize o app de forma lícita e respeite os direitos de outras pessoas. Não utilize o aplicativo para distribuir código malicioso, obter acesso indevido a serviços ou explorar falhas para prejudicar outros usuários. Estas condições não restringem usos permitidos por lei nem as licenças próprias dos componentes de terceiros.'),
        ('progressao', '3. Progresso e resultados', 'O progresso e as preferências são armazenados no dispositivo. Desinstalar o app ou apagar seu armazenamento pode eliminar os dados locais. Atualizações podem alterar níveis e regras; resultados incompatíveis podem deixar de contar para a progressão atual. A sincronização com Google Play Games, quando disponível, é opcional e abrange resultados concluídos, sem incluir partidas em andamento ou preferências. Falhas de conexão ou diferenças entre versões podem afetar a sincronização.'),
        ('google', '4. Serviços do Google e publicidade', 'O modelo previsto é gratuito e financiado por banners e anúncios intersticiais, sem recompensas por assistir a anúncios. A disponibilidade dos anúncios e do Google Play Games depende de serviços externos, conexão e configurações aplicáveis. O uso desses serviços está sujeito também aos respectivos termos do Google. As escolhas de privacidade e o tratamento de dados são explicados na Política de Privacidade do Arenis.'),
        ('idade', '5. Crianças e adolescentes', 'Arenis é destinado ao público geral. O uso por crianças e adolescentes deve observar a legislação aplicável e as condições de idade dos serviços utilizados. Quando necessário, pais ou responsáveis devem orientar e acompanhar o uso. A classificação etária e a disponibilidade serão informadas na página da loja quando o jogo for publicado.'),
        ('direitos', '6. Conteúdo e componentes', 'A marca, os elementos visuais e outros conteúdos do Arenis são protegidos pelos direitos aplicáveis. Estes termos não transferem a titularidade desses conteúdos. Componentes de terceiros, fontes e recursos com licenças próprias continuam sujeitos às respectivas licenças e créditos. A disponibilidade de um repositório público, por si só, não concede direitos adicionais sobre todo o seu conteúdo.'),
        ('funcionamento', '7. Funcionamento e seus direitos', 'O app pode receber correções e mudanças, e serviços externos podem ter interrupções. Se encontrar um problema, informe a versão do app e descreva o ocorrido ao suporte. Nenhuma disposição destes termos exclui ou limita direitos obrigatórios do consumidor, garantias legais ou responsabilidades que não possam ser afastadas pela legislação aplicável.'),
        ('alteracoes', '8. Atualizações destes termos', 'Podemos atualizar estes termos para refletir mudanças do app ou de seus serviços. A data desta página identifica a versão vigente. Mudanças relevantes serão comunicadas pelos meios adequados; quando uma nova manifestação for exigida pela legislação aplicável, ela será solicitada.'),
        ('contato', '9. Contato e privacidade', 'Para suporte, dúvidas sobre estes termos ou solicitações de privacidade, utilize o e-mail abaixo. Envie apenas as informações necessárias para tratar sua solicitação. Consulte também a Política de Privacidade para conhecer os dados utilizados pelo jogo e as opções disponíveis.'),
    ]
    content = '<div class="intro"><p class="eyebrow">Arenis: Sand Sort Challenge</p><h1>Termos de uso</h1><p class="lead">Condições de uso do jogo e informações sobre seus serviços.</p><p class="date">Atualizados em <time datetime="' + DATE + '">17 de novembro de 2026</time></p></div><article>'
    for sid, title, paragraph in sections:
        content += f'<section id="{sid}"><h2>{escape(title)}</h2><p>{escape(paragraph)}</p>'
        if sid == 'google':
            content += '<p><a href="https://policies.google.com/terms?hl=pt-BR">Termos de Serviço do Google</a> · <a href="../privacy/">Política de Privacidade do Arenis</a></p>'
        content += '</section>'
    content += '</article>'
    (site/'terms').mkdir(exist_ok=True)
    (site/'terms/index.html').write_text(page('Termos de uso', 'Termos de uso de Arenis: Sand Sort Challenge. Progresso, publicidade, serviços externos e contato.', content, '../', 'terms'), encoding='utf-8')
