/**
 * Via Verde toll calculator scraper
 *
 * Página ASP.NET WebForms com jQuery UI autocomplete.
 * Campos confirmados: #txtStartPos (origem), #txtEndPos (destino)
 * Botão: <a> com texto "Calcular"
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

// Aceita cookies se aparecer banner (tenta várias vezes)
async function acceptCookies(page: any): Promise<void> {
  const sels = [
    '#onetrust-accept-btn-handler',
    'button[id*="accept" i]',
    'button[class*="accept" i]',
    '[class*="cookie"] button',
  ]
  for (let attempt = 0; attempt < 3; attempt++) {
    for (const s of sels) {
      try {
        const btn = await page.$(s)
        if (btn) {
          const box = await btn.boundingBox()
          if (box && box.width > 0) {
            console.log('[ViaVerde] Cookie banner:', s)
            await btn.click()
            await new Promise(r => setTimeout(r, 800))
            return
          }
        }
      } catch { /* ignore */ }
    }
    await new Promise(r => setTimeout(r, 1_000))
  }
}

// Preenche campo usando jQuery (mais fiável que page.type para jQuery UI autocomplete)
// Depois aguarda .ui-menu-item visível e clica na 1ª sugestão
async function fillAddressAndSelect(page: any, fieldId: string, address: string, label: string): Promise<void> {
  console.log(`[ViaVerde] A preencher ${label}: "${address}"`)

  // 1. Limpar campo e focar via jQuery
  await page.evaluate(`
    (function() {
      var el = document.getElementById('${fieldId}');
      if (el) {
        el.focus();
        el.value = '';
      }
    })()
  `)
  await new Promise(r => setTimeout(r, 300))

  // 2. Digitar o endereço — page.type() dispara eventos de teclado reais
  await page.type('#' + fieldId, address, { delay: 80 })

  // 3. Também disparar eventos jQuery para garantir que o autocomplete é activado
  await page.evaluate(`
    (function() {
      var jq = window.jQuery || window.$;
      if (jq) {
        var el = jq('#${fieldId}');
        el.trigger('keydown');
        el.trigger('keyup');
        el.trigger('input');
      }
    })()
  `)

  // 4. Aguardar sugestões (.ui-menu-item visível) — até 12 segundos
  console.log(`[ViaVerde] A aguardar sugestões para ${label}...`)
  let clicked = false
  for (let i = 0; i < 20; i++) {
    await new Promise(r => setTimeout(r, 600))
    const items = await page.$$('.ui-menu-item')
    const visibleItems: any[] = []
    for (const item of items) {
      try {
        const box = await item.boundingBox()
        if (box && box.width > 0 && box.height > 0) visibleItems.push(item)
      } catch { /* ignore */ }
    }
    if (visibleItems.length > 0) {
      console.log(`[ViaVerde] ${visibleItems.length} sugestão(ões) para ${label}, a clicar na 1ª`)
      await visibleItems[0].click()
      await new Promise(r => setTimeout(r, 800))
      clicked = true
      break
    }
  }

  if (!clicked) {
    console.log(`[ViaVerde] Sem sugestão visível para ${label}, fallback ArrowDown+Enter`)
    await page.keyboard.press('ArrowDown')
    await new Promise(r => setTimeout(r, 500))
    await page.keyboard.press('Enter')
    await new Promise(r => setTimeout(r, 800))
  }

  // Verificar o que ficou no campo
  const val = await page.evaluate(`document.getElementById('${fieldId}')?.value || ''`) as string
  console.log(`[ViaVerde] Campo ${fieldId} após selecção: "${val}"`)
}

