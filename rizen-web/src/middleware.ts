import { createServerClient } from "@supabase/ssr";
import { NextResponse } from "next/server";
import type { NextRequest } from "next/server";

export async function middleware(request: NextRequest) {
  const { pathname } = request.nextUrl;
  const response = NextResponse.next({
    request: { headers: request.headers },
  });

  // Client Supabase qui lit/écrit les cookies de session
  const supabase = createServerClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!,
    {
      cookies: {
        getAll() { return request.cookies.getAll(); },
        setAll(cookiesToSet) {
          cookiesToSet.forEach(({ name, value, options }) => {
            response.cookies.set(name, value, options);
          });
        },
      },
    }
  );

  // Récupère la session (rafraîchit le token si besoin)
  const { data: { user } } = await supabase.auth.getUser();

  // ── Protection routes /admin/* ─────────────────────────────────────
  if (pathname.startsWith("/admin")) {
    // La page de login admin est toujours accessible
    if (pathname === "/admin/login") {
      // Si déjà connecté en superadmin → dashboard directement
      if (user) {
        const { data: profil } = await supabase
          .from("profils")
          .select("role")
          .eq("id", user.id)
          .maybeSingle();
        if (profil?.role === "superadmin") {
          return NextResponse.redirect(new URL("/admin/dashboard", request.url));
        }
      }
      return response;
    }

    // Toutes les autres routes /admin/* nécessitent superadmin
    if (!user) {
      return NextResponse.redirect(new URL("/admin/login", request.url));
    }

    const { data: profil } = await supabase
      .from("profils")
      .select("role")
      .eq("id", user.id)
      .maybeSingle();

    if (profil?.role !== "superadmin") {
      await supabase.auth.signOut();
      return NextResponse.redirect(new URL("/admin/login", request.url));
    }

    return response;
  }

  // ── Redirection si déjà connecté sur /auth/* ──────────────────────
  // /auth/callback est exclu : Google y renvoie le code PKCE avant qu'une session existe
  if (pathname.startsWith("/auth/") && pathname !== "/auth/callback") {
    if (user) {
      return NextResponse.redirect(new URL("/feed", request.url));
    }
    return response;
  }

  // ── Protection routes post-connexion ──────────────────────────────
  const protectedRoutes = [
    "/feed",
    "/messages",
    "/profil",
    "/favoris",
    "/notifications",
    "/parametres",
    "/annonces/creer",
    "/annonces/modifier",
    "/negociations",
    "/paiement",
  ];
  const isProtected = protectedRoutes.some((r) => pathname === r || pathname.startsWith(r + "/"));
  if (isProtected && !user) {
    const gateUrl = new URL("/auth/gate", request.url);
    gateUrl.searchParams.set("redirect", pathname);
    return NextResponse.redirect(gateUrl);
  }

  return response;
}

export const config = {
  matcher: [
    "/admin/:path*",
    "/auth/:path*",
    "/feed",
    "/messages",
    "/messages/:path*",
    "/profil/:path*",
    "/favoris",
    "/notifications",
    "/parametres",
    "/annonces/creer",
    "/annonces/:id/modifier",
    "/negociations/:path*",
    "/paiement/:path*",
  ],
};
