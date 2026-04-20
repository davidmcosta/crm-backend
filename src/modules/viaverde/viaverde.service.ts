/**
 * Via Verde toll calculator
 *
 * Fluxo:
 *  1. Geocodifica as moradas via HERE Geocoding API
 *  2. Calcula rota via HERE Routing API (timeout 6s)
 *     → fallback: OSRM (OpenStreetMap, gratuito, sem key)
 *  3. Para portagens: interceta o XHR que CalculateRoute() faz
 *     para encontrar o endpoint interno da Via Verde (debugFindVvApi)
 */

import puppeteer from 'puppeteer'

const HERE_KEY = 'KLRL1l8y-1d-oBuCWTOQRRGCUL4tL3yThEPf9tXdW8s'
const VV_URL   = 'https://www.viaverde.pt/ferramentas/calculador-de-portagens'

export interface ViaverdeResult {
  km: number
  portagens: number
}

// ── Geocodificação ─────────────────────────────────────────────────────────────

async function geocodeHere(address: string): Promise<[number, number] | null> {
  try {
    const url = `https://geocode.search.hereapi.com/v1/geocode?q=${encodeURIComponent(address)}&in=countryCode:PRT&apikey=${HERE_KEY}`
    const res  = await fetch(url, { signal: AbortSignal.timeout(8_000) })
    const json = await res.json() as any
    if (json.items?.length > 0) {
      const { lat, lng } = json.items[0].position
      console.log(`[ViaVerde] Geocoded "${address}" → [${lat},${lng}]`)
      return [lat, lng]
    }
    console.log(`[ViaVerde] Geocoding sem resultado para "${address}"`)
  } catch (e: any) {
    console.log(`[ViaVerde] Geocoding error: ${e.message}`)
  }
  return null
}

async function geocodeNominatim(address: string): Promise<[number, number] | null> {
  try {
    const q   = encodeURIComponent(address + ', Portugal')
    const url = `https://nominatim.openstreetmap.org/search?q=${q}&format=json&limit=1`
    const res  = await fetch(url, {
      headers: { 'User-Agent': 'ViaVerde-CRM/1.0' },
      signal: AbortSignal.timeout(8_000),
    })
    const json = await res.json() as any[]
    if (json.length > 0) {
      const lat = parseFloat(json[0].lat)
      const lng = parseFloat(json[0].lon)
      console.log(`[ViaVerde] Nominatim "${address}" → [${lat},${lng}]`)
      return [lat, lng]
    }
  } catch (e: any) {
    console.log(`[ViaVerde] Nominatim error: ${e.message}`)
  }
  return null
}

async function geocode(address: string): Promise<[number, number]> {
  const here = await geocodeHere(address)
  if (here) return here
  const nom  = await geocodeNominatim(address)
  if (nom) return nom
  throw Object.assign(
    new Error(`Não foi possível geocodificar: "${address}". Verifique a morada.`),
    { statusCode: 400 },
  )
}

// ── Routing: HERE (com timeout) + fallback OSRM ────────────────────────────────

async function routeHere(
  orig: [number, number],
  dest: [number, number],
): Promise<ViaverdeResult | null> {
  try {
    const url = new URL('https://router.hereapi.com/v8/routes')
    url.searchParams.set('transportMode', 'car')
    url.searchParams.set('origin',      `${orig[0]},${orig[1]}`)
    url.searchParams.set('destination', `${dest[0]},${dest[1]}`)
    url.searchParams.set('return',      'summary,tolls')
    url.searchParams.set('apikey',      HERE_KEY)

    console.log('[ViaVerde] HERE Routing...')
    const res  = await fetch(url.toString(), { signal: AbortSignal.timeout(6_000) })
    const json = await res.json() as any

    if (!res.ok || !json.routes?.length) {
      console.log(`[ViaVerde] HERE Routing falhou (${res.status}):`, JSON.stringify(json).substring(0, 200))
      return null
    }

    let totalMeters    = 0
    let totalPortagens = 0

    for (const section of json.routes[0].sections ?? []) {
      totalMeters += section.summary?.length ?? 0

      for (const toll of section.tolls ?? []) {
        const fares: any[] = toll.fares ?? []

        if (totalPortagens === 0 && fares.length > 0) {
          console.log('[ViaVerde] Toll fares sample:', JSON.stringify(fares).substring(0, 500))
        }

        // Uma tarifa por praça — preferir transponder (Via Verde), fallback ao menor preço
        let fare = fares.find((f: any) =>
          f.paymentMethods?.some((m: string) =>
            /transponder|electronic|via.verde/i.test(String(m))
          )
        )
        if (!fare && fares.length > 0) {
          fare = fares.reduce((min: any, f: any) =>
            (f.price?.value ?? Infinity) < (min.price?.value ?? Infinity) ? f : min
          )
        }
        if (fare?.price?.value) totalPortagens += fare.price.value
      }
    }

    const km = Math.round((totalMeters / 1000) * 10) / 10
    console.log(`[ViaVerde] HERE: ${km} km, €${totalPortagens.toFixed(2)} portagens`)
    return { km, portagens: Math.round(totalPortagens * 100) / 100 }

  } catch (e: any) {
    console.log('[ViaVerde] HERE Routing error:', e.message)
    return null
  }
}