// ── Debug ─────────────────────────────────────────────────────────────────────
export async function debugViaVerde(): Promise<object> {
  const browser = await puppeteer.launch({ headless: true, args: launchArgs() })
  try {
    const page = await browser.newPage()
    await page.setViewport({ width: 1280, height: 900 })
    await page.setUserAgent('Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 Chrome/124.0.0.0 Safari/537.36')
    await page.goto(VV_URL, { waitUntil: 'domcontentloaded', timeout: 60_000 })
    await page.waitForSelector('#txtStartPos', { timeout: 20_000 })
    await acceptCookies(page)

    return await page.evaluate(`(() => {
      const inputs = Array.from(document.querySelectorAll('input,select,textarea')).map(e => ({
        tag: e.tagName, type: e.getAttribute('type') || '',
        name: e.getAttribute('name') || '', id: e.getAttribute('id') || '',
        placeholder: e.getAttribute('placeholder') || '',
        className: (e.className || '').substring(0,80)
      }));
      const buttons = Array.from(document.querySelectorAll('button,input[type=submit]')).map(e => ({
        text: (e.textContent || '').trim().substring(0,60),
        id: e.getAttribute('id') || '', type: e.getAttribute('type') || '',
        className: (e.className || '').substring(0,60)
      }));
      const links = Array.from(document.querySelectorAll('a'))
        .map(e => ({ text: (e.textContent||'').trim().substring(0,60), href: (e.getAttribute('href')||'').substring(0,80), id: e.getAttribute('id')||'', className: (e.className||'').substring(0,60) }))
        .filter(l => l.text.length > 0);
      const hasJQuery = typeof window.jQuery !== 'undefined' || typeof window.$ !== 'undefined';
      return { url: location.href, title: document.title, hasJQuery, inputs, buttons, links, bodyText: document.body.innerText.substring(0,2000) };
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
    await page.setUserAgent('Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 Chrome/124.0.0.0 Safari/537.36')

    // ── 1. Navegar e aguardar campo de origem ─────────────────────────────────
    console.log('[ViaVerde] A navegar...')
    await page.goto(VV_URL, { waitUntil: 'domcontentloaded', timeout: 60_000 })
    await page.waitForSelector('#txtStartPos', { timeout: 20_000 })
    console.log('[ViaVerde] Página carregada:', await page.title())

    // ── 2. Aceitar cookies ────────────────────────────────────────────────────
    await acceptCookies(page)

    // ── 3. Preencher origem ───────────────────────────────────────────────────
    await fillAddressAndSelect(page, 'txtStartPos', moradaOrigem, 'origem')

    // ── 4. Preencher destino ──────────────────────────────────────────────────
    await fillAddressAndSelect(page, 'txtEndPos', moradaDestino, 'destino')

    // ── 5. Clicar "Calcular" ──────────────────────────────────────────────────
    const clicked = await page.evaluate(`(() => {
      // Tenta <a> com texto "Calcular"
      const links = Array.from(document.querySelectorAll('a'));
      for (const l of links) {
        if (l.textContent.trim().toLowerCase() === 'calcular') {
          console.log('[VV] Calcular link href:', l.href);
          l.click();
          return 'link:' + l.href;
        }
      }
      // Tenta button com texto "Calcular"
      const btns = Array.from(document.querySelectorAll('button'));
      for (const b of btns) {
        if ((b.textContent || '').trim().toLowerCase().includes('calcul')) {
          b.click();
          return 'button:' + b.textContent.trim();
        }
      }
      return null;
    })()`) as string | null

    console.log('[ViaVerde] Calcular clicado:', clicked)

    if (!clicked) {
      console.log('[ViaVerde] Botão Calcular não encontrado, a usar Enter')
      await page.keyboard.press('Enter')
    }

    // ── 6. Aguardar resultados ────────────────────────────────────────────────
    // Aguarda até 40 segundos que apareça um valor em km na página
    console.log('[ViaVerde] A aguardar resultados...')
    try {
      await page.waitForFunction(
        '() => /\\d+[,.]?\\d*\\s*km/i.test(document.body.innerText)',
        { timeout: 40_000 },
      )
      console.log('[ViaVerde] Resultados detectados!')
    } catch {
      console.log('[ViaVerde] Timeout a aguardar km nos resultados, a tentar ler o que há...')
    }

    // ── 7. Extrair 1ª rota ────────────────────────────────────────────────────
    const pageText = await page.evaluate('document.body.innerText') as string
    console.log('[ViaVerde] Texto da página (800 chars):', pageText.substring(0, 800))

    // Procura o 1º valor de km e o 1º valor de portagens
    const km = parseNum(pageText, /(\d{1,4}(?:[.,]\d+)?)\s*km/i)
    const portagens = parseNum(pageText, /(\d+[.,]\d{2})\s*€|€\s*(\d+[.,]\d{2})/i)

    console.log('[ViaVerde] Resultado:', { km, portagens })

    if (km === 0 && portagens === 0) {
      throw new Error(
        'Via Verde não devolveu resultados.\nTexto da página: ' + pageText.substring(0, 1000),
      )
    }

    return { km, portagens }
  } finally {
    await browser.close()
  }
}
