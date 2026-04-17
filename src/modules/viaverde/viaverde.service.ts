/**
 * Via Verde toll calculator scraper
 *
 * Abre o calculador em https://www.viaverde.pt/ferramentas/calculador-de-portagens,
 * preenche a morada de origem (configurada nas Settings) e de destino,
 * e extrai os km e o valor das portagens.
 *
 * ⚠️  Se a Via Verde alterar o layout, ajusta os selectores marcados com [SELECTOR].
 */

import puppeteer from 'puppeteer'

const VV_URL = 'https://www.viaverde.pt/ferramentas/calculador-de-portagens'

export interface ViaverdeResult {
  km: number
  portagens: number
}

// ── Helper: preenche um campo de endereço e trata o autocomplete ──────────────
async function fillAddress(page: any, address: string): Promise<void> {
  await page.keyboard.type(address, { delay: 45 })

  // Aguarda sugestões do autocomplete (Google Maps Places ou nativo)
  await page.waitForTimeout(1800)

  // Selecciona a primeira sugestão com ArrowDown + Enter
  await page.keyboard.press('ArrowDown')
  await page.waitForTimeout(400)
  await page.keyboard.press('Enter')
  await page.waitForTimeout(700)
}

// ── Helper: extrai número de texto  (ex: "125,3 km" → 125.3) ─────────────────
function parseNum(text: string, pattern: RegExp): number {
  const m = text.match(pattern)
  if (!m) return 0
  return parseFloat((m[1] || m[2] || '0').replace(',', '.'))
}

