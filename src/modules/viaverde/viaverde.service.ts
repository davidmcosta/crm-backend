/**
 * Via Verde toll calculator scraper
 *
 * Página ASP.NET WebForms com jQuery UI autocomplete.
 *
 * Selectores confirmados via /debug:
 *   origem  → #txtStartPos   (.ui-autocomplete-input)
 *   destino → #txtEndPos     (.ui-autocomplete-input)
 *   sugest. → .ui-menu-item  (jQuery UI dropdown)
 *   calcular→ <a> com texto "Calcular"
 */

import puppeteer from 'puppeteer'

const VV_URL = 'https://www.viaverde.pt/ferramentas/calculador-de-portagens'

export interface ViaverdeResult {
  km: number
  portagens: number
}

function launchArgs() {
  return [
    '--no-sandbox',
    '--disable-setuid-sandbox',
    '--disable-dev-shm-usage',
    '--disable-gpu',
    '--single-process',
    '--no-zygote',
    '--window-size=1280,900',
  ]
}

function parseNum(text: string, pattern: RegExp): number {
  const m = text.match(pattern)
  if (!m) return 0
  return parseFloat((m[1] || m[2] || '0').replace(',', '.'))
}

// Aguarda até 10s que o jQuery UI dropdown tenha pelo menos 1 item visível
// e clica no primeiro. Fallback para ArrowDown+Enter.
async function clickFirstAutocomplete(page: any, label: string): Promise<void> {
  console.log(`[ViaVerde] A aguardar sugestão autocomplete para ${label}...`)
  for (let i = 0; i < 15; i++) {
    await new Promise(r => setTimeout(r, 700))
    const items = await page.$$('.ui-menu-item')
    const visible: any[] = []
    for (const item of items) {
      const box = await item.boundingBox()
      if (box && box.width > 0 && box.height > 0) visible.push(item)
    }
    if (visible.length > 0) {
      console.log(`[ViaVerde] ${visible.length} sugestão(ões) encontrada(s) para ${label}, a clicar na 1ª`)
      await visible[0].click()
      await new Promise(r => setTimeout(r, 600))
      return
    }
  }
  // fallback teclado
  console.log(`[ViaVerde] Sem sugestão visível para ${label}, fallback ArrowDown+Enter`)
  await page.keyboard.press('ArrowDown')
  await new Promise(r => setTimeout(r, 400))
  await page.keyboard.press('Enter')
  await new Promise(r => setTimeout(r, 600))
}

// ── Debug ─────────────────────────────────────────────────────────────────────
export async function debugViaVerde(): Promise<object> {
  const browser = await puppeteer.launch({ headless: true, args: launchArgs() })
  try {
    const page = await browser.newPage()
    await page.setViewport({ width: 1280, height: 900 })
    await page.setUserAgent(
      'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 Chrome/124.0.0.0 Safari/537.36',
    )
    await page.goto(VV_URL, { waitUntil: 'domcontentloaded', timeout: 60_000 })
    await new Promise(r => setTimeout(r, 3_000))

    try {
      const btn = await page.$('#onetrust-accept-btn-handler')
      if (btn) { await btn.click(); await new Promise(r => setTimeout(r, 800)) }
    } catch { /* ignore */ }

    return await page.evaluate(`(() => {
      const inputs = Array.from(document.querySelectorAll('input,select,textarea')).map(e => ({
        tag: e.tagName, type: e.getAttribute('type') || '',
        name: e.getAttribute('name') || '', id: e.getAttribute('id') || '',
        placeholder: e.getAttribute('placeholder') || '',
        ariaLabel: e.getAttribute('aria-label') || '',
        className: (e.className || '').substring(0,80)
      }));
      const buttons = Array.from(document.querySelectorAll('button,input[type=submit]')).map(e => ({
        tag: e.tagName, type: e.getAttribute('type') || '',
        text: (e.textContent || '').trim().substring(0,80),
        id: e.getAttribute('id') || '',
        className: (e.className || '').substring(0,80)
      }));
      const links = Array.from(document.querySelectorAll('a')).map(e => ({
        text: (e.textContent || '').trim().substring(0,60),
        href: (e.getAttribute('href') || '').substring(0,80),
        id: e.getAttribute('id') || '',
        className: (e.className || '').substring(0,60)
      })).filter(l => l.text.length > 0);
      return {
        url: location.href, title: document.title,
        inputs, buttons, links,
        bodyText: document.body.innerText.substring(0, 2000)
      };
    })()`) as object
  } finally {
    await browser.close()
  }
}

