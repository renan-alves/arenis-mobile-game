"""Generate the small, script-free privacy site; all assets are self-hosted."""
from pathlib import Path
import argparse
import html
import json
import re
import shutil
from urllib.parse import quote

ROOT = Path(__file__).resolve().parents[1]
APP = 'Arenis: Sand Sort Challenge'
DATE = '2026-11-19'
LINKS = {
    'ads': 'https://developers.google.com/admob/android/privacy/play-data-disclosure',
    'google': 'https://policies.google.com/privacy',
    'partners': 'https://policies.google.com/technologies/partner-sites',
    'delete': 'https://support.google.com/googleplay/answer/9130646',
    'github': 'https://docs.github.com/site-policy/privacy-policies/github-general-privacy-statement',
}

CONTENT = {
 'pt-BR': {
  'title': 'Política de Privacidade', 'date': 'Atualizada em 19 de novembro de 2026',
  'lead': 'Entenda como seus dados são tratados enquanto você joga, vê anúncios ou escolhe sincronizar seu progresso.',
  'contact': 'Contato de privacidade e suporte', 'languages': 'Idioma da página',
  'draft': 'Rascunho local: o contato público ainda precisa ser definido.',
  'summary': [('No aparelho', 'Partidas e preferências são salvas localmente.'), ('Anúncios', 'O Google trata dados para fornecer publicidade.'), ('Nuvem opcional', 'Somente conclusões e recordes são sincronizados.')],
  'sections': [
   ('sobre', '1. Sobre esta política', [
    'Esta política se aplica ao aplicativo Android Arenis: Sand Sort Challenge e a esta página. O jogo é desenvolvido de forma independente por Renan Alves. Para dúvidas ou solicitações de privacidade, use o contato indicado ao final.',
    'Você pode jogar sem criar um cadastro próprio do Arenis. Anúncios e sincronização dependem da disponibilidade dos serviços Google; a sincronização é uma escolha opcional e pode não estar disponível em versões de desenvolvimento.'
   ]),
   ('local', '2. Dados salvos no aparelho', [
    'O app guarda progresso, estrelas, melhores jogadas, a partida em andamento de cada dificuldade, histórico de desfazer, cores reveladas e trancas. Também salva idioma, tema, acessibilidade, áudio, tutoriais vistos, opção de sincronização e contador local de anúncios.',
    'Esses dados permitem retomar partidas, preservar suas escolhas e controlar a frequência dos anúncios. Não temos um servidor próprio para receber suas partidas em andamento ou preferências.'
   ]),
   ('anuncios', '3. Anúncios e dados do Google', [
    'O Arenis usa Google AdMob. O SDK trata IP (inclusive para localização aproximada), identificadores de publicidade/dispositivo e, quando aplicável, conta; interações com o app/anúncios; e diagnósticos. As finalidades incluem publicidade, medição e prevenção de fraude. O SDK protege a transmissão com TLS. Consulte {ads} e {google}.',
    'O jogo exibe banners e anúncios intersticiais em transições após resultados. Não há recompensas vinculadas a anúncios. O código do jogo não solicita câmera, microfone, contatos ou localização precisa.'
   ]),
   ('escolhas', '4. Suas escolhas sobre anúncios', [
    'A plataforma de consentimento do Google (UMP) verifica quais opções precisam ser apresentadas conforme a região e o estado do consentimento. Quando aplicável, você pode aceitar, recusar ou gerenciar finalidades e parceiros.',
    'Quando disponível, reabra as escolhas em Configurações → Conta e privacidade → Privacidade dos anúncios. O Android também oferece controles para o identificador de publicidade. Recusar a personalização não significa necessariamente deixar de receber anúncios. Saiba mais em {partners}.'
   ]),
   ('nuvem', '5. Sincronização opcional com Play Games', [
    'O SDK do Google Play Games é inicializado na abertura do app para preparar a conexão e pode reconhecer automaticamente um perfil já configurado no aparelho. Essa preparação usa os dados de conta e técnicos necessários ao serviço, conforme {google}. A criação automática de novos perfis permanece desativada; a conexão explícita pode apresentar a interface do Google.',
    'Se o recurso estiver disponível e você ativar Sincronizar progresso em Conta e privacidade, o Google Play Games autentica sua Conta do Google e armazena uma cópia das conclusões. O Google também trata os dados de conta e técnicos necessários ao seu serviço, conforme {google}.',
    'A cópia enviada pelo Arenis contém identificadores e revisões dos níveis, versão das regras, estrelas e melhores quantidades de jogadas. Partidas em andamento, desfazer, preferências e contador de anúncios não fazem parte dessa cópia. Desativar a sincronização interrompe a leitura e o envio de resultados pelo Arenis, mas não exclui cópias já salvas nem desconecta sua Conta do Google.'
   ]),
   ('contato', '6. Quando você entra em contato', [
    'Se enviar uma mensagem de suporte ou privacidade, trataremos seu e-mail e as informações fornecidas para responder e resolver a solicitação. Envie somente o necessário; não envie senhas ou documentos de identidade sem uma necessidade previamente esclarecida.'
   ]),
   ('exclusao', '7. Retenção e exclusão', [
    'Os dados locais permanecem até você limpar o armazenamento do Arenis nas configurações do Android ou desinstalar o app. Essa ação remove partidas e preferências locais; não exclui automaticamente dados mantidos pelo Google.',
    'Para remover o progresso na nuvem, desative a sincronização no Arenis e siga {delete}. Para evitar reenviar esse progresso, remova também a cópia local antes de voltar a ativar a sincronização. A exclusão pode causar perda definitiva de estrelas e recordes.',
    'Mensagens de contato são mantidas enquanto necessárias ao atendimento e ao cumprimento de obrigações aplicáveis. Google e GitHub mantêm dados dos seus serviços segundo as próprias políticas; não prometemos prazos ou exclusões que não controlamos.'
   ]),
   ('direitos', '8. Solicitações e direitos', [
    'Você pode usar o contato desta página para esclarecer o tratamento de dados ou solicitar acesso, correção, exclusão e outros direitos previstos pela legislação aplicável. As solicitações serão analisadas considerando os dados sob nosso controle e a necessidade de verificar a legitimidade do pedido. Para dados da sua Conta do Google, use também os controles do próprio Google.'
   ]),
   ('seguranca', '9. Serviços externos e segurança', [
    'Google fornece publicidade, consentimento e, quando ativada, sincronização. GitHub hospeda esta página. Esses serviços podem processar dados em países diferentes do seu, conforme suas políticas e mecanismos de proteção. Não publicamos seus resultados individuais nesta página.',
    'Adotamos medidas compatíveis com o funcionamento do app, como arquivos no espaço privado do aplicativo e uso dos SDKs oficiais. Nenhum sistema é totalmente imune a falhas; não compartilhe informações sensíveis em solicitações desnecessárias.'
   ]),
   ('familias', '10. Crianças e adolescentes', [
    'O Arenis é um jogo de público geral. O jogo não pede que crianças ou adolescentes informem nome, e-mail ou documentos para jogar. Responsáveis podem entrar em contato para esclarecer o uso de dados ou solicitar providências sobre informações sob nosso controle. O uso dos serviços Google também está sujeito às condições e configurações de idade desses serviços.'
   ]),
   ('pagina', '11. Esta página', [
    'Esta página não inclui anúncios, formulários, ferramentas de análise, scripts de terceiros ou fontes carregadas de outros serviços. Ao acessá-la, o provedor de hospedagem pode registrar IP e informações técnicas da requisição para operar e proteger o serviço. Consulte {github}.'
   ]),
   ('alteracoes', '12. Alterações e contato', [
    'Podemos atualizar esta política quando o app ou seus serviços mudarem. A data no início identifica esta versão. Mudanças que exigirem uma nova escolha serão apresentadas pelos mecanismos adequados do app. Para falar com o desenvolvedor: {email}.'
   ])
  ],
 },
 'en': {
  'title': 'Privacy Policy', 'date': 'Updated November 19, 2026',
  'lead': 'How your data is handled while you play, see ads or choose to sync your progress.',
  'contact': 'Privacy and support contact', 'languages': 'Page language',
  'draft': 'Local draft: a public contact email still needs to be provided.',
  'summary': [('On your device', 'Games and preferences are stored locally.'), ('Advertising', 'Google processes data to provide ads.'), ('Optional cloud save', 'Only completed levels and best scores are synced.')],
  'sections': [
   ('about', '1. About this policy', [
    'This policy applies to the Android app Arenis: Sand Sort Challenge and this page. The game is independently developed by Renan Alves. Use the contact at the end for privacy questions and requests.',
    'You can play without creating an Arenis account. Ads and sync depend on Google service availability. Sync is optional and may be unavailable in development versions.'
   ]),
   ('local', '2. Data stored on your device', [
    'The app stores progress, stars, best move counts, one ongoing game per difficulty, undo history, revealed colors and locks. It also stores language, theme, accessibility, audio, completed tutorials, sync preference and a local ad counter.',
    'These records let you resume games, keep your preferences and control ad frequency. We do not operate our own server to receive ongoing games or preferences.'
   ]),
   ('ads', '3. Advertising and Google data', [
    'Arenis uses Google AdMob. Its SDK processes IP addresses (including for approximate location), advertising/device and, where applicable, account identifiers; app/ad interactions; and diagnostics. Purposes include advertising, measurement and fraud prevention. SDK transmissions use TLS. See {ads} and {google}.',
    'The game displays banners and interstitials at transitions after results. Ads do not grant rewards. The game code does not request camera, microphone, contacts or precise location access.'
   ]),
   ('choices', '4. Your advertising choices', [
    'Google’s User Messaging Platform (UMP) checks which choices must be presented based on region and consent status. Where applicable, you can accept, decline or manage purposes and partners.',
    'Where available, reopen your choices under Settings → Account and privacy → Ad privacy. Android also provides advertising identifier controls. Declining personalization does not necessarily remove ads. Learn more at {partners}.'
   ]),
   ('cloud', '5. Optional Play Games sync', [
    'The Google Play Games SDK initializes when the app opens to prepare the connection and may automatically recognize a profile already configured on the device. This preparation uses account and technical data needed for the service under {google}. Automatic creation of new profiles stays disabled; an explicit connection may display Google’s interface.',
    'If the feature is available and you enable Sync progress in Account and privacy, Google Play Games authenticates your Google Account and stores a copy of completed results. Google also handles account and technical data needed for its service under {google}.',
    'The copy sent by Arenis contains level identifiers and revisions, rules version, stars and best move counts. It excludes ongoing games, undo history, preferences and the ad counter. Turning sync off stops Arenis from reading or uploading results, but does not delete previously stored copies or sign you out of your Google Account.'
   ]),
   ('contact', '6. When you contact us', [
    'If you send a support or privacy message, we process your email address and the information you provide to respond and resolve the request. Send only what is needed; do not send passwords or identity documents without a previously explained need.'
   ]),
   ('deletion', '7. Retention and deletion', [
    'Local data remains until you clear Arenis storage in Android settings or uninstall the app. This removes local games and preferences; it does not automatically delete data held by Google.',
    'To remove cloud progress, turn off sync in Arenis and follow {delete}. To prevent uploading it again, also remove the local copy before enabling sync again. Deletion may permanently remove stars and best scores.',
    'Contact messages are kept as needed to handle requests and meet applicable obligations. Google and GitHub retain their service data under their own policies; we do not promise retention periods or deletion outside our control.'
   ]),
   ('rights', '8. Requests and rights', [
    'Use the contact on this page to ask about data handling or request access, correction, deletion and other rights available under applicable law. Requests are assessed considering data under our control and any need to verify that the request is legitimate. Also use Google’s own controls for data in your Google Account.'
   ]),
   ('security', '9. External services and security', [
    'Google provides ads, consent and, when enabled, sync. GitHub hosts this page. These services may process data outside your country under their own policies and safeguards. We do not publish your individual results on this page.',
    'We use measures appropriate to the app, such as files in its private storage and official SDKs. No system is entirely immune to failures; do not share sensitive information in unnecessary requests.'
   ]),
   ('families', '10. Children and teenagers', [
    'Arenis is a general-audience game. The game does not ask children or teenagers for their name, email address or identity documents to play. Parents and guardians can contact us about data use or requests concerning information under our control. Google services are also subject to their own age conditions and settings.'
   ]),
   ('page', '11. This page', [
    'This page includes no ads, forms, analytics tools, third-party scripts or remotely loaded fonts. The hosting provider may log IP addresses and technical request information to operate and protect its service. See {github}.'
   ]),
   ('changes', '12. Changes and contact', [
    'We may update this policy as the app and its services change. The date above identifies this version. Changes requiring a new choice will use appropriate app mechanisms. Contact the developer at {email}.'
   ])
  ],
 },
 'es-419': {
  'title': 'Política de Privacidad', 'date': 'Actualizada el 19 de noviembre de 2026',
  'lead': 'Cómo se tratan tus datos mientras juegas, ves anuncios o eliges sincronizar tu progreso.',
  'contact': 'Contacto de privacidad y soporte', 'languages': 'Idioma de la página',
  'draft': 'Borrador local: falta definir el correo de contacto público.',
  'summary': [('En tu dispositivo', 'Las partidas y preferencias se guardan localmente.'), ('Publicidad', 'Google trata datos para mostrar anuncios.'), ('Nube opcional', 'Solo se sincronizan niveles completados y récords.')],
  'sections': [
   ('acerca', '1. Acerca de esta política', [
    'Esta política se aplica a la app para Android Arenis: Sand Sort Challenge y a esta página. El juego es desarrollado de forma independiente por Renan Alves. Para consultas y solicitudes de privacidad, utiliza el contacto al final.',
    'Puedes jugar sin crear una cuenta propia de Arenis. Los anuncios y la sincronización dependen de los servicios de Google. La sincronización es opcional y puede no estar disponible en versiones de desarrollo.'
   ]),
   ('local', '2. Datos guardados en el dispositivo', [
    'La app guarda progreso, estrellas, mejores cantidades de movimientos, una partida en curso por dificultad, historial de deshacer, colores revelados y bloqueos. También guarda idioma, tema, accesibilidad, audio, tutoriales vistos, preferencia de sincronización y un contador local de anuncios.',
    'Estos datos permiten retomar partidas, conservar preferencias y controlar la frecuencia de anuncios. No tenemos un servidor propio que reciba partidas en curso o preferencias.'
   ]),
   ('anuncios', '3. Anuncios y datos de Google', [
    'Arenis usa Google AdMob. Su SDK trata IP (incluida ubicación aproximada), identificadores publicitarios/del dispositivo y, cuando corresponde, de cuenta; interacciones con la app/anuncios; y diagnósticos. Las finalidades incluyen publicidad, medición y prevención de fraude. Las transmisiones usan TLS. Consulta {ads} y {google}.',
    'El juego muestra banners e intersticiales en transiciones después de los resultados. Los anuncios no otorgan recompensas. El código del juego no solicita acceso a cámara, micrófono, contactos ni ubicación precisa.'
   ]),
   ('opciones', '4. Tus opciones de publicidad', [
    'La plataforma UMP de Google comprueba qué opciones debe mostrar según la región y el estado del consentimiento. Cuando corresponde, puedes aceptar, rechazar o administrar finalidades y socios.',
    'Cuando esté disponible, reabre tus opciones en Configuración → Cuenta y privacidad → Privacidad de los anuncios. Android también ofrece controles del identificador publicitario. Rechazar la personalización no necesariamente elimina los anuncios. Consulta {partners}.'
   ]),
   ('nube', '5. Sincronización opcional con Play Games', [
    'El SDK de Google Play Games se inicializa al abrir la app para preparar la conexión y puede reconocer automáticamente un perfil ya configurado en el dispositivo. Esta preparación utiliza los datos de cuenta y técnicos necesarios para el servicio según {google}. La creación automática de nuevos perfiles permanece desactivada; la conexión explícita puede mostrar la interfaz de Google.',
    'Si la función está disponible y activas Sincronizar progreso en Cuenta y privacidad, Google Play Games autentica tu Cuenta de Google y guarda una copia de los resultados completados. Google también trata los datos de cuenta y técnicos necesarios para su servicio según {google}.',
    'La copia enviada por Arenis contiene identificadores y revisiones de niveles, versión de reglas, estrellas y mejores cantidades de movimientos. No incluye partidas en curso, deshacer, preferencias ni contador de anuncios. Desactivar la sincronización detiene la lectura y el envío de resultados por Arenis, pero no elimina copias guardadas ni cierra tu sesión de Google.'
   ]),
   ('contacto', '6. Cuando nos contactas', [
    'Si envías un mensaje de soporte o privacidad, trataremos tu correo y la información proporcionada para responder y resolver la solicitud. Envía solo lo necesario; no envíes contraseñas o documentos de identidad sin una necesidad previamente explicada.'
   ]),
   ('eliminacion', '7. Conservación y eliminación', [
    'Los datos locales permanecen hasta que borres el almacenamiento de Arenis en la configuración de Android o desinstales la app. Esto elimina partidas y preferencias locales; no borra automáticamente los datos que conserva Google.',
    'Para eliminar el progreso en la nube, desactiva la sincronización en Arenis y sigue {delete}. Para evitar volver a enviarlo, elimina también la copia local antes de reactivar la sincronización. La eliminación puede causar la pérdida definitiva de estrellas y récords.',
    'Los mensajes de contacto se conservan mientras sean necesarios para atender solicitudes y cumplir obligaciones aplicables. Google y GitHub conservan datos de sus servicios según sus propias políticas; no prometemos plazos ni eliminaciones fuera de nuestro control.'
   ]),
   ('derechos', '8. Solicitudes y derechos', [
    'Usa el contacto de esta página para consultar el tratamiento de datos o solicitar acceso, corrección, eliminación y otros derechos previstos por la legislación aplicable. Las solicitudes se evalúan según los datos bajo nuestro control y la necesidad de verificar su legitimidad. Para datos de tu Cuenta de Google, utiliza también los controles de Google.'
   ]),
   ('seguridad', '9. Servicios externos y seguridad', [
    'Google proporciona publicidad, consentimiento y, al activarla, sincronización. GitHub aloja esta página. Estos servicios pueden tratar datos fuera de tu país según sus políticas y mecanismos de protección. No publicamos tus resultados individuales en esta página.',
    'Utilizamos medidas adecuadas al funcionamiento de la app, como archivos en su almacenamiento privado y SDK oficiales. Ningún sistema es totalmente inmune a fallas; no compartas información sensible en solicitudes innecesarias.'
   ]),
   ('familias', '10. Niñas, niños y adolescentes', [
    'Arenis es un juego para público general. El juego no pide a niñas, niños o adolescentes nombre, correo ni documentos para jugar. Sus responsables pueden contactarnos sobre el uso de datos o solicitudes relacionadas con información bajo nuestro control. Los servicios de Google también están sujetos a sus propias condiciones y configuraciones de edad.'
   ]),
   ('pagina', '11. Esta página', [
    'Esta página no contiene anuncios, formularios, herramientas de análisis, scripts de terceros ni fuentes cargadas desde otros servicios. El proveedor de alojamiento puede registrar IP e información técnica de las solicitudes para operar y proteger su servicio. Consulta {github}.'
   ]),
   ('cambios', '12. Cambios y contacto', [
    'Podemos actualizar esta política cuando cambien la app o sus servicios. La fecha inicial identifica esta versión. Los cambios que requieran una nueva elección se presentarán mediante los mecanismos apropiados de la app. Contacta al desarrollador en {email}.'
   ])
  ],
 },
}

