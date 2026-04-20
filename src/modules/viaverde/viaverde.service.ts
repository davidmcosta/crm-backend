/**
 * Via Verde toll calculator — via HERE Maps APIs
 *
 * Fluxo (sem browser/Puppeteer):
 *  1. Geocodifica as moradas via HERE Geocoding API
 *  2. Calcula a rota + portagens via HERE Routing API v8
 *
 * Resultado em ~1-2 segundos (vs 15-20s com Puppeteer).
 */

const HERE_KEY = 'KLRL1l8y-1d-oBuCWTOQRRGCUL4tL3yThEPf9tXdW8s'

export interface ViaverdeResult {
  km: number
  portagens: number
}

// ── Geocodificação ────────────────────────────────────────────────────────────

async function geocodeHere(address: string): Promise<[number, number] | null> {
  try {
    const url = `https://geocode.search.hereapi.com/v1/geocode?q=${encodeURIComponent(address)}&in=countryCode:PRT&apikey=${HERE_KEY}`
    const res  = await fetch(url)
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
    const res  = await fetch(url, { headers: { 'User-Agent': 'ViaVerde-CRM/1.0' } })
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

// ── Routing + portagens ───────────────────────────────────────────────────────

async function routeHere(
  orig: [number, number],
  dest: [number, number],
): Promise<ViaverdeResult> {
  const url = new URL('https://router.hereapi.com/v8/routes')
  url.searchParams.set('transportMode', 'car')
  url.searchParams.set('origin',      `${orig[0]},${orig[1]}`)
  url.searchParams.set('destination', `${dest[0]},${dest[1]}`)
  url.searchParams.set('return',      'summary,tolls')
  url.searchParams.set('apikey',      HERE_KEY)

  console.log('[ViaVerde] HERE Routing...')
  const res  = await fetch(url.toString())
  const json = await res.json() as any

  if (!res.ok || !json.routes?.length) {
    const msg = json.title || json.error || JSON.stringify(json).substring(0, 200)
    throw new Error(`HERE Routing falhou (${res.status}): ${msg}`)
  }

  // Agregar todas as secções da primeira rota
  let totalMeters    = 0
  let totalPortagens = 0

  for (const section of json.routes[0].sections ?? []) {
    totalMeters += section.summary?.length ?? 0

    for (const toll of section.tolls ?? []) {
      const fares: any[] = toll.fares ?? []

      // Log raw para diagnóstico na 1ª praça
      if (totalPortagens === 0 && fares.length > 0) {
        console.log('[ViaVerde] Toll fares sample:', JSON.stringify(fares).substring(0, 500))
      }

      // Escolher apenas UMA tarifa por praça — preferir transponder (Via Verde)
      // evitando somar cash + transponder + outras categorias
      let fare = fares.find((f: any) =>
        f.paymentMethods?.some((m: string) =>
          /transponder|electronic|via.verde/i.test(String(m))
        )
      )
      // Fallback: menor preço (evita tomar a mais cara como default)
      if (!fare && fares.length > 0) {
        fare = fares.reduce((min: any, f: any) =>
          (f.price?.value ?? Infinity) < (min.price?.value ?? Infinity) ? f : min
        )
      }

      if (fare?.price?.value) {
        totalPortagens += fare.price.value
      }
    }
  }

  const km = Math.round((totalMeters / 1000) * 10) / 10

  console.log(`[ViaVerde] Rota: ${km} km, portagens: €${totalPortagens.toFixed(2)}`)
  return { km, portagens: Math.round(totalPortagens * 100) / 100 }
}

// ── API pública ───────────────────────────────────────────────────────────────

/** Calcula km e portagens entre dois endereços (sem browser). */
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

  return routeHere(origCoords, destCoords)
}

/** Endpoint de diagnóstico — devolve as coordenadas geocodificadas e a rota raw. */
export async function debugViaVerde(): Promise<object> {
  const testOrig = 'Lisboa, Portugal'
  const testDest = 'Porto, Portugal'

  const [orig, dest] = await Promise.all([
    geocodeHere(testOrig),
    geocodeHere(testDest),
  ])

  if (!orig || !dest) return { error: 'Geocoding falhou' }

  const url = new URL('https://router.hereapi.com/v8/routes')
  url.searchParams.set('transportMode', 'car')
  url.searchParams.set('origin',      `${orig[0]},${orig[1]}`)
  url.searchParams.set('destination', `${dest[0]},${dest[1]}`)
  url.searchParams.set('return',      'summary,tolls')
  url.searchParams.set('apikey',      HERE_KEY)

  const res  = await fetch(url.toString())
  const json = await res.json() as any
  return { status: res.status, orig, dest, routes: json.routes?.length, raw: json }
}
