/**
 * Via Verde toll calculator scraper
 *
 * Fluxo:
 *  1. Abrir calculador
 *  2. Aceitar cookies
 *  3. Preencher origem → clicar 1ª sugestão autocomplete
 *  4. Preencher destino → clicar 1ª sugestão autocomplete
 *  5. Clicar "Calcular"
 *  6. Aguardar rotas → extrair km e portagens da 1ª rota
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

// ── Selectores de sugestão de autocomplete (por ordem de preferência) ─────────
// Google Maps Places usa .pac-item; outros usem li em dropdown/listbox
const AUTOCOMPLETE_ITEM_SELS = [
  '.pac-item',                          // Google Maps Places
  '[class*="suggestion"]',              // genérico
  '[class*="autocomplete"] li',         // genérico
  'ul[role="listbox"] li',              // ARIA listbox
  '[role="option"]',                    // ARIA option
  '[class*="dropdown"] li',             // dropdown genérico
  '[class*="result"] li',
  '[class*="item"]',
]

// Aguarda que apareça pelo menos uma sugestão e clica na primeira
async function clickFirstSuggestion(page: any): Promise<boolean> {
  for (let attempt = 0; attempt < 6; attempt++) {
    await new Promise(r => setTimeout(r, 600))
    for (const sel of AUTOCOMPLETE_ITEM_SELS) {
      try {
        const items = await page.$$(sel)
        const visible = []
        for (const item of items) {
          const box = await item.boundingBox()
          if (box && box.width > 0 && box.height > 0) visible.push(item)
        }
        if (visible.length > 0) {
          console.log(`[ViaVerde] Sugestão encontrada com selector "${sel}", a clicar na 1ª`)
          await visible[0].click()
          await new Promise(r => setTimeout(r, 600))
          return true
        }
      } catch { /* tenta o próximo */ }
    }
  }
  // fallback teclado
  console.log('[ViaVerde] Sem sugestão clicável, a tentar ArrowDown+Enter')
  await page.keyboard.press('ArrowDown')
  await new Promise(r => setTimeout(r, 400))
  await page.keyboard.press('Enter')
  await new Promise(r => setTimeout(r, 600))
  return false
}

