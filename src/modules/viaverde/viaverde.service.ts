/**
 * Via Verde toll calculator scraper
 *
 * Estratégia: geocodifica as moradas via HERE Geocoding API (mesma chave
 * usada pelo site), injeta as coordenadas directamente nos campos e chama
 * CalculateRoute() — sem depender do autocomplete do browser em headless.
 */

import puppeteer from 'puppeteer'

const VV_URL     = 'https://www.viaverde.pt/ferramentas/calculador-de-portagens'
const HERE_KEY   = 'KLRL1l8y-1d-oBuCWTOQRRGCUL4tL3yThEPf9tXdW8s'

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

// ── Geocodifica via HERE Geocoding API ────────────────────────────────────────
async function geocodeHere(address: string): Promise<[number, number] | null> {
  try {
    const url = `https://geocode.search.hereapi.com/v1/geocode?q=${encodeURIComponent(address)}&in=countryCode:PRT&apikey=${HERE_KEY}`
    console.log(`[ViaVerde] Geocoding: "${address}"`)
    const res  = await fetch(url)
    const json = await res.json() as any
    if (json.items?.length > 0) {
      const { lat, lng } = json.items[0].position
      console.log(`[ViaVerde] Geocoded "${address}" → [${lat},${lng}]`)
      return [lat, lng]
    }
    console.log(`[ViaVerde] Geocoding sem resultados para "${address}":`, JSON.stringify(json).substring(0, 200))
  } catch (e: any) {
    console.log(`[ViaVerde] Geocoding error para "${address}":`, e.message)
  }
  return null
}

// Fallback: Nominatim (OpenStreetMap) — sem API key
async function geocodeNominatim(address: string): Promise<[number, number] | null> {
  try {
    const q   = encodeURIComponent(address + ', Portugal')
    const url = `https://nominatim.openstreetmap.org/search?q=${q}&format=json&limit=1`
    console.log(`[ViaVerde] Nominatim fallback: "${address}"`)
    const res  = await fetch(url, { headers: { 'User-Agent': 'ViaVerde-CRM/1.0' } })
    const json = await res.json() as any[]
    if (json.length > 0) {
      const lat = parseFloat(json[0].lat)
      const lng = parseFloat(json[0].lon)
      console.log(`[ViaVerde] Nominatim "${address}" → [${lat},${lng}]`)
      return [lat, lng]
    }
    console.log(`[ViaVerde] Nominatim sem resultados para "${address}"`)
  } catch (e: any) {
    console.log(`[ViaVerde] Nominatim error para "${address}":`, e.message)
  }
  return null
}

async function geocode(address: string): Promise<[number, number]> {
  const here = await geocodeHere(address)
  if (here) return here
  const nom  = await geocodeNominatim(address)
  if (nom) return nom
  throw new Error(`Não foi possível geocodificar: "${address}". Verifique a morada.`)
}

// Aceita cookies se aparecer banner
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

  // ── 1. Geocodificar ANTES de abrir o browser ──────────────────────────────
  const [origCoords, destCoords] = await Promise.all([
    geocode(moradaOrigem.trim()),
    geocode(moradaDestino.trim()),
  ])

  const browser = await puppeteer.launch({ headless: true, args: launchArgs() })

  try {
    const page = await browser.newPage()
    await page.setViewport({ width: 1280, height: 900 })
    await page.setUserAgent('Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 Chrome/124.0.0.0 Safari/537.36')

    // ── 2. Navegar e aguardar campo de origem ─────────────────────────────────
    console.log('[ViaVerde] A navegar...')
    await page.goto(VV_URL, { waitUntil: 'domcontentloaded', timeout: 60_000 })
    await page.waitForSelector('#txtStartPos', { timeout: 20_000 })
    console.log('[ViaVerde] Página carregada:', await page.title())

    // ── 3. Aceitar cookies ────────────────────────────────────────────────────
    await acceptCookies(page)
    await new Promise(r => setTimeout(r, 500))

    // ── 4. Seleccionar Classe 2 ───────────────────────────────────────────────
    const classeClicked = await page.evaluate(`(() => {
      const el = document.querySelector('a[title="Classe 2"]');
      if (el) { el.click(); return 'a[title=Classe 2]'; }
      if (typeof window.setClass === 'function') {
        window.setClass(null, 2);
        return 'setClass(2) direct';
      }
      return null;
    })()`) as string | null
    console.log('[ViaVerde] Classe 2:', classeClicked)
    await new Promise(r => setTimeout(r, 500))

    // ── 5. Injectar coordenadas directamente nos campos ───────────────────────
    // Evita dependência do autocomplete (que não funciona em headless)
    const origPos = `[${origCoords[0]},${origCoords[1]}]`
    const destPos = `[${destCoords[0]},${destCoords[1]}]`
    const origVal = moradaOrigem.trim().replace(/'/g, "\\'")
    const destVal = moradaDestino.trim().replace(/'/g, "\\'")

    await page.evaluate(`
      (function(ov, op, dv, dp) {
        var orig = document.getElementById('txtStartPos');
        if (orig) {
          orig.value = ov;
          orig.setAttribute('data-position', op);
          orig.dispatchEvent(new Event('change', { bubbles: true }));
        }
        var dest = document.getElementById('txtEndPos');
        if (dest) {
          dest.value = dv;
          dest.setAttribute('data-position', dp);
          dest.dispatchEvent(new Event('change', { bubbles: true }));
        }
        console.log('[VV] campos injectados: orig=' + op + ' dest=' + dp);
      })('${origVal}', '${origPos}', '${destVal}', '${destPos}')
    `)
    console.log(`[ViaVerde] Campos injectados: orig=${origPos} dest=${destPos}`)
    await new Promise(r => setTimeout(r, 500))

    // ── 6. Chamar CalculateRoute() ────────────────────────────────────────────
    console.log('[ViaVerde] A chamar CalculateRoute()...')
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

    // ── 7. Aguardar .route-info ───────────────────────────────────────────────
    console.log('[ViaVerde] A aguardar .route-info...')
    try {
      await page.waitForSelector('.route-info', { timeout: 40_000 })
      console.log('[ViaVerde] .route-info detectado!')
    } catch {
      console.log('[ViaVerde] Timeout a aguardar .route-info')
    }

    // ── 8. Extrair 1ª rota ────────────────────────────────────────────────────
    const result = await page.evaluate(`(() => {
      const first = document.querySelector('.route-info');
      if (!first) {
        return { km: null, portagens: null, debug: document.body.innerText.substring(0, 800) };
      }
      const kmText  = (first.querySelector('.km')           || {}).textContent || '';
      const valText = (first.querySelector('.value.destak') || {}).textContent || '';
      return { km: kmText.trim(), portagens: valText.trim(), debug: null };
    })()`) as { km: string | null; portagens: string | null; debug: string | null }

    console.log('[ViaVerde] Resultado raw:', result)

    if (!result.km) {
      throw new Error('Via Verde não devolveu resultados.\nTexto da página: ' + (result.debug || ''))
    }

    const km        = parseNum(result.km,             /(\d+[.,]?\d*)/)
    const portagens = parseNum(result.portagens || '', /(\d+[.,]\d+)/)

    return { km, portagens }
  } finally {
    await browser.close()
  }
}