// ── Scraper principal ─────────────────────────────────────────────────────────
export async function calcularViaVerde(
  moradaOrigem: string,
  moradaDestino: string,
): Promise<ViaverdeResult> {
  if (!moradaOrigem.trim()) {
    throw Object.assign(new Error('Morada de origem não configurada. Adiciona-a em Configurações.'), { statusCode: 400 })
  }
  if (!moradaDestino.trim()) {
    throw Object.assign(new Error('Morada de destino em branco.'), { statusCode: 400 })
  }

  const browser = await puppeteer.launch({
    headless: true,
    args: [
      '--no-sandbox',
      '--disable-setuid-sandbox',
      '--disable-dev-shm-usage',
      '--disable-gpu',
      '--window-size=1280,900',
    ],
  })

  try {
    const page = await browser.newPage()
    await page.setViewport({ width: 1280, height: 900 })
    await page.setUserAgent(
      'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36',
    )

    // ── 1. Navegar ────────────────────────────────────────────────────────────
    await page.goto(VV_URL, { waitUntil: 'networkidle2', timeout: 30_000 })

    // ── 2. Aceitar cookies ────────────────────────────────────────────────────
    // [SELECTOR] Ajusta se o banner de cookies tiver um id/class diferente
    try {
      const cookieSelectors = [
        '#onetrust-accept-btn-handler',
        '[id*="cookie"] [class*="accept"]',
        '[class*="cookie-accept"]',
        'button[data-testid*="accept"]',
      ]
      for (const sel of cookieSelectors) {
        const btn = await page.$(sel)
        if (btn) {
          await btn.click()
          await page.waitForTimeout(600)
          break
        }
      }
    } catch { /* sem banner */ }

    // ── 3. Seleccionar tipo de veículo "Ligeiro" ──────────────────────────────
    // [SELECTOR] Muitos calculadores de portagens têm um dropdown/radio de classe
    // Se o site não tiver este selector, o try simplesmente falha sem problema
    try {
      const classeSelectors = [
        'select[name*="classe"], select[name*="veiculo"], select[name*="class"]',
        'input[value="1"][type="radio"], input[value="ligeiro"][type="radio"]',
      ]
      for (const sel of classeSelectors) {
        const el = await page.$(sel)
        if (el) {
          const tag = await page.evaluate((e: Element) => e.tagName, el)
          if (tag === 'SELECT') {
            // Tenta seleccionar classe 1 (Ligeiro)
            await page.select(sel, '1').catch(() => {})
          } else {
            await el.click()
          }
          await page.waitForTimeout(400)
          break
        }
      }
    } catch { /* sem selector de classe */ }

    // ── 4. Campo de origem ────────────────────────────────────────────────────
    // [SELECTOR] Tenta vários padrões comuns para o campo de origem
    const originSelectors = [
      'input[name="origin"]',
      'input[placeholder*="origem" i]',
      'input[placeholder*="partida" i]',
      'input[aria-label*="origem" i]',
      'input[aria-label*="partida" i]',
      'input[id*="origin" i]',
      'input[id*="from" i]',
    ]

    let originFocused = false
    for (const sel of originSelectors) {
      const el = await page.$(sel)
      if (el) {
        await el.click({ clickCount: 3 })
        await fillAddress(page, moradaOrigem)
        originFocused = true
        break
      }
    }

    if (!originFocused) {
      // Fallback: usa o primeiro input de texto da página
      const inputs = await page.$$('input[type="text"], input:not([type])')
      if (inputs.length === 0) throw new Error('Não foi possível encontrar os campos de endereço na página da Via Verde.')
      await inputs[0].click({ clickCount: 3 })
      await fillAddress(page, moradaOrigem)
    }

    // ── 5. Campo de destino ───────────────────────────────────────────────────
    // [SELECTOR] Tenta vários padrões comuns para o campo de destino
    const destSelectors = [
      'input[name="destination"]',
      'input[placeholder*="destino" i]',
      'input[placeholder*="chegada" i]',
      'input[aria-label*="destino" i]',
      'input[aria-label*="chegada" i]',
      'input[id*="destination" i]',
      'input[id*="to" i]',
    ]

    let destFocused = false
    for (const sel of destSelectors) {
      const el = await page.$(sel)
      if (el) {
        await el.click({ clickCount: 3 })
        await fillAddress(page, moradaDestino)
        destFocused = true
        break
      }
    }

    if (!destFocused) {
      // Fallback: usa o segundo input de texto da página
      const inputs = await page.$$('input[type="text"], input:not([type])')
      if (inputs.length < 2) throw new Error('Não foi possível encontrar o campo de destino na página da Via Verde.')
      await inputs[1].click({ clickCount: 3 })
      await fillAddress(page, moradaDestino)
    }

    // ── 6. Submeter / Calcular ────────────────────────────────────────────────
    // [SELECTOR] Ajusta se o botão de calcular tiver um selector diferente
    const submitSelectors = [
      'button[type="submit"]',
      'button[class*="calcul" i]',
      'button[class*="search" i]',
      'button[class*="pesquis" i]',
      'input[type="submit"]',
    ]

    let submitted = false
    for (const sel of submitSelectors) {
      const btn = await page.$(sel)
      if (btn) {
        await btn.click()
        submitted = true
        break
      }
    }

    if (!submitted) {
      // Fallback: tenta submeter com Enter
      await page.keyboard.press('Enter')
    }

    // ── 7. Aguardar resultados ────────────────────────────────────────────────
    await page.waitForTimeout(5_000)

    // ── 8. Extrair km e portagens do texto da página ──────────────────────────
    const bodyText: string = await page.evaluate(() => document.body.innerText)

    // Distância: "125 km" ou "125,3 km" ou "125.3 km"
    const km = parseNum(bodyText, /(\d{1,4}(?:[.,]\d+)?)\s*km/i)

    // Portagens: "12,50 €" ou "€ 12,50" ou "12.50 €"
    const portagens = parseNum(bodyText, /(\d+[.,]\d{2})\s*€|€\s*(\d+[.,]\d{2})/i)

    if (km === 0 && portagens === 0) {
      throw new Error(
        'Via Verde não devolveu resultados. ' +
        'Verifica se as moradas estão correctas e se o site está acessível.',
      )
    }

    return { km, portagens }
  } finally {
    await browser.close()
  }
}
