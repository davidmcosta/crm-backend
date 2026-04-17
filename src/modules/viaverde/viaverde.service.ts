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

// Preenche campo de endereço e selecciona a 1ª sugestão do jQuery UI autocomplete.
// Os campos usam oninput="ValidateKeyPress()" para disparar o autocomplete,
// e guardam as coordenadas em data-position após selecção.
async function fillAddressAndSelect(page: any, fieldId: string, address: string, label: string): Promise<void> {
  console.log(`[ViaVerde] A preencher ${label}: "${address}"`)

  // Guardar data-position inicial para detectar quando muda (= selecção feita)
  const posBefore = await page.evaluate(`document.getElementById('${fieldId}')?.getAttribute('data-position') || ''`) as string

  // 1. Focar e limpar o campo
  await page.click('#' + fieldId, { clickCount: 3 })
  await new Promise(r => setTimeout(r, 200))
  await page.keyboard.press('Backspace')

  // 2. Digitar o endereço caractere a caractere (dispara keypress + oninput = ValidateKeyPress)
  await page.type('#' + fieldId, address, { delay: 120 })
  await new Promise(r => setTimeout(r, 500))

  // 3. Chamar ValidateKeyPress() explicitamente para garantir que o autocomplete arranca
  await page.evaluate(`
    (function() {
      var el = document.getElementById('${fieldId}');
      if (!el) return;
      // Dispara oninput nativo
      el.dispatchEvent(new Event('input', { bubbles: true }));
      // Chama a função do site directamente
      if (typeof ValidateKeyPress === 'function') ValidateKeyPress();
      // Garante que o jQuery UI autocomplete também faz search
      var jq = window.jQuery || window.$;
      if (jq && jq('#${fieldId}').autocomplete) {
        try { jq('#${fieldId}').autocomplete('search', el.value); } catch(e) {}
      }
    })()
  `)

  // 4. Aguardar .ui-menu-item e clicar no 1º (sem verificar bounding rect —
  //    em headless/sem-GPU as dimensões podem ser 0 mesmo com o item presente)
  console.log(`[ViaVerde] A aguardar sugestões para ${label}...`)
  let clicked = false
  for (let i = 0; i < 25; i++) {
    await new Promise(r => setTimeout(r, 800))
    const count = await page.evaluate(`document.querySelectorAll('.ui-menu-item').length`) as number
    console.log(`[ViaVerde] tentativa ${i+1}: ${count} .ui-menu-item para ${label}`)
    if (count > 0) {
      console.log(`[ViaVerde] ${count} sugestão(ões) para ${label}, a clicar na 1ª`)
      await page.evaluate(`document.querySelector('.ui-menu-item a, .ui-menu-item').click()`)
      await new Promise(r => setTimeout(r, 1000))
      clicked = true
      break
    }
  }

  if (!clicked) {
    console.log(`[ViaVerde] Sem sugestões para ${label}, fallback ArrowDown+Enter`)
    await page.keyboard.press('ArrowDown')
    await new Promise(r => setTimeout(r, 600))
    await page.keyboard.press('Enter')
    await new Promise(r => setTimeout(r, 1000))
  }

  // 5. Verificar se data-position mudou (indica que a selecção actualizou as coordenadas)
  const posAfter = await page.evaluate(`document.getElementById('${fieldId}')?.getAttribute('data-position') || ''`) as string
  const valAfter = await page.evaluate(`document.getElementById('${fieldId}')?.value || ''`) as string
  console.log(`[ViaVerde] ${fieldId} | value="${valAfter}" | data-position mudou: ${posAfter !== posBefore} (${posAfter})`)
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

    // ── Monitorar requests de autocomplete/geocoding ──────────────────────────
    await page.setRequestInterception(true)
    page.on('request', req => {
      const url = req.url()
      if (/autocomplete|geocod|suggest|here\.com|viaverde/i.test(url)) {
        console.log('[ViaVerde] REQ:', req.method(), url.substring(0, 250))
      }
      req.continue()
    })
    page.on('response', async res => {
      const url = res.url()
      if (/autocomplete|geocod|suggest|here\.com/i.test(url)) {
        try {
          const text = await res.text()
          console.log('[ViaVerde] RES', res.status(), url.substring(0, 150), '→', text.substring(0, 300))
        } catch { /* ignore */ }
      }
    })

    // ── 1. Navegar e aguardar campo de origem ─────────────────────────────────
    console.log('[ViaVerde] A navegar...')
    await page.goto(VV_URL, { waitUntil: 'domcontentloaded', timeout: 60_000 })
    await page.waitForSelector('#txtStartPos', { timeout: 20_000 })
    console.log('[ViaVerde] Página carregada:', await page.title())

    // ── 2. Aceitar cookies ────────────────────────────────────────────────────
    await acceptCookies(page)

    // ── 3. Seleccionar Classe 2 (Ligeiros) ───────────────────────────────────
    // Selector confirmado: <a title="Classe 2" onclick="setClass(this,2)">
    const classeClicked = await page.evaluate(`(() => {
      const el = document.querySelector('a[title="Classe 2"]');
      if (el) { el.click(); return 'a[title=Classe 2]'; }
      // fallback: chamar setClass directamente se existir
      if (typeof window.setClass === 'function') {
        window.setClass(null, 2);
        return 'setClass(2) direct';
      }
      return null;
    })()`) as string | null
    console.log('[ViaVerde] Classe 2 seleccionada:', classeClicked)
    await new Promise(r => setTimeout(r, 500))

    // ── 4. Preencher origem ───────────────────────────────────────────────────
    await fillAddressAndSelect(page, 'txtStartPos', moradaOrigem, 'origem')

    // ── 4. Preencher destino ──────────────────────────────────────────────────
    await fillAddressAndSelect(page, 'txtEndPos', moradaDestino, 'destino')

    // ── 5. Clicar "Calcular" ──────────────────────────────────────────────────
    // Chama CalculateRoute() directamente (é o onclick do #btnCalculate)
    console.log('[ViaVerde] A clicar Calcular...')
    const clicked = await page.evaluate(`(() => {
      if (typeof window.CalculateRoute === 'function') {
        window.CalculateRoute();
        return 'CalculateRoute() direct';
      }
      var el = document.getElementById('btnCalculate');
      if (el) { el.click(); return '#btnCalculate click'; }
      return null;
    })()`) as string | null

    console.log('[ViaVerde] Calcular:', clicked)

    if (!clicked) {
      console.log('[ViaVerde] Sem Calcular, a usar Enter')
      await page.keyboard.press('Enter')
    }

    // ── 6. Aguardar .route-info aparecer ─────────────────────────────────────
    console.log('[ViaVerde] A aguardar .route-info...')
    try {
      await page.waitForSelector('.route-info', { timeout: 40_000 })
      console.log('[ViaVerde] .route-info detectado!')
    } catch {
      console.log('[ViaVerde] Timeout a aguardar .route-info')
    }

    // ── 7. Extrair 1ª rota (.route-info:first-child) ─────────────────────────
    // Estrutura confirmada:
    //   <div class="route-info">
    //     <div class="left-content">
    //       <span class="km">51.3Km</span>
    //     </div>
    //     <div class="right-content">
    //       <span class="value destak">5.45€</span>
    //     </div>
    //   </div>
    const result = await page.evaluate(`(() => {
      const first = document.querySelector('.route-info');
      if (!first) {
        // Sem resultados — devolver texto da página para diagnóstico
        return { km: null, portagens: null, debug: document.body.innerText.substring(0, 800) };
      }
      const kmText  = (first.querySelector('.km')          || {}).textContent || '';
      const valText = (first.querySelector('.value.destak') || {}).textContent || '';
      return { km: kmText.trim(), portagens: valText.trim(), debug: null };
    })()`) as { km: string | null; portagens: string | null; debug: string | null }

    console.log('[ViaVerde] Resultado raw:', result)

    if (!result.km) {
      throw new Error('Via Verde não devolveu resultados.\nTexto da página: ' + (result.debug || ''))
    }

    // "51.3Km" → 51.3   |   "5.45€" → 5.45
    const km       = parseNum(result.km,       /(\d+[.,]?\d*)/)
    const portagens = parseNum(result.portagens || '', /(\d+[.,]\d+)/)

    return { km, portagens }
  } finally {
    await browser.close()
  }
}