// ── Scraper principal ─────────────────────────────────────────────────────────
export async function calcularViaVerde(
  moradaOrigem: string,
  moradaDestino: string,
): Promise<ViaverdeResult> {
  if (!moradaOrigem.trim()) {
    throw Object.assign(
      new Error('Morada de origem não configurada. Adiciona-a em Configurações.'),
      { statusCode: 400 },
    )
  }
  if (!moradaDestino.trim()) {
    throw Object.assign(new Error('Morada de destino em branco.'), { statusCode: 400 })
  }

  const browser = await puppeteer.launch({ headless: true, args: launchArgs() })

  try {
    const page = await browser.newPage()
    await page.setViewport({ width: 1280, height: 900 })
    await page.setUserAgent(
      'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 Chrome/124.0.0.0 Safari/537.36',
    )

    // ── 1. Navegar ────────────────────────────────────────────────────────────
    console.log('[ViaVerde] A navegar...')
    await page.goto(VV_URL, { waitUntil: 'domcontentloaded', timeout: 60_000 })
    // Aguarda que o campo de origem exista (indica que o JS da página carregou)
    await page.waitForSelector('#txtStartPos', { timeout: 20_000 })
    console.log('[ViaVerde] Página carregada:', await page.title())

    // ── 2. Cookies ────────────────────────────────────────────────────────────
    try {
      const cookieSels = [
        '#onetrust-accept-btn-handler',
        'button[id*="accept"]',
        '[class*="cookie"] button',
      ]
      for (const s of cookieSels) {
        const b = await page.$(s)
        if (b) {
          console.log('[ViaVerde] Cookie banner aceite:', s)
          await b.click()
          await new Promise(r => setTimeout(r, 1_000))
          break
        }
      }
    } catch { /* sem banner */ }

    // ── 3. Preencher origem (#txtStartPos) ────────────────────────────────────
    await page.click('#txtStartPos', { clickCount: 3 })
    await new Promise(r => setTimeout(r, 200))
    await page.type('#txtStartPos', moradaOrigem, { delay: 60 })
    console.log('[ViaVerde] Origem digitada:', moradaOrigem)
    await clickFirstAutocomplete(page, 'origem')

    // ── 4. Preencher destino (#txtEndPos) ─────────────────────────────────────
    await page.click('#txtEndPos', { clickCount: 3 })
    await new Promise(r => setTimeout(r, 200))
    await page.type('#txtEndPos', moradaDestino, { delay: 60 })
    console.log('[ViaVerde] Destino digitado:', moradaDestino)
    await clickFirstAutocomplete(page, 'destino')

    // ── 5. Clicar "Calcular" ──────────────────────────────────────────────────
    // Na Via Verde é um <a> com texto "Calcular" (ASP.NET WebForms)
    const clicked = await page.evaluate(`(() => {
      const links = Array.from(document.querySelectorAll('a'));
      const btn = links.find(l => l.textContent.trim().toLowerCase() === 'calcular');
      if (btn) { btn.click(); return true; }
      // fallback: procura button com texto calcular
      const btns = Array.from(document.querySelectorAll('button'));
      const b2 = btns.find(b => b.textContent.trim().toLowerCase().includes('calcul'));
      if (b2) { b2.click(); return true; }
      return false;
    })()`) as boolean

    if (clicked) {
      console.log('[ViaVerde] Botão Calcular clicado')
    } else {
      console.log('[ViaVerde] Botão Calcular não encontrado, a submeter com Enter')
      await page.keyboard.press('Enter')
    }

    // ── 6. Aguardar resultados ────────────────────────────────────────────────
    // ASP.NET pode fazer postback completo ou UpdatePanel (AJAX parcial)
    console.log('[ViaVerde] A aguardar resultados...')
    await new Promise(r => setTimeout(r, 8_000))

    // ── 7. Extrair 1ª rota ────────────────────────────────────────────────────
    const resultData = await page.evaluate(`(() => {
      const body = document.body.innerText;

      // Tenta encontrar o 1º bloco de resultado de rota
      // Selectores típicos de resultado na Via Verde
      const routeSels = [
        '.route-result:first-child',
        '.route-item:first-child',
        '.result-item:first-child',
        '.route:first-child',
        '.rota:first-child',
        'tr.route:first-child',
        '.routes-list > *:first-child',
        '.results > *:first-child',
      ];
      for (const sel of routeSels) {
        try {
          const el = document.querySelector(sel);
          if (el && el.textContent && el.textContent.trim().length > 5) {
            return { text: el.textContent.trim(), selector: sel };
          }
        } catch(e) {}
      }
      return { text: body, selector: 'body' };
    })()`) as { text: string; selector: string }

    console.log('[ViaVerde] Selector usado:', resultData.selector)
    console.log('[ViaVerde] Texto resultado (600 chars):', resultData.text.substring(0, 600))

    const km = parseNum(resultData.text, /(\d{1,4}(?:[.,]\d+)?)\s*km/i)
    const portagens = parseNum(resultData.text, /(\d+[.,]\d{2})\s*€|€\s*(\d+[.,]\d{2})/i)

    console.log('[ViaVerde] Resultado:', { km, portagens })

    if (km === 0 && portagens === 0) {
      const snippet = (await page.evaluate('document.body.innerText') as string).substring(0, 1000)
      throw new Error(`Via Verde não devolveu resultados.\nTexto da página: ${snippet}`)
    }

    return { km, portagens }
  } finally {
    await browser.close()
  }
}