// ── Debug: devolve info da página ─────────────────────────────────────────────
export async function debugViaVerde(): Promise<object> {
  const browser = await puppeteer.launch({ headless: true, args: launchArgs() })
  try {
    const page = await browser.newPage()
    await page.setViewport({ width: 1280, height: 900 })
    await page.setUserAgent(
      'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 Chrome/124.0.0.0 Safari/537.36',
    )
    await page.goto(VV_URL, { waitUntil: 'networkidle2', timeout: 30_000 })

    try {
      const btn = await page.$('#onetrust-accept-btn-handler')
      if (btn) { await btn.click(); await new Promise(r => setTimeout(r, 800)) }
    } catch { /* ignore */ }

    const result = await page.evaluate(`(() => {
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
      return {
        url: location.href, title: document.title,
        inputs, buttons,
        bodyText: document.body.innerText.substring(0, 2000)
      };
    })()`) as object

    return result
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
    await page.goto(VV_URL, { waitUntil: 'networkidle2', timeout: 30_000 })
    console.log('[ViaVerde] Título:', await page.title())

    // ── 2. Cookies ────────────────────────────────────────────────────────────
    try {
      const cookieSels = [
        '#onetrust-accept-btn-handler',
        'button[id*="accept"]',
        'button[class*="accept"]',
        'button[aria-label*="accept" i]',
        '[class*="cookie"] button',
      ]
      for (const s of cookieSels) {
        const b = await page.$(s)
        if (b) {
          console.log('[ViaVerde] Cookie banner:', s)
          await b.click()
          await new Promise(r => setTimeout(r, 1000))
          break
        }
      }
    } catch { /* sem banner */ }

    // ── 3. Campo de origem ────────────────────────────────────────────────────
    const originSels = [
      'input[name="origin"]', 'input[id*="origin" i]', 'input[id*="from" i]',
      'input[placeholder*="origem" i]', 'input[placeholder*="partida" i]',
      'input[placeholder*="local de partida" i]',
      'input[aria-label*="origem" i]', 'input[aria-label*="partida" i]',
      'input[name*="from" i]', 'input[name*="origem" i]',
    ]

    let originEl: any = null
    for (const s of originSels) {
      originEl = await page.$(s)
      if (originEl) { console.log('[ViaVerde] Origem selector:', s); break }
    }
    if (!originEl) {
      const all = await page.$$('input[type="text"], input:not([type])')
      if (all.length === 0) throw new Error('Sem campos de texto na página. Usa GET /api/viaverde/debug para diagnosticar.')
      originEl = all[0]
      console.log('[ViaVerde] Origem: fallback 1º input')
    }

    await originEl.click({ clickCount: 3 })
    await new Promise(r => setTimeout(r, 200))
    await page.keyboard.type(moradaOrigem, { delay: 60 })
    console.log('[ViaVerde] Origem digitada, a aguardar sugestões...')
    await clickFirstSuggestion(page)

    // ── 4. Campo de destino ───────────────────────────────────────────────────
    const destSels = [
      'input[name="destination"]', 'input[id*="destination" i]', 'input[id*="dest" i]',
      'input[id*="to" i]',
      'input[placeholder*="destino" i]', 'input[placeholder*="chegada" i]',
      'input[placeholder*="local de chegada" i]',
      'input[aria-label*="destino" i]', 'input[aria-label*="chegada" i]',
      'input[name*="to" i]', 'input[name*="destino" i]',
    ]

    let destEl: any = null
    for (const s of destSels) {
      destEl = await page.$(s)
      if (destEl) { console.log('[ViaVerde] Destino selector:', s); break }
    }
    if (!destEl) {
      const all = await page.$$('input[type="text"], input:not([type])')
      if (all.length < 2) throw new Error('Sem campo de destino. Usa GET /api/viaverde/debug.')
      destEl = all[1]
      console.log('[ViaVerde] Destino: fallback 2º input')
    }

    await destEl.click({ clickCount: 3 })
    await new Promise(r => setTimeout(r, 200))
    await page.keyboard.type(moradaDestino, { delay: 60 })
    console.log('[ViaVerde] Destino digitado, a aguardar sugestões...')
    await clickFirstSuggestion(page)

    // ── 5. Clicar "Calcular" ──────────────────────────────────────────────────
    const submitSels = [
      'button[type="submit"]',
      'button[class*="calcular" i]',
      'button[class*="calcul" i]',
      'button[class*="search" i]',
      'button[class*="pesquis" i]',
      'input[type="submit"]',
    ]

    let submitted = false
    for (const s of submitSels) {
      const btn = await page.$(s)
      if (btn) {
        const txt = await btn.evaluate((e: any) => e.textContent?.trim())
        console.log('[ViaVerde] Botão calcular:', s, '|', txt)
        await btn.click()
        submitted = true
        break
      }
    }
    if (!submitted) {
      // tenta encontrar botão com texto "calcular"
      const allBtns = await page.$$('button')
      for (const btn of allBtns) {
        const txt: string = await btn.evaluate((e: any) => (e.textContent || '').toLowerCase().trim())
        if (txt.includes('calcul') || txt.includes('pesquis') || txt.includes('search')) {
          console.log('[ViaVerde] Botão por texto:', txt)
          await btn.click()
          submitted = true
          break
        }
      }
    }
    if (!submitted) {
      console.log('[ViaVerde] Sem botão, a usar Enter')
      await page.keyboard.press('Enter')
    }

    // ── 6. Aguardar rotas ─────────────────────────────────────────────────────
    console.log('[ViaVerde] A aguardar resultados...')
    await new Promise(r => setTimeout(r, 7_000))

    // ── 7. Extrair dados da 1ª rota ───────────────────────────────────────────
    // Tenta selectores específicos de resultado primeiro; fallback para regex no texto
    const resultText: string = await page.evaluate(`(() => {
      // Tenta pegar só o 1º bloco de resultado (card/row de rota)
      const routeSelectors = [
        '[class*="route"]:first-child',
        '[class*="rota"]:first-child',
        '[class*="result"]:first-child',
        '[class*="card"]:first-child',
        '[class*="item"]:first-child',
        'tr:nth-child(2)',  // tabela de rotas
      ];
      for (const sel of routeSelectors) {
        try {
          const el = document.querySelector(sel);
          if (el && el.textContent && el.textContent.trim().length > 10) {
            return el.textContent.trim();
          }
        } catch(e) {}
      }
      // fallback: texto completo
      return document.body.innerText;
    })()`) as string

    console.log('[ViaVerde] Texto resultado (500 chars):', resultText.substring(0, 500))

    // Extrai km (ex: "125 km", "125,3 km", "125.3km")
    const km = parseNum(resultText, /(\d{1,4}(?:[.,]\d+)?)\s*km/i)

    // Extrai portagens (ex: "12,50 €", "€12,50", "EUR 12.50")
    // Apanha o PRIMEIRO valor monetário encontrado (= 1ª rota)
    const portagens = parseNum(resultText, /(\d+[.,]\d{2})\s*€|€\s*(\d+[.,]\d{2})/i)

    console.log('[ViaVerde] Resultado final:', { km, portagens })

    if (km === 0 && portagens === 0) {
      // Devolve o texto da página para ajudar no diagnóstico
      const bodySnippet = (await page.evaluate('document.body.innerText') as string).substring(0, 800)
      throw new Error(
        `Via Verde não devolveu resultados. Texto da página: ${bodySnippet}`,
      )
    }

    return { km, portagens }
  } finally {
    await browser.close()
  }
}
