const TMDB_ORIGIN = 'https://api.themoviedb.org/3';

const ALLOWED_PATHS = [
  /^\/trending\/(movie|tv)\/day$/,
  /^\/movie\/popular$/,
  /^\/movie\/\d+$/,
  /^\/search\/movie$/,
  /^\/tv\/popular$/,
  /^\/tv\/top_rated$/,
  /^\/search\/tv$/,
  /^\/tv\/\d+$/,
  /^\/tv\/\d+\/season\/\d+$/,
];

function corsHeaders(request, env) {
  const origin = request.headers.get('Origin') || '';
  const configured = (env.ALLOWED_ORIGINS || '')
    .split(',')
    .map((value) => value.trim())
    .filter(Boolean);

  const allowOrigin = configured.includes(origin)
    ? origin
    : configured[0] || 'https://rayat23.github.io';

  return {
    'Access-Control-Allow-Origin': allowOrigin,
    'Access-Control-Allow-Methods': 'GET,OPTIONS',
    'Access-Control-Allow-Headers': 'Content-Type',
    'Vary': 'Origin',
  };
}

function jsonResponse(body, status, request, env) {
  return new Response(JSON.stringify(body), {
    status,
    headers: {
      'Content-Type': 'application/json; charset=utf-8',
      ...corsHeaders(request, env),
    },
  });
}

export default {
  async fetch(request, env) {
    if (request.method === 'OPTIONS') {
      return new Response(null, {
        status: 204,
        headers: corsHeaders(request, env),
      });
    }

    if (request.method !== 'GET') {
      return jsonResponse({ error: 'Method not allowed' }, 405, request, env);
    }

    if (!env.TMDB_API_KEY && !env.TMDB_BEARER_TOKEN) {
      return jsonResponse(
        { error: 'TMDB credential is not configured on the proxy.' },
        503,
        request,
        env,
      );
    }

    const incoming = new URL(request.url);
    const path = incoming.pathname.replace(/\/$/, '') || '/';

    if (!ALLOWED_PATHS.some((pattern) => pattern.test(path))) {
      return jsonResponse({ error: 'TMDB route is not allowed.' }, 404, request, env);
    }

    const target = new URL(`${TMDB_ORIGIN}${path}`);

    for (const [key, value] of incoming.searchParams.entries()) {
      if (key !== 'api_key') {
        target.searchParams.set(key, value);
      }
    }

    if (!target.searchParams.has('language')) {
      target.searchParams.set('language', 'en-US');
    }

    if (env.TMDB_API_KEY) {
      target.searchParams.set('api_key', env.TMDB_API_KEY);
    }

    const headers = {
      'Accept': 'application/json',
    };

    if (!env.TMDB_API_KEY && env.TMDB_BEARER_TOKEN) {
      headers.Authorization = `Bearer ${env.TMDB_BEARER_TOKEN}`;
    }

    try {
      const response = await fetch(target.toString(), {
        headers,
        cf: {
          cacheEverything: request.method === 'GET',
          cacheTtl: path.startsWith('/search/') ? 300 : 900,
        },
      });

      const body = await response.text();
      return new Response(body, {
        status: response.status,
        headers: {
          'Content-Type': response.headers.get('Content-Type') || 'application/json',
          'Cache-Control': response.ok ? 'public, max-age=120' : 'no-store',
          ...corsHeaders(request, env),
        },
      });
    } catch (error) {
      return jsonResponse(
        { error: 'TMDB proxy request failed.', detail: String(error) },
        502,
        request,
        env,
      );
    }
  },
};