async function routeOsrm(
  orig: [number, number],
  dest: [number, number],
): Promise<number> {
  // OSRM usa (lng,lat) ao contrário do HERE que usa (lat,lng)
  const url = `https://router.project-osrm.org/route/v1/driving/${orig[1]},${orig[0]};${dest[1]},${dest[0]}?overview=false`
  console.log('[ViaVerde] OSRM fallback...')
  const res  = await fetch(url, { signal: AbortSignal.timeout(8_000) })
  const json = await res.json() as any
  if (!json.routes?.length) throw new Error('OSRM sem rota')
  const km = Math.round((json.routes[0].distance / 1000) * 10) / 10
  console.log(`[ViaVerde] OSRM: ${km} km`)
  return km
}

// ── API pública ────────────────────────────────────────────────────────────────

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

  const [origCoords, destCoords] = await Promise.all([
    geocode(moradaOrigem.trim()),
    geocode(moradaDestino.trim()),
  ])

  // Tentar HERE primeiro; fallback para OSRM (km apenas, portagens = 0)
  const hereResult = await routeHere(origCoords, destCoords)
  if (hereResult) return hereResult

  console.log('[ViaVerde] HERE indisponível — a usar OSRM (sem portagens)')
  const km = await routeOsrm(origCoords, destCoords)
  return { km, portagens: 0 }
}

// ── Debug: intercepta o XHR que CalculateRoute() faz ──────────────────────────
// Corre GET /api/viaverde/debug para descobrir o endpoint interno da Via Verde

function launchArgs() {
  return [
    '--no-sandbox', '--disable-setuid-sandbox', '--disable-dev-shm-usage',
    '--disable-gpu', '--single-process', '--no-zygote', '--window-size=1280,900',
  ]
}

export async function debugViaVerde(): Promise<object> {
  const browser = await puppeteer.launch({ headless: true, args: launchArgs() })
  try {
    const page = await browser.newPage()
    await page.setViewport({ width: 1280, height: 900 })
    await page.setUserAgent('Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 Chrome/124 Safari/537.36')

    // Interceptar XMLHttpRequest e fetch AO NÍVEL DO JS antes de qualquer script correr
    await page.evaluateOnNewDocument(`
      window.__capturedRequests = [];
      const _xhrOpen = XMLHttpRequest.prototype.open;
      XMLHttpRequest.prototype.open = function(method, url) {
        window.__capturedRequests.push({ via: 'XHR', method, url: String(url) });
        return _xhrOpen.apply(this, arguments);
      };
      const _xhrSend = XMLHttpRequest.prototype.send;
      XMLHttpRequest.prototype.send = function(body) {
        const last = window.__capturedRequests[window.__capturedRequests.length - 1];
        if (last && body) last.body = String(body).substring(0, 400);
        return _xhrSend.apply(this, arguments);
      };
      const _fetch = window.fetch;
      window.fetch = function(input, opts) {
        window.__capturedRequests.push({
          via: 'fetch',
          method: (opts && opts.method) || 'GET',
          url: String(typeof input === 'string' ? input : input.url),
          body: opts && opts.body ? String(opts.body).substring(0, 400) : undefined
        });
        return _fetch.apply(this, arguments);
      };
    `)

    await page.setRequestInterception(true)
    page.on('request', req => {
      const rt  = req.resourceType()
      const url = req.url()
      if (['image', 'font', 'media'].includes(rt) ||
          /evgnet|evergage|onetrust|cookielaw|geolocation\.onetrust/i.test(url)) {
        req.abort(); return
      }
      req.continue()
    })

    await page.goto(VV_URL, { waitUntil: 'domcontentloaded', timeout: 30_000 })
    await page.waitForSelector('#txtStartPos', { timeout: 15_000 })
    await new Promise(r => setTimeout(r, 2_000))

    // Snapshot antes de calcular
    const beforeCount: number = await page.evaluate(`window.__capturedRequests.length`)

    // Injectar Lisboa → Porto + Classe 2
    await page.evaluate(`
      (function() {
        var orig = document.getElementById('txtStartPos');
        orig.value = 'Lisboa'; orig.setAttribute('data-position', '[38.71667,-9.13333]');
        var dest = document.getElementById('txtEndPos');
        dest.value = 'Porto'; dest.setAttribute('data-position', '[41.14961,-8.61099]');
        var c2 = document.querySelector('a[title="Classe 2"]');
        if (c2) c2.click();
      })()
    `)
    await new Promise(r => setTimeout(r, 500))

    await page.evaluate(`typeof CalculateRoute === 'function' && CalculateRoute()`)

    // Aguardar 15 segundos para capturar tudo
    await new Promise(r => setTimeout(r, 15_000))

    const allReqs: any[] = await page.evaluate(`window.__capturedRequests`)
    const afterReqs = allReqs.slice(beforeCount)

    // Filtrar apenas chamadas relevantes (não map tiles)
    const relevant = afterReqs.filter((r: any) =>
      !/vectortiles|omv\?|yaml$|woff|png|svg|gif/i.test(r.url)
    )

    return { relevant, afterCalculate: afterReqs.length, total: allReqs.length }
  } finally {
    await browser.close()
  }
}