TERMS_LABELS = {'pt-BR': 'Termos de uso', 'en': 'Terms of Use (Portuguese)', 'es-419': 'Términos de uso (portugués)'}

LABELS = {
 'pt-BR': {'ads':'os detalhes do SDK', 'google':'a Política de Privacidade do Google', 'partners':'como o Google usa dados', 'delete':'as instruções de exclusão do Play Games', 'github':'a Política de Privacidade do GitHub'},
 'en': {'ads':'the SDK disclosures', 'google':'Google’s Privacy Policy', 'partners':'how Google uses data', 'delete':'the Play Games deletion instructions', 'github':'GitHub’s Privacy Statement'},
 'es-419': {'ads':'los detalles del SDK', 'google':'la Política de Privacidad de Google', 'partners':'cómo usa Google los datos', 'delete':'las instrucciones de eliminación de Play Games', 'github':'la Política de Privacidad de GitHub'},
}

def build(email: str, draft: bool = False):
    if not draft and not re.fullmatch(r'[A-Za-z0-9.!#$%&\x27*+/=?^_`{|}~-]+@[A-Za-z0-9](?:[A-Za-z0-9.-]*[A-Za-z0-9])?\.[A-Za-z]{2,}', email):
        raise SystemExit('Provide a valid public contact email; use --draft only for a local preview.')
    site = ROOT/'website'
    site.mkdir(parents=True, exist_ok=True)
    for name in ['.nojekyll', '.gdignore']:
        (site/name).touch()
    if (ROOT/'assets/branding/mascot-light.svg').is_file():
        shutil.copy2(ROOT/'assets/branding/mascot-light.svg', site/'mascot.svg')
    (site/'fonts').mkdir(exist_ok=True)
    if (ROOT/'assets/fonts/Manrope-Variable.ttf').is_file():
        shutil.copy2(ROOT/'assets/fonts/Manrope-Variable.ttf', site/'fonts/Manrope.ttf')
        shutil.copy2(ROOT/'assets/fonts/OFL.txt', site/'fonts/OFL.txt')
    paths = {'pt-BR':Path('privacy/index.html'), 'en':Path('privacy/en/index.html'), 'es-419':Path('privacy/es-419/index.html')}
    for locale,data in CONTENT.items():
        depth = len(paths[locale].parts)-1
        assets = '../'*depth
        relative = {'pt-BR':'./' if locale=='pt-BR' else '../', 'en':'en/' if locale=='pt-BR' else './' if locale=='en' else '../en/', 'es-419':'es-419/' if locale=='pt-BR' else './' if locale=='es-419' else '../es-419/'}
        nav = ''.join(f'<a href="{relative[other]}" lang="{other}"'+(' aria-current="page"' if other==locale else '')+f'>{label}</a>' for other,label in [('pt-BR','Português'),('en','English'),('es-419','Español')])
        substitutions = {key:f'<a href="{url}">{LABELS[locale][key]}</a>' for key,url in LINKS.items()}
        contact = html.escape(email) if not draft else '⟨e-mail a definir⟩'
        mail = f'<a href="mailto:{quote(email, safe="@.+-_")}">{contact}</a>' if not draft else contact
        substitutions['email'] = mail
        sections = ''.join(f'<section id="{sid}"><h2>{html.escape(title)}</h2>'+''.join('<p>'+html.escape(p).format(**substitutions)+'</p>' for p in paragraphs)+'</section>' for sid,title,paragraphs in data['sections'])
        cards = ''.join(f'<div><strong>{title}</strong><p>{text}</p></div>' for title,text in data['summary'])
        banner = '<p class="draft" role="status">'+data['draft']+'</p>' if draft else ''
        robots = '<meta name="robots" content="noindex,nofollow">' if draft else ''
        page = f'''<!doctype html>
<html lang="{locale}">
<head><meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1">{robots}
<meta name="description" content="{html.escape(data['lead'], quote=True)}">
<meta name="color-scheme" content="light dark"><title>{data['title']} · {APP}</title>
<link rel="stylesheet" href="{assets}styles.css"><link rel="icon" type="image/svg+xml" href="{assets}mascot.svg"></head>
<body><div class="page"><header><a class="brand" href="{assets}"><img src="{assets}mascot.svg" width="56" height="56" alt=""><span><b>arenis</b><small>Sand Sort Challenge</small></span></a>
<nav aria-label="{data['languages']}">{nav}</nav></header>
<main>{banner}<div class="intro"><p class="eyebrow">{APP}</p><h1>{data['title']}</h1><p class="lead">{data['lead']}</p><p class="date"><time datetime="{DATE}">{data['date']}</time></p></div>
<div class="summary">{cards}</div><article>{sections}</article>
<aside class="contact"><h2>{data['contact']}</h2><p>{mail}</p></aside></main>
<footer><span><a href="{assets}">Arenis</a> · <a href="{assets}terms/">{TERMS_LABELS[locale]}</a></span><span>© 2026 Renan Alves</span></footer></div></body></html>'''
        path = site/paths[locale]
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(page+'\n', encoding='utf-8')
    from build_public_pages import DATE as PUBLIC_DATE, build_public_pages
    build_public_pages(site, email, draft)
    (site/'publication.json').write_text(json.dumps({'app':APP,'updated':DATE,'public_pages_updated':PUBLIC_DATE,'contact_email':email if not draft else None,'ready_for_review':not draft,'languages':list(CONTENT)},ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
    print(f'Generated privacy site in {site}; draft={draft}')

if __name__ == '__main__':
    parser=argparse.ArgumentParser()
    parser.add_argument('--contact-email', default='')
    parser.add_argument('--draft', action='store_true')
    args=parser.parse_args()
    build(args.contact_email, args.draft)
